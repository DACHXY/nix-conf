{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ step-cli ];

  users.users.step-ca = {
    isSystemUser = true;
    group = "step-ca";
  };

  users.groups.step-ca = { };

  services.step-ca = {
    enable = true;
    address = "0.0.0.0";
    settings = builtins.fromJSON (builtins.readFile /var/lib/step-ca/config/ca.json);
    port = 8443;
    openFirewall = true;
    intermediatePasswordFile = "/run/keys/step-password";
  };
}
