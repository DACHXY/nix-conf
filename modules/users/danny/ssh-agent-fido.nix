{
  # A second ssh-agent that holds only a FIDO key. ~/.ssh/config forwards this
  # socket (`ForwardAgent /run/user/<uid>/ssh-agent-fido.sock`) instead of the
  # main agent, so a remote host only ever sees a key that needs the device PIN
  # and a touch per signature -- enough for pam_rssh's sudo (nh os switch
  # --target-host), useless for silently logging in elsewhere or pushing to
  # GitHub as danny.
  #
  # The keys are `-O verify-required`, so the agent asks for the PIN through a
  # graphical askpass on this desktop: a remote sudo pops a PIN dialog here.
  #
  # Only the primary device (RP2350 #1) is loaded. The backups' handles stay in
  # ~/.ssh; if the primary is lost: `SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent-fido.sock
  # ssh-add ~/.ssh/id_ecdsa_sk_rp2040` (or _rp2350b).
  flake.modules.nixos.danny-gui =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      key = "%h/.ssh/id_ecdsa_sk_rp2350a";

      # SSH_ASKPASS for the agent: the PIN goes through pinentry-gnome3 (a
      # masked GTK prompt that follows the system theme); the "touch your key"
      # notices OpenSSH sends with SSH_ASKPASS_PROMPT=none become desktop
      # notifications (shown by noctalia).
      askpass = lib.getExe (
        pkgs.writeShellApplication {
          name = "ssh-askpass-fido";
          runtimeInputs = [
            pkgs.pinentry-gnome3
            pkgs.libnotify
            pkgs.gnused
            pkgs.gnugrep
          ];
          text = ''
            prompt="''${1:-}"
            # Assuan escaping for SETDESC: %, CR and LF.
            desc=$(printf '%s' "$prompt" | sed -e 's/%/%25/g' -e ':a;N;$!ba;s/\n/%0A/g' -e 's/\r/%0D/g')

            case "''${SSH_ASKPASS_PROMPT:-}" in
              none)
                exec notify-send -a SSH -i security-high -t 15000 "SSH" "$prompt"
                ;;
              confirm)
                out=$(printf 'SETTITLE SSH\nSETDESC %s\nCONFIRM\nBYE\n' "$desc" | pinentry-gnome3)
                if printf '%s\n' "$out" | grep -q '^ERR'; then exit 1; fi
                ;;
              *)
                out=$(printf 'SETTITLE SSH\nSETDESC %s\nSETPROMPT PIN\nGETPIN\nBYE\n' "$desc" | pinentry-gnome3)
                if printf '%s\n' "$out" | grep -q '^ERR'; then exit 1; fi
                printf '%s\n' "$out" | sed -n 's/^D //p' | sed -e 's/%0A/\n/g' -e 's/%0D/\r/g' -e 's/%25/%/g'
                ;;
            esac
          '';
        }
      );
    in
    {
      home-manager.users.${config.my.user.name} = {
        systemd.user.services.ssh-agent-fido = {
          Unit = {
            Description = "ssh-agent holding only the FIDO key, for agent forwarding";
            ConditionPathExists = key;
            # Needs the session's WAYLAND_DISPLAY/DISPLAY for the PIN dialog.
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            Environment = [
              "SSH_AUTH_SOCK=%t/ssh-agent-fido.sock"
              "SSH_ASKPASS=${askpass}"
              "SSH_ASKPASS_REQUIRE=force"
            ];
            ExecStartPre = "${pkgs.coreutils}/bin/rm -f %t/ssh-agent-fido.sock";
            ExecStart = "${pkgs.openssh}/bin/ssh-agent -D -a %t/ssh-agent-fido.sock";
            # Adding a FIDO key needs neither the PIN nor a touch; signing does.
            ExecStartPost = "${pkgs.bash}/bin/sh -c 'for i in $(seq 50); do [ -S %t/ssh-agent-fido.sock ] && break; sleep 0.1; done; ${pkgs.openssh}/bin/ssh-add ${key}'";
            Restart = "on-failure";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
