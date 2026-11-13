{
  # kubectl & co. with danny's kubeconfig, personal machines only. The
  # kubeconfig is decrypted by the system sops-nix (root-only host key) and
  # owned by the user.
  flake.modules.generic.danny-personal =
    { config, ... }:
    let
      user = config.my.user.name;
      seed = config.sops.secrets."kubeconfig".path;
    in
    {
      sops.secrets."kubeconfig" = {
        sopsFile = ./secret.yaml;
        owner = user;
        mode = "0400";
      };

      home-manager.users.${user} =
        {
          config,
          pkgs,
          lib,
          ...
        }:
        {
          home.packages = with pkgs; [
            kubectl
            kubelogin
            kubelogin-oidc
            fluxcd
            kubernetes-helm

            # monitor
            flux9s
            k9s
          ];

          home.activation.kubeconfig = lib.hm.dag.entryAfter [ "writeBoundary" ] /* bash */ ''
            kubeDir="${config.home.homeDirectory}/.kube"
            kubeConfig="$kubeDir/config"
            seed="${seed}"
            $DRY_RUN_CMD mkdir -p "$kubeDir"
            # Seed once: only when the live config is missing or is still the old
            # sops symlink. Once kubectl owns a real file we never touch it, so
            # `kubectl config use-context` survives rebuilds.
            if [ -L "$kubeConfig" ] || [ ! -e "$kubeConfig" ]; then
              if [ -e "$seed" ]; then
                $DRY_RUN_CMD rm -f "$kubeConfig"
                $DRY_RUN_CMD install -m600 "$seed" "$kubeConfig"
              fi
            fi
          '';
        };
    };
}
