{ ... }:
{
  systemd.services.hideTTY = {
    description = "Auto turn off monitor ";
    wantedBy = [ "multi-user.target" ];
    script = ''
      echo 1 > /sys/class/graphics/fb0/blank
    '';
    serviceConfig = {
      Type = "oneshot";
    };
  };
}
