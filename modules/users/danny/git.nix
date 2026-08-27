{
  flake.modules.homeManager.danny = { ... }: {
    programs.git = {
      includes = [
        {
          condition = "hasconfig:remote.*.url:*gitlab.it.cs.nycu.edu.tw*";
          contents = {
            user = {
              name = "Chen-Wei Chang";
              email = "cchenwei@cs.nctu.edu.tw";
            };
          };
        }
      ];
    };
  };
}
