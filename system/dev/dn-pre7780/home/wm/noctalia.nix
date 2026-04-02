{ ... }:
{
  programs.noctalia-shell.settings = {
    desktopWidgets = {
      monitorWidgets = [
        {
          name = "DP-6";
          widgets = [
            {
              clockColor = "none";
              clockStyle = "binary";
              customFont = "";
              format = "HH:mm\\nd MMMM yyyy";
              id = "Clock";
              roundedCorners = true;
              scale = 2.25675;
              showBackground = false;
              useCustomFont = false;
              x = 25;
              y = 64;
            }
          ];
        }
      ];
    };
  };
}
