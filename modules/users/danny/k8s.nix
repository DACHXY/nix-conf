{
  # Decrypted by the system sops-nix (root-only host key) and owned by the
  # user; shared by NixOS and nix-darwin through generic.danny.
  flake.modules.generic.danny =
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
        seed="${osConfig.sops.secrets."kubeconfig".path}"
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
}
