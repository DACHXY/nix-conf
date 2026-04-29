{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    rustdesk
    ((blender.override { cudaSupport = true; }).overrideAttrs (prev: {
      postInstall = ''
        sed -i 's|Exec=blender %f|Exec=/run/current-system/sw/bin/nvidia-offload blender %f|' $out/share/applications/blender.desktop
      '';
    }))
  ];
}
