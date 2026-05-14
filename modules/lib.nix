{ inputs, ... }:
{
  flake.lib =
    let
      inherit (inputs.nixpkgs) lib;
      inherit (lib)
        optionalString
        toUpper
        substring
        concatStringsSep
        splitString
        ;
    in
    {
      capitalize = text: "${toUpper (substring 0 1 text)}${substring 1 (-1) text}";

      nftables = {
        mkElementsStatement =
          elements:
          optionalString (builtins.length elements > 0) "elements = { ${concatStringsSep "," elements} }";
      };

      ldap = {
        getOlcSuffix = domain: concatStringsSep "," (map (dc: "dc=${dc}") (splitString "." domain));
      };
    };
}
