{ self, ... }:
{
  flake.modules.homeManager.danny =
    { osConfig, lib, ... }:
    let
      inherit (lib) mkForce;
      inherit (self.lib) capitalize;
      username = osConfig.my.user.name;
      profileName = "${capitalize username}_Profile";
    in
    {
      programs.zen-browser.profiles.${profileName} = {
        pins = mkForce {
          "Instagram" = {
            id = "9813885d-e361-420a-9018-dfaa1f2cbdb9";
            url = "https://www.instagram.com/direct/t";
            isEssential = true;
            position = 100;
          };
          "Youtube" = {
            id = "c4474b1d-462c-4362-8d79-a7f61f560bd8";
            url = "https://www.youtube.com";
            isEssential = true;
            position = 110;
          };
          "AniGamer" = {
            id = "e73966f0-4a8a-46ca-8200-6be859b6058a";
            url = "https://ani.gamer.com.tw";
            isEssential = true;
            position = 120;
          };
          "Github" = {
            id = "77d6c637-0fcd-456e-b7e6-f161325a2a91";
            url = "https://github.com";
            isEssential = true;
            position = 130;
          };
          "ChatGPT" = {
            id = "3703b7f4-b2c0-4b0e-98c1-f02aa2f7ec09";
            url = "https://chatgpt.com";
            isEssential = true;
            position = 140;
          };
          "Discord" = {
            id = "ff47d812-b089-4fa3-b1b0-8f8d7def5b63";
            url = "https://discord.com/app";
            isEssential = true;
            position = 150;
          };
          "nextcloud" = {
            id = "09f7ca95-9c82-46df-822a-47ffc8fa3eb0";
            url = "https://nextcloud.dnywe.com";
            position = 160;
          };
          "Home" = {
            id = "74bc74e7-fd42-4a44-a9ab-f1b85eef4bae";
            url = "https://www.dnywe.com";
            position = 170;
          };
          "Notion" = {
            id = "42ed89c2-820c-4a48-824e-39c8bd94b67c";
            url = "https://notion.so";
            position = 180;
          };
          "Element" = {
            id = "ad60fc37-6ee7-4591-9760-f5f50a7c948f";
            url = "https://element.dnywe.com";
            position = 190;
          };
          "ntfy" = {
            id = "922a3de0-f2e8-4efb-b6c0-9499095c00e8";
            url = "https://ntfy.dnywe.com";
            position = 200;
          };
          "teams" = {
            id = "1b43051f-d873-4854-a99a-fdec88a5240f";
            url = "https://teams.cloud.microsoft";
            position = 210;
          };
        };
        pinsForce = mkForce true;
      };
    };
}
