{
  # A second ssh-agent that holds only the FIDO key (~/.ssh/id_ecdsa_sk).
  # ~/.ssh/config forwards this socket (`ForwardAgent /run/user/<uid>/
  # ssh-agent-fido.sock`) instead of the main agent, so a remote host only
  # ever sees a key that needs a physical touch per signature -- enough for
  # pam_rssh's passwordless sudo (nh os switch --target-host), useless for
  # silently logging in elsewhere or pushing to GitHub as danny.
  flake.modules.nixos.danny-gui =
    { config, pkgs, ... }:
    {
      home-manager.users.${config.my.user.name} = {
        systemd.user.services.ssh-agent-fido = {
          Unit = {
            Description = "ssh-agent holding only the FIDO key, for agent forwarding";
            ConditionPathExists = "%h/.ssh/id_ecdsa_sk";
          };
          Service = {
            Environment = "SSH_AUTH_SOCK=%t/ssh-agent-fido.sock";
            ExecStartPre = "${pkgs.coreutils}/bin/rm -f %t/ssh-agent-fido.sock";
            ExecStart = "${pkgs.openssh}/bin/ssh-agent -D -a %t/ssh-agent-fido.sock";
            # Adding a FIDO key needs no touch; signing with it does.
            ExecStartPost = "${pkgs.bash}/bin/sh -c 'for i in $(seq 50); do [ -S %t/ssh-agent-fido.sock ] && break; sleep 0.1; done; ${pkgs.openssh}/bin/ssh-add %h/.ssh/id_ecdsa_sk'";
            Restart = "on-failure";
          };
          Install.WantedBy = [ "default.target" ];
        };
      };
    };
}
