{
  pkgs,
  url,
  ...
}:
pkgs.writers.writePython3Bin "memeSelector" {libraries = with pkgs.python3Packages; [requests];}
''
  import requests
  import xml.etree.ElementTree as ET
  import urllib.parse
  import sys
  import os
  import tempfile
  import subprocess

  BASE_URL = "${url}"
  headers = {"Depth": "1"}
  resp = requests.request(
    "PROPFIND",
    BASE_URL,
    headers=headers,
    verify="${"" + ../../system/extra/ca.crt}"
  )

  if resp.status_code not in (200, 207):
      print(f"Error: Http {resp.status_code}")
      sys.exit(1)

  root = ET.fromstring(resp.text)
  ns = {"d": "DAV:"}

  files = []
  for href in root.findall(".//d:href", ns):
      path = href.text
      if not path:
          continue
      filename = urllib.parse.unquote(path.split("/")[-1])

      if filename and not filename.endswith("/"):
          files.append(filename)

  if not files:
      print("No files found")
      sys.exit(0)

  rofi = subprocess.run(
    ["rofi", "-i", "-dmenu", "-p", "Meme"],
    input="\n".join(files).encode(),
    stdout=subprocess.PIPE
  )

  selected = rofi.stdout.decode().strip()
  if not selected:
      sys.exit(0)

  url = BASE_URL + urllib.parse.quote(selected)
  tmpfile = os.path.join(tempfile.gettempdir(), selected)

  subprocess.run(["wget", "-q", "-O", tmpfile, url], check=True)

  with open(tmpfile, "rb") as f:
      subprocess.run("wl-copy", stdin=f)

  subprocess.run([
    "notify-send",
    "-i", tmpfile,
    "Meme Copied: ",
    f"{selected}"
  ])
''
