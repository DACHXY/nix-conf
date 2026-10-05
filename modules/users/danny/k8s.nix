{
  flake.modules.homeManager.danny =
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
        k9s
      ];

      sops.secrets."kubeconfig" = {
        sopsFile = ./secret.yaml;
        path = "${config.home.homeDirectory}/.kube/config.sops";
        mode = "0400";
      };

      home.activation.kubeconfig = lib.hm.dag.entryAfter [ "writeBoundary" ] /* bash */ ''
        kubeDir="${config.home.homeDirectory}/.kube"
        kubeConfig="$kubeDir/config"
        $DRY_RUN_CMD mkdir -p "$kubeDir"
        # Seed once: only when the live config is missing or is still the old
        # sops symlink. Once kubectl owns a real file we never touch it, so
        # `kubectl config use-context` survives rebuilds.
        if [ -L "$kubeConfig" ] || [ ! -e "$kubeConfig" ]; then
          if [ -e "$kubeDir/config.sops" ]; then
            $DRY_RUN_CMD rm -f "$kubeConfig"
            $DRY_RUN_CMD install -m600 "$kubeDir/config.sops" "$kubeConfig"
          fi
        fi
      '';
    };
}
