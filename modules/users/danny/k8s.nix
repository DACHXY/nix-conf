{
  flake.modules.homeManager.danny = { config, pkgs, ... }: {
    home.packages = with pkgs; [
      kubectl
      kubelogin
      kubelogin-oidc
    ];

    sops.secrets."kubeconfig" = {
      sopsFile = ./secret.yaml;
      path = "${config.home.homeDirectory}/.kube/config";
    };
  };
}
