{
  # On NixOS the kubeconfig is decrypted by the system sops-nix (root-only
  # host key) and owned by the user; nix-darwin keeps the home-manager secret.
  flake.modules.nixos.danny =
    { config, ... }:
    {
      sops.secrets."kubeconfig" = {
        sopsFile = ./secret.yaml;
        owner = config.my.user.name;
        mode = "0400";
      };
    };

  flake.modules.homeManager.danny =
    {
      config,
      pkgs,
      lib,
      osConfig,
      ...
    }:
    let
      seedFile =
        if pkgs.stdenv.isLinux then
          osConfig.sops.secrets."kubeconfig".path
        else
          "${config.home.homeDirectory}/.kube/config.sops";
    in
    lib.mkMerge [
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
          seed="${seedFile}"
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
      }

      (lib.mkIf pkgs.stdenv.isDarwin {
        sops.secrets."kubeconfig" = {
          sopsFile = ./secret.yaml;
          path = "${config.home.homeDirectory}/.kube/config.sops";
          mode = "0400";
        };
      })
    ];
}
