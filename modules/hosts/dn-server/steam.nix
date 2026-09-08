{ lib, ... }:
{
  configurations.nixos.dn-server.module =
    { pkgs, config, ... }:
    let
      greeter-control = pkgs.writeTextFile {
        name = "greeter-control";
        executable = true;
        destination = "/bin/greeter-control";

        text = /* python */ ''
          #!${lib.getExe pkgs.python312}

          """
          greetd control server

          Endpoints:
              POST /greetd/start
              POST /greetd/stop
          """

          from __future__ import annotations

          import ipaddress
          import logging
          import signal
          import subprocess
          import sys
          import threading
          from dataclasses import dataclass
          from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
          from typing import Optional


          # ---------------------------------------------------------------------------
          # Settings
          # ---------------------------------------------------------------------------

          HOSTS = [
              "192.168.100.9",
              "100.104.189.30",
          ]

          PORT = 30025

          ALLOWED_NETWORKS = [
              ipaddress.ip_network("192.168.100.0/24"),
              ipaddress.ip_network("100.104.0.0/16"),
          ]

          SYSTEMCTL = "/run/current-system/sw/bin/systemctl"
          SERVICE_NAME = "greetd.service"
          SYSTEMCTL_TIMEOUT = 30

          ACTIONS = {
              "/greetd/start": "start",
              "/greetd/stop": "stop",
          }

          logging.basicConfig(
              level=logging.INFO,
              format="%(asctime)s [%(levelname)s] %(message)s",
              datefmt="%Y-%m-%d %H:%M:%S",
          )
          log = logging.getLogger("greetd-control")


          # ---------------------------------------------------------------------------
          # ACL
          # ---------------------------------------------------------------------------

          def is_client_allowed(ip_str: str) -> bool:
              try:
                  client_ip = ipaddress.ip_address(ip_str)
              except ValueError:
                  return False

              return any(client_ip in network for network in ALLOWED_NETWORKS)


          # ---------------------------------------------------------------------------
          # systemctl result
          # ---------------------------------------------------------------------------

          @dataclass
          class SystemctlResult:
              ok: bool
              message: str


          def run_systemctl(action: str) -> SystemctlResult:
              try:
                  result = subprocess.run(
                      [SYSTEMCTL, action, SERVICE_NAME],
                      capture_output=True,
                      text=True,
                      timeout=SYSTEMCTL_TIMEOUT,
                      check=False,
                  )
              except subprocess.TimeoutExpired:
                  return SystemctlResult(False, "systemctl timeout")
              except OSError as e:
                  return SystemctlResult(False, f"Failed to execute systemctl: {e}")

              if result.returncode != 0:
                  error = result.stderr.strip() or (
                      f"systemctl exited with code {result.returncode}"
                  )
                  return SystemctlResult(False, error)

              return SystemctlResult(True, f"{SERVICE_NAME} {action}ed")


          # ---------------------------------------------------------------------------
          # HTTP handler
          # ---------------------------------------------------------------------------

          class GreetdControlHandler(BaseHTTPRequestHandler):
              server_version = "GreetdControl/1.0"

              def do_POST(self) -> None:
                  client_ip = self.client_address[0]

                  if not is_client_allowed(client_ip):
                      self.send_error(403, "Forbidden")
                      return

                  action = ACTIONS.get(self.path)
                  if action is None:
                      self.send_error(404, "Not Found")
                      return

                  result = run_systemctl(action)

                  if not result.ok:
                      self.send_error(500, result.message)
                      return

                  body = f"{result.message}\n".encode("utf-8")

                  self.send_response(200)
                  self.send_header("Content-Type", "text/plain; charset=utf-8")
                  self.send_header("Content-Length", str(len(body)))
                  self.end_headers()
                  self.wfile.write(body)

              def log_message(self, format: str, *args) -> None:
                  log.info("[%s] %s", self.client_address[0], format % args)


          # ---------------------------------------------------------------------------
          # Server
          # ---------------------------------------------------------------------------

          class ManagedServer:
              def __init__(self, host: str, port: int):
                  self.host = host
                  self.port = port
                  self.httpd = ThreadingHTTPServer((host, port), GreetdControlHandler)
                  self._thread: Optional[threading.Thread] = None

              def start(self) -> None:
                  self._thread = threading.Thread(
                      target=self.httpd.serve_forever,
                      name=f"http-{self.host}:{self.port}",
                      daemon=True,
                  )
                  self._thread.start()
                  log.info("Listening on http://%s:%s", self.host, self.port)

              def stop(self) -> None:
                  self.httpd.shutdown()
                  self.httpd.server_close()
                  if self._thread is not None:
                      self._thread.join(timeout=5)


          def start_servers(hosts: list[str], port: int) -> list[ManagedServer]:
              servers: list[ManagedServer] = []

              for host in hosts:
                  try:
                      server = ManagedServer(host, port)
                      server.start()
                      servers.append(server)
                  except OSError as e:
                      log.error("Failed to listen on %s:%s: %s", host, port, e)

              return servers


          def main() -> None:
              servers = start_servers(HOSTS, PORT)

              if not servers:
                  raise RuntimeError("Failed to start any HTTP server")

              log.info("greetd control server started")

              shutdown_event = threading.Event()

              def handle_signal(signum, _frame):
                  log.info("Received signal %s, shutting down...", signum)
                  shutdown_event.set()

              signal.signal(signal.SIGINT, handle_signal)
              signal.signal(signal.SIGTERM, handle_signal)

              shutdown_event.wait()

              for server in servers:
                  server.stop()

              log.info("Shutdown complete")


          if __name__ == "__main__":
              try:
                  main()
              except RuntimeError as e:
                  log.error(str(e))
                  sys.exit(1)
        '';
      };
    in
    {
      environment.systemPackages = with pkgs; [
        steamcmd
        steam-tui
      ];

      networking.firewall.allowedTCPPorts = [
        30025
      ];

      systemd.services.greeter-control = {
        description = "Greeter control server";
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          ExecStart = "${greeter-control}/bin/greeter-control";
          Restart = "always";
          RestartSec = "1s";
          User = "root";
        };
      };

      programs = {
        gamescope = {
          enable = true;
          capSysNice = true;
          enableWsi = true;
        };
      };

      programs.gamemode = {
        enable = true;
      };

      programs.steam = {
        enable = true;
        gamescopeSession.enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        extraCompatPackages = with pkgs; [
          dwproton-bin
          proton-ge-bin
        ];
        extraPackages = with pkgs; [
          mangohud
          gamescope
        ];
      };

      hardware = {
        steam-hardware.enable = true;
        xpadneo.enable = true;
      };

      services = {
        xserver.enable = false; # Assuming no other Xserver needed
        # getty.autologinUser = config.my.user.name;
        greetd = {
          enable = true;
          settings = {
            default_session = {
              command = "${lib.getExe pkgs.gamescope} --backend drm --prefer-vk-device 10de:2438 -O HDMI-A-1 -W 2560 -H 1440 -f -e --xwayland-count 2 --hdr-enabled --hdr-itm-enabled -- steam -pipewire-dmabuf -gamepadui -steamdeck -steamos3";
              user = config.my.user.name;
            };
          };
        };
      };

      networking.hosts = {
        "2.19.181.11" = [ "client-download.steampowered.com" ];
        "2.19.181.10" = [ "client-download.steampowered.com" ];
      };
    };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-unwrapped"
    ];
}
