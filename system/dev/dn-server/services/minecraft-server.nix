{ pkgs, ... }:
let
  modpack = pkgs.fetchPackwizModpack {
    url = "https://git.dnywe.com/dachxy/shader-retired-modpack/raw/branch/main/pack.toml";
    packHash = "sha256-NPMS8j5NXbtbsso8R4s4lhx5L7rQJdek62G2Im3JdmM=";
  };
in
{
  systemConf.security.allowedDomains = [
    "api.mojang.com"
    "textures.minecraft.net"
    "session.minecraft.net"
    "login.microsoftonline.com"
  ];

  services.minecraft-servers = {
    enable = true;
    eula = true;
  };

  services.minecraft-servers.servers.shader-retired = {
    enable = true;
    autoStart = true;
    openFirewall = true;
    package = pkgs.fabric-server;
    symlinks = {
      "mods" = "${modpack}/mods";
    };
    serverProperties = {

      server-port = 25565;
      difficulty = 3;
      gamemode = "survival";
      max-player = 20;
      modt = "Bro!!!!";
      accepts-flight = true;
      accepts-transfers = true;
      hardcore = false;
    };
  };
}
