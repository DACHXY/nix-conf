{
  pkgs,
  username,
  ...
}:
let
  scriptBin = pkgs.writeShellScriptBin "davinci-resolve" ''
    ROC_ENABLE_PRE_VEGA=1 RUSTICL_ENABLE=amdgpu,amdgpu-pro,radv,radeon DRI_PRIME=1 QT_QPA_PLATFORM=xcb ${pkgs.davinci-resolve}/bin/davinci-resolve
  '';
in
{
  environment.systemPackages = [
    scriptBin
  ];

  home-manager.users."${username}" = {
    xdg.desktopEntries."davindi-resolve" = {
      name = "Davinci Resolve";
      genericName = "Video Editor";
      exec = "${scriptBin}/bin/davinci-resolve";
      icon = "${pkgs.davinci-resolve}/share/icons/hicolor/128x128/apps/davinci-resolve.png";
      comment = "Professional video editing, color, effects and audio post-processing";
      categories = [
        "AudioVideo"
        "AudioVideoEditing"
        "Video"
        "Graphics"
      ];
    };
  };
}
