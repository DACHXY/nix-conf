{ pkgs, ... }:

{
  console = {
    earlySetup = true;
    font = "ter-124b";
    useXkbConfig = true;
    packages = with pkgs; [ terminus_font ];
  };
}
