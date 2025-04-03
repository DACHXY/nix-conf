{
  pkgs,
  inputs,
  settings,
  ...
}:
{
  imports = [
    (import ../../modules/nvidia.nix {
      nvidia-mode = settings.nvidia.mode;
      intel-bus-id = settings.nvidia.intel-bus-id;
      nvidia-bus-id = settings.nvidia.nvidia-bus-id;
    })
    ./hardware-configuration.nix
    ./boot.nix
    ./packages.nix
    ./services.nix
    ./networking.nix
    ../../modules/presets/minimal.nix
    ../../modules/bluetooth.nix
    ../../modules/cuda.nix
    ../../modules/gc.nix
  ];

  environment.systemPackages = with pkgs; [
    ferium
  ];

  home-manager = {
    users."${settings.personal.username}" = {
      imports = [
        ../../../home/user/config.nix
        ../../../home/user/direnv.nix
        ../../../home/user/environment.nix
        ../../../home/user/git.nix
        ../../../home/user/nvim.nix
        ../../../home/user/shell.nix
        ../../../home/user/tmux.nix
        ../../../home/user/yazi.nix
        {
          home.packages = with pkgs; [
            inputs.ghostty.packages.${system}.default
            (python3.withPacakges (
              p: with p; [
                pip
              ]
            ))
          ];
        }
      ];
    };
  };
}
