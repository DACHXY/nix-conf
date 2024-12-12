{ config, pkgs, lib, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.swraid.enable = true;
  boot.swraid.mdadmConf =
    "\n  MAILADDR smitty\n  ARRAY /dev/md126 metadata=1.2 name=stuff:0\n  UUID=3b0b7c51:2681:407e:a22a:e965a8aeece7\n  ";
}
