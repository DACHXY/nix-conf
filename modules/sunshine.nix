{
  flake.modules.nixos.gui =
    { config, pkgs, lib, ... }:
    let
      # NVENC (hardware encoding) lives behind Sunshine's CUDA build, which
      # nixpkgs disables unless cudaSupport is on.  Without it Sunshine silently
      # falls back to CPU libx264.
      nvenc = lib.elem "nvidia" config.services.xserver.videoDrivers;
    in
    {
      services.sunshine = {
        enable = true;
        autoStart = true;
        capSysAdmin = true;
        openFirewall = true;
        settings = {
          sunshine_name = config.networking.hostName;
        }
        // lib.optionalAttrs nvenc {
          encoder = "nvenc";
        };
      };

      services.sunshine.package = lib.mkIf nvenc (
        pkgs.sunshine.override {
          cudaSupport = true;
          cudaPackages = pkgs.cudaPackages;
        }
      );

      # Grant CAP_SYS_NICE so Sunshine can raise the priority of its
      # capture/encode EGL context (otherwise it warns and stays at normal prio).
      security.wrappers.sunshine.capabilities =
        lib.mkIf nvenc (lib.mkForce "cap_sys_admin,cap_sys_nice+p");
    };
}
