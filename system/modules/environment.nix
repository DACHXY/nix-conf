{ pkgs, ... }:

{
  environment.variables = {
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    GSETTINGS_SCHEMA_DIR = "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}/glib-2.0/schemas";
  };
}
