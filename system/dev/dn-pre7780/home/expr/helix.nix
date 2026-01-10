{
  osConfig,
  lib,
  pkgs,
  ...
}:
{
  programs.helix = {
    enable = true;
    extraPackages = with pkgs; [
      nixd
      bash-language-server
      docker-language-server
      fish-lsp
      typescript-language-server
      superhtml
      hyprls
      jq-lsp
      vscode-json-languageserver
      texlab # Latex
      lua-language-server
      marksman # Markdown
      clang-tools # Clangd
      intelephense # Php
      ruff # Python
      rust-analyzer
      vscode-css-languageserver
      systemd-lsp
      taplo
      vue-language-server
      yaml-language-server
      zls
    ];
    settings = {
      editor.cursor-shape = {
        normal = "block";
        insert = "bar";
        select = "underline";
      };
      keys.normal = {
        space.space = "file_picker";
        G = "goto_file_end";
        D = "kill_to_line_end";
        V = [ "extend_to_line_bounds" ];
        "$" = "goto_line_end";
        "^" = "goto_line_start";
        x = "delete_selection";
        esc = [
          "collapse_selection"
          "keep_primary_selection"
        ];
        space.w = ":w";
        space.q = ":q";
      };
    };
    languages.language = [
      {
        name = "nix";
        auto-format = true;
      }
    ];
    languages.language-server = {
      nixd = {
        command = "nixd";
        args = [ "--semantic-tokens=true" ];
        config.nixd =
          let
            myFlake = ''(builtins.getFlake "/etc/nixos")'';
            nixosOpts = "${myFlake}.nixosConfigurations.${osConfig.networking.hostName}.options";
          in
          {
            nixpkgs.expr = "import ${myFlake}.inputs.nixpkgs { }";
            formatting.command = [ "${lib.getExe pkgs.nixfmt}" ];
            options = {
              nixos.expr = nixosOpts;
              home-manager.expr = "${nixosOpts}.home-manager.users.type.getSubOptions []";
            };
          };
      };
    };
  };
}
