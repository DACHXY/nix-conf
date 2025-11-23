{
  lib,
  config,
  osConfig,
  ...
}:
let
  inherit (lib.generators) mkLuaInline;
  inherit (osConfig.systemConf) username;
  relativeDir = "projects/leetcode";
  dataDir = "${config.home.homeDirectory}/${relativeDir}";
in
{
  programs.nvf.settings.vim.utility.leetcode-nvim = {
    enable = true;
    setupOpts = {
      image_support = true;
      lang = "rust";
      plugins.non_standalone = true;
      storage.home = mkLuaInline ''"${dataDir}"'';
      injector = mkLuaInline ''
        {
          ['rust'] = {
            before = { '#[allow(dead_code)]', 'fn main() {}', '#[allow(dead_code)]', 'struct Solution;' },
          }
        }
      '';
      hooks."question_enter" = [
        (mkLuaInline
          # lua
          ''
            function (question)
              if question.lang ~= 'rust' then
                return
              end

              local config = require("leetcode.config")
              local problem_dir = config.user.storage.home .. "/Cargo.toml"
              local content = [[
                [package]
                name = "leetcode"
                edition = "2024"

                [lib]
                name = "%s"
                path = "%s"

                [dependencies]
                rand = "0.8"
                regex = "1"
                itertools = "0.14.0"
              ]]

              local file = io.open(problem_dir, "w")
              if file then
                local formatted = (content:gsub(" +", "")):format(question.q.frontend_id, question:path())
                file:write(formatted)
                file:close()
              else
                print("Failed to open file " .. problem_dir)
              end
            end
          ''
        )
      ];
    };
  };

  systemd.user.tmpfiles.rules = [
    "d ${dataDir} 0744 ${username} users -"
  ];
}
