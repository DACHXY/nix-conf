{ ... }:
{
  flake.modules.darwin.security = {
    # Touch ID (and Apple Watch) for sudo, plus pam-reattach so it also
    # works inside tmux/screen sessions (e.g. Ghostty + tmux).
    security.pam.services.sudo_local = {
      touchIdAuth = true;
      reattach = true;
    };
  };
}
