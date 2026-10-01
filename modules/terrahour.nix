# terrahour — terminal world clock with a day/night map (https://github.com/ACoci86/terrahour)
{ ... }:
{
  flake.modules.generic.base =
    { pkgs, ... }:
    let
      version = "1.0.2";

      terrahour = pkgs.python3Packages.buildPythonApplication {
        pname = "terrahour";
        inherit version;

        pyproject = true;
        src = pkgs.fetchFromGitHub {
          owner = "ACoci86";
          repo = "terrahour";
          tag = "v${version}";
          hash = "sha256-1zr+QvkTcaccZvU+s0+Q35MTOzbj7mjq3h9pQdXx4qw=";
        };

        build-system = [ pkgs.python3Packages.setuptools ];
        nativeCheckInputs = with pkgs.python3Packages; [
          pytest
          pillow
        ];

        meta = {
          description = "World clock for the terminal with a day and night map and a 24-hour timeline";
          homepage = "https://github.com/ACoci86/terrahour";
          license = pkgs.lib.licenses.mit;
          mainProgram = "terrahour";
        };
      };
    in
    {
      environment.systemPackages = [ terrahour ];
    };
}
