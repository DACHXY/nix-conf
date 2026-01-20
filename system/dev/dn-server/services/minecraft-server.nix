{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (config.sops) secrets;
  inherit (inputs.nix-minecraft.lib) collectFilesAt;

  modpack-shaderRetired = pkgs.fetchPackwizModpack {
    url = "https://git.dnywe.com/dachxy/shader-retired-modpack/raw/branch/main/pack.toml";
    packHash = "sha256-NPMS8j5NXbtbsso8R4s4lhx5L7rQJdek62G2Im3JdmM=";
  };

  modpack-landscape = pkgs.fetchPackwizModpack {
    url = "https://git.dnywe.com/dachxy/landscape-modpack/raw/branch/main/pack.toml";
    packHash = "sha256-mQSE4PMrOupARpEIzdzg+gOD0VQGII4MrBUyr8VevKk=";
  };

  fabricProxy = pkgs.fetchurl rec {
    pname = "FabricProxy-Lite";
    version = "2.11.0";
    url = "https://cdn.modrinth.com/data/8dI2tmqs/versions/nR8AIdvx/${pname}-${version}.jar";
    hash = "sha256-68er6vbAOsYZxwHrszLeaWbG2D7fq/AkNHIMj8PQPNw=";
  };

  velocityCfg = config.services.velocity;
in
{
  systemConf.security.allowedDomains = [
    "api.mojang.com"
    "textures.minecraft.net"
    "session.minecraft.net"
    "login.microsoftonline.com"
  ];

  sops.secrets."velocity" = {
    owner = velocityCfg.user;
  };

  sops.secrets."fabricProxy" = {
    owner = "minecraft";
  };

  services.velocity = {
    enable = true;
    openFirewall = true;
    host = "0.0.0.0";
    port = 25565;
    settings = {
      motd = "<#09add3>POG, MC server!";
      player-info-forwarding-mode = "modern";
      forwarding-secret-file = "${secrets."velocity".path}";

      servers = {
        shader-retired = "127.0.0.1:30066";
        landscape = "127.0.0.1:30067";

        try = [
          "shader-retired"
        ];
      };

      forced-hosts = {
        "server.vnet.dn" = [
          "shader-retired"
        ];
        "retired.mc.dnywe.com" = [
          "shader-retired"
        ];
        "landscape.mc.dnywe.com" = [
          "landscape"
        ];
      };
    };
  };

  services.minecraft-servers = {
    enable = true;
    eula = true;
  };

  services.minecraft-servers.servers = {
    shader-retired =
      let
        mcVersion = modpack-shaderRetired.manifest.versions.minecraft;
        fabricVersion = modpack-shaderRetired.manifest.versions.fabric;
        serverVersion = lib.replaceStrings [ "." ] [ "_" ] "fabric-${mcVersion}";
      in
      {
        enable = true;
        autoStart = true;
        jvmOpts = "-Xms2144M -Xmx8240M";
        package = pkgs.fabricServers.${serverVersion}.override { loaderVersion = fabricVersion; };
        symlinks = collectFilesAt modpack-shaderRetired "mods" // {
          "mods/FabricProxy-Lite.jar" = fabricProxy;
        };
        files = {
          "config/FabricProxy-Lite.toml" = "${secrets."fabricProxy".path}";
        };
        serverProperties = {
          server-port = 30066;
          difficulty = 3;
          gamemode = "survival";
          max-player = 20;
          motd = "Bro!!!!";
          accepts-flight = true;
          accepts-transfers = true;
          hardcore = false;
        };
      };

    landscape =
      let
        mcVersion = modpack-landscape.manifest.versions.minecraft;
        fabricVersion = modpack-landscape.manifest.versions.fabric;
        serverVersion = lib.replaceStrings [ "." ] [ "_" ] "fabric-${mcVersion}";
      in
      {
        enable = true;
        autoStart = true;
        enableReload = true;
        jvmOpts = "-Xms2144M -Xmx8240M";
        package = pkgs.fabricServers.${serverVersion}.override { loaderVersion = fabricVersion; };
        symlinks = collectFilesAt modpack-landscape "mods" // {
          "mods/FabricProxy-Lite.jar" = fabricProxy;
        };
        files = {
          "config/FabricProxy-Lite.toml" = "${secrets."fabricProxy".path}";
        };
        serverProperties = {
          server-port = 30067;
          difficulty = 3;
          gamemode = "survival";
          max-player = 20;
          motd = "Landscape, daug!";
          accepts-flight = true;
          accepts-transfers = true;
          hardcore = false;
        };
      };
  };
}
