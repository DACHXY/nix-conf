# Recovery channel for a headless cloud box: `danny` has no password (the
# shared user module sets none; only `goWin` is NOPASSWD sudo) and the GCE
# serial console has no root password either — so without this the machine
# would have no way in after a bad boot. Key-only root login, nothing else.
{
  configurations.nixos.dn-gcp.module =
    { lib, ... }:
    {
      users.users.root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPUdPF97njslzBHYk5zTrmnx6Tj7u7BCJ5M0+OeyTTt/ danny@dn-cscc nixos-anywhere"
      ];
      services.openssh.settings.PermitRootLogin = lib.mkForce "prohibit-password";
      # ssh-server.nix 的 `AllowUsers = [ username ]` 會連帶擋掉 root，只設
      # PermitRootLogin 沒有用（sshd 會記錄 "not allowed because not listed in
      # AllowUsers"）。救援通道要兩個一起開。
      services.openssh.settings.AllowUsers = lib.mkForce [ "danny" "root" ];
    };
}
