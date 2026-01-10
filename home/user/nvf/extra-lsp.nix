{ pkgs, ... }:
{
  programs.nvf.settings.vim = {
    diagnostics.nvim-lint.linters_by_ft = {
      dockerfile = [ "hadolint" ];
    };
    treesitter.grammars = with pkgs.vimPlugins.nvim-treesitter-parsers; [
      dockerfile
    ];
    extraPackages = with pkgs; [
      # docker
      hadolint
      dockerfile-language-server
      docker-compose-language-service
    ];

    lsp.servers = {
      dockerls = { };
      docker_compose_language_service = { };
    };
  };
}
