"""picokey-led: show or set the PicoKey's LED brightness (Pico Keys PHY config).

Talks to the firmware's rescue applet over PC/SC. Writing the PHY block
replaces it wholesale, so every other field (VID/PID, LED pin and driver,
press-to-confirm timeout, ...) is read first and written back unchanged.

  picokey-led                  show the PHY config
  picokey-led brightness N     set brightness, 0 (off) .. 15 (max)

Writing needs a press on the key's button when press-to-confirm is enabled.
pcscd only admits the local desktop session; over ssh, run it with sudo.
"""

import sys

from smartcard.pcsc.PCSCExceptions import EstablishContextException
from smartcard.System import readers

RESCUE_AID = [0xA0, 0x58, 0x3F, 0xC1, 0x9B, 0x7E, 0x4F, 0x21]
TAG_BRIGHTNESS = 0x05
MAX_BRIGHTNESS = 15  # firmware: LED_BTNESS_BITS = 4
NAMES = {
    0x00: "vid:pid",
    0x04: "led gpio",
    0x05: "led brightness",
    0x06: "options",
    0x08: "press timeout (s)",
    0x09: "usb product",
    0x0A: "enabled curves",
    0x0B: "enabled usb itf",
    0x0C: "led driver",
}
DRIVERS = {1: "pico", 2: "pimoroni", 3: "ws2812", 4: "cyw43", 5: "neopixel", 0xFF: "none"}


def connect():
    try:
        found = [r for r in readers() if "Pico" in str(r)]
    except EstablishContextException:
        sys.exit("pcscd refused the connection; outside the desktop session run this with sudo")
    if not found:
        sys.exit("no PicoKey reader found (is the key plugged in?)")
    conn = found[0].createConnection()
    conn.connect()
    return conn


def transmit(conn, apdu):
    data, sw1, sw2 = conn.transmit(apdu)
    while sw1 == 0x61:
        more, sw1, sw2 = conn.transmit([0x00, 0xC0, 0x00, 0x00, sw2])
        data += more
    return bytes(data), (sw1 << 8) | sw2


def check(sw, what):
    if sw != 0x9000:
        hint = " (button not pressed in time?)" if sw == 0x6985 else ""
        sys.exit(f"{what} failed: SW {sw:04x}{hint}")


def parse(raw):
    fields, i = [], 0
    while i + 2 <= len(raw):
        tag, length = raw[i], raw[i + 1]
        fields.append((tag, raw[i + 2:i + 2 + length]))
        i += 2 + length
    return fields


def serialize(fields):
    return b"".join(bytes([tag, len(value)]) + value for tag, value in fields)


def describe(tag, value):
    if tag == 0x00 and len(value) == 4:
        return f"{value[:2].hex()}:{value[2:].hex()}"
    if tag == 0x09:
        return value.decode(errors="replace")
    if tag == 0x0C and value:
        return DRIVERS.get(value[0], f"0x{value[0]:02x}") + (f" order {value[1]}" if len(value) > 1 else "")
    if tag == TAG_BRIGHTNESS and value:
        return f"{value[0]}/{MAX_BRIGHTNESS}"
    if len(value) == 1:
        return str(value[0])
    return value.hex()


def main():
    args = sys.argv[1:]
    if args and (args[0] != "brightness" or len(args) != 2):
        sys.exit(__doc__)

    conn = connect()
    _, sw = transmit(conn, [0x00, 0xA4, 0x04, 0x04, len(RESCUE_AID)] + RESCUE_AID)
    check(sw, "selecting the rescue applet")
    raw, sw = transmit(conn, [0x80, 0x1E, 0x01, 0x00, 0x00])
    check(sw, "reading the PHY config")
    fields = parse(raw)

    if not args:
        for tag, value in fields:
            print(f"{NAMES.get(tag, f'tag 0x{tag:02x}'):18} {describe(tag, value)}")
        if all(tag != TAG_BRIGHTNESS for tag, _ in fields):
            print(f"{NAMES[TAG_BRIGHTNESS]:18} {MAX_BRIGHTNESS}/{MAX_BRIGHTNESS} (default)")
        return

    try:
        level = int(args[1])
    except ValueError:
        level = -1
    if not 0 <= level <= MAX_BRIGHTNESS:
        sys.exit(f"brightness must be 0..{MAX_BRIGHTNESS}")

    fields = [(t, v) for t, v in fields if t != TAG_BRIGHTNESS] + [(TAG_BRIGHTNESS, bytes([level]))]
    print("press the key's button to confirm...", flush=True)
    _, sw = transmit(conn, [0x80, 0x1C, 0x01, 0x00, len(serialize(fields))] + list(serialize(fields)))
    check(sw, "writing the PHY config")
    print(f"led brightness set to {level}/{MAX_BRIGHTNESS}")


main()
