{
  flake.modules.nixos.virtual-display =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      create-edid = pkgs.writeText "create-edid.py" ''
        import struct, sys

        def make_dtd(pc_khz, h_active, h_blank, h_front, h_sync,
                     v_active, v_blank, v_front, v_sync, h_mm=600, v_mm=340):
            dtd = bytearray(18)
            struct.pack_into('<H', dtd, 0, pc_khz // 10)
            dtd[2] = h_active & 0xFF
            dtd[3] = h_blank & 0xFF
            dtd[4] = ((h_active >> 8) & 0x0F) << 4 | ((h_blank >> 8) & 0x0F)
            dtd[5] = v_active & 0xFF
            dtd[6] = v_blank & 0xFF
            dtd[7] = ((v_active >> 8) & 0x0F) << 4 | ((v_blank >> 8) & 0x0F)
            dtd[8] = h_front & 0xFF
            dtd[9] = h_sync & 0xFF
            dtd[10] = ((v_front & 0x0F) << 4) | (v_sync & 0x0F)
            dtd[11] = (((h_front >> 8) & 0x03) << 6 | ((h_sync >> 8) & 0x03) << 4 |
                       ((v_front >> 4) & 0x03) << 2 | ((v_sync >> 4) & 0x03))
            dtd[12] = h_mm & 0xFF
            dtd[13] = v_mm & 0xFF
            dtd[14] = ((h_mm >> 8) & 0x0F) << 4 | ((v_mm >> 8) & 0x0F)
            dtd[17] = 0x18 | 0x02 | 0x04  # digital separate sync, +hsync, +vsync
            return bytes(dtd)

        def make_desc(tag, data):
            desc = bytearray(18)
            desc[3] = tag
            for i, b in enumerate(data[:13]):
                desc[5 + i] = b
            return bytes(desc)

        def fix_checksum(block):
            block = bytearray(block)
            block[127] = (256 - (sum(block[:127]) % 256)) % 256
            return bytes(block)

        def cvt_rb_timing(h_active, v_active, refresh):
            """CVT-RB v2 timing per VESA CVT 2.0 spec (used by macOS for
            eDP/internal and many external panels). Horizontal blanking is
            fixed at 80 and sync/front are constants; vertical blank is
            calculated from a 540 us vblank time (v2 uses 540 us instead of
            v1's 460 us)."""
            RB_H_BLANK, RB_H_SYNC, RB_H_FRONT = 80, 8, 8
            RB_V_SYNC = 8 if v_active < 1200 else (7 if v_active < 2000 else 10)
            RB_V_FRONT = 3
            h_total = h_active + RB_H_BLANK
            v_blank = max(RB_V_FRONT + RB_V_SYNC + 1,
                          int(540 * refresh * (v_active + RB_V_FRONT + RB_V_SYNC + 1) / 1_000_000) + 1)
            pixel_clock = h_total * (v_active + v_blank) * refresh
            pixel_clock_khz = ((pixel_clock + 5000) // 10000) * 10
            return (pixel_clock_khz, RB_H_BLANK, RB_H_FRONT, RB_H_SYNC, v_blank, RB_V_FRONT, RB_V_SYNC)

        def mfr_id(s):
            v = sum((ord(c) - 64) << (5 * (2 - i)) for i, c in enumerate(s[:3]))
            return bytes([(v >> 8) & 0xFF, v & 0xFF])

        VICS = [16, 63, 97]  # 1080p60, 1080p120, 4K60

        def build_base():
            base = bytearray(128)
            base[0:8] = b'\x00\xFF\xFF\xFF\xFF\xFF\xFF\x00'
            base[8:10] = mfr_id('SUN')
            base[10:12] = b'\x01\x00'
            base[12:16] = b'\x00\x00\x00\x00'
            base[16] = 1
            base[17] = 36
            base[18] = 1
            base[19] = 4
            base[20] = 0xA5  # digital, 8-bit, DisplayPort
            base[21] = 60
            base[22] = 34
            base[23] = 120
            base[24] = 0x0B
            base[25:35] = bytes([0xEE, 0x95, 0xA3, 0x54, 0x4C, 0x99, 0x26, 0x0F, 0x50, 0x54])
            base[35:38] = bytes([0x21, 0x08, 0x00])
            # Supported resolutions (16:9, 16:10 MacBook, and 4K)
            for i in range(8):
                base[38 + i * 2] = 0x01
                base[39 + i * 2] = 0x01
            # Descriptor slot 1 must hold the preferred timing, so start at
            # offset 54 (slots 3 and 4 hold the range-limit + name).
            pos = 54
            pc, hb, hf, hs, vb, vf, vs = cvt_rb_timing(2560, 1440, 60)
            base[pos:pos+18] = make_dtd(pc, 2560, hb, hf, hs, 1440, vb, vf, vs)
            pos += 18
            pc, hb, hf, hs, vb, vf, vs = cvt_rb_timing(2560, 1600, 60)
            base[pos:pos+18] = make_dtd(pc, 2560, hb, hf, hs, 1600, vb, vf, vs)
            pos += 18
            rl = bytearray(18)
            rl[0:4] = b'\x00\x00\x00\xFD'
            rl[5] = 24
            rl[6] = 120
            rl[7] = 15
            rl[8] = 200
            rl[9] = 70
            rl[10] = 0x00
            rl[11:18] = b'\x0A\x20\x20\x20\x20\x20\x20'
            base[pos:pos+18] = rl
            pos += 18
            base[pos:pos+18] = make_desc(0xFC, b'VirtDisplay\n ')
            pos += 18
            base[126] = 2
            assert pos == 126, f'base block ends at {pos}, expected 126'
            return fix_checksum(base)

        def build_cta():
            ext = bytearray(128)
            ext[0] = 0x02
            ext[1] = 0x03
            data = bytearray()
            data.append(0x40 | len(VICS))
            data.extend(VICS)
            # HDMI VSDB (OUI 00-0C-03)
            data.extend([0x66, 0x03, 0x0C, 0x00, 0x10, 0x00, 0x78])
            # HDMI Forum VSDB (OUI C4-5D-D8): 600 MHz max TMDS + SCDC
            data.extend([0x67, 0xD8, 0x5D, 0xC4, 0x01, 0x78, 0x80, 0x00])
            dtd_offset = 4 + len(data)
            ext[2] = dtd_offset
            ext[3] = 0x30
            ext[4:4 + len(data)] = data
            pos = dtd_offset
            for h, v, rf in ((2560,1440,120),(2560,1600,120),(3072,1920,60),(3456,2234,60),(3840,2160,60)):
                pc, hb, hf, hs, vb, vf, vs = cvt_rb_timing(h, v, rf)
                ext[pos:pos+18] = make_dtd(pc, h, hb, hf, hs, v, vb, vf, vs)
                pos += 18
            assert pos <= 126, f'CTA block ends at {pos}'
            return fix_checksum(ext)

        def build_cta30():
            # Second CTA block: 30 Hz variants so a 30 fps stream can run with
            # the display actually refreshing at 30 Hz.  No data blocks -- the
            # DTDs start right after the 4-byte header (6 fit before byte 127).
            ext = bytearray(128)
            ext[0] = 0x02
            ext[1] = 0x03
            ext[2] = 4
            ext[3] = 0x00
            pos = 4
            for h, v, rf in ((1920,1080,30),(2560,1440,30),(2560,1600,30),(3072,1920,30),(3456,2234,30),(3840,2160,30)):
                pc, hb, hf, hs, vb, vf, vs = cvt_rb_timing(h, v, rf)
                ext[pos:pos+18] = make_dtd(pc, h, hb, hf, hs, v, vb, vf, vs)
                pos += 18
            assert pos <= 126, f'CTA 30 Hz block ends at {pos}'
            return fix_checksum(ext)

        edid = bytes(build_base() + build_cta() + build_cta30())
        assert len(edid) == 384
        open(sys.argv[1], 'wb').write(edid)
      '';
      edid =
        pkgs.runCommand "sunshine-virt-edid.bin"
          {
            nativeBuildInputs = [ pkgs.python3 ];
          }
          ''
            python3 ${create-edid} "$out"
          '';
      edid-pkg = pkgs.runCommand "sunshine-virt-edid" { } ''
        mkdir -p "$out/lib/firmware/edid"
        cp ${edid} "$out/lib/firmware/edid/sunshine-virt.bin"
      '';
      connector = "DP-2"; # spare connector on dn-cscc (no physical sink attached)
    in
    {
      hardware.display.edid.packages = [ edid-pkg ];
      hardware.display.outputs.${connector} = {
        edid = "sunshine-virt.bin";
        mode = "e";
      };

      services.sunshine.settings.output_name = connector;
    };
}
