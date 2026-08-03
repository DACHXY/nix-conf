{ inputs, ... }:
{
  nixpkgs.overlays = [
    inputs.llm-agents.overlays.shared-nixpkgs
  ];

  flake.modules.generic.claude = { pkgs, ... }: {

    environment.systemPackages = with pkgs; [
      claude-monitor
    ];
  };

  flake.modules.homeManger.claude = { pkgs, ... }: {
    programs.claude-code = {
      enable = true;
      package = pkgs.claude-code;
    };
  };
}
