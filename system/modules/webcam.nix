# Use WebRTC to stream
{ pkgs, config, ... }:
{
  environment.systemPackages = with pkgs; [
    ffmpeg
    v4l-utils
  ];

  boot = {
    kernelModules = [ "v4l2loopback" ];
    extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  };

  boot.extraModprobeConfig = ''
    options v4l2loopback devices=2 video_nr=1,2 card_label="OBS Cam","phone webRTC cam" exclusive_caps=1,1
  '';
}
