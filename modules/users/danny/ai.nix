{
  config,
  ...
}:
let
  globalConfig = config;
in
{
  flake.modules.generic.danny-ai =
    { pkgs, config, ... }:
    {
      sops.secrets."cc/mcp-endpoint" = {
        sopsFile = ./secret.yaml;
        mode = "0444";
      };

      environment.systemPackages = [
        (pkgs.writeShellApplication {
          name = "cc-claude-config";
          runtimeInputs = with pkgs; [ claude-code ];
          text = ''
            claude mcp add --transport http gitlab-mcp "$(cat ${config.sops.secrets."cc/mcp-endpoint".path})"
          '';
        })
      ];
    };

  flake.modules.nixos.danny-ai =
    { ... }:
    {
      imports = with globalConfig.flake.modules; [ generic.danny-ai ];
      security.pki.certificates = [
        # CSCC
        ''
          -----BEGIN CERTIFICATE-----
          MIIGfTCCBGWgAwIBAgIJANtNHd4pchD1MA0GCSqGSIb3DQEBDQUAMIHUMQswCQYD
          VQQGEwJUVzEPMA0GA1UECAwGVGFpd2FuMRYwFAYDVQQHDA1Ic2luLUNodSBDaXR5
          MScwJQYDVQQKDB5OYXRpb25hbCBDaGlhby1UdW5nIFVuaXZlcnNpdHkxJzAlBgNV
          BAsMHkRlcGFydG1lbnQgb2YgQ29tcHV0ZXIgU2NpZW5jZTEmMCQGA1UEAwwdTkNU
          VSBDUyBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkxIjAgBgkqhkiG9w0BCQEWE2hlbHBA
          Y3MubmN0dS5lZHUudHcwHhcNMTcxMjA2MTc0MzE2WhcNMjcxMjA0MTc0MzE2WjCB
          1DELMAkGA1UEBhMCVFcxDzANBgNVBAgMBlRhaXdhbjEWMBQGA1UEBwwNSHNpbi1D
          aHUgQ2l0eTEnMCUGA1UECgweTmF0aW9uYWwgQ2hpYW8tVHVuZyBVbml2ZXJzaXR5
          MScwJQYDVQQLDB5EZXBhcnRtZW50IG9mIENvbXB1dGVyIFNjaWVuY2UxJjAkBgNV
          BAMMHU5DVFUgQ1MgQ2VydGlmaWNhdGUgQXV0aG9yaXR5MSIwIAYJKoZIhvcNAQkB
          FhNoZWxwQGNzLm5jdHUuZWR1LnR3MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
          CgKCAgEAvOZF59xipyzkRVbWTqMCf94ucr4ze6mTtctDnqpFFRfFC0ksXKVFZbhf
          /N9dSTw+i8WJQY/RZc5jHNx7E+fnNdURBQniyuiXBTTicoVYp1Uef56CAYbEZDfp
          VQmmovcGv8gEuZ4L/CFMwsFFFab2epS7A7u7wk0dnhFBpvC0RigqQIwtlBc/M0WA
          a8C9cwBzxpblpa0TY3pMbI3KPxLnflTrlPqCrlcWCuChen3Z1Lzu5C9EgavPJsYU
          bmGwOayP4cie59dVYzCrmi6/XHMsfWuJ4vAHVOJqV1JeKbS65MfOVE+UVNKAGaLO
          a6RaVcy0M5IAhTGSi+kZeBgVC0c5yoNZ7NHyG1EOOBg6CoNsWW4B8F2780s6ofRG
          Ukl2+HGf6nvqgUsU3cyyZ09OFk4gDTPAj24VSG5uAdCUst1aaTxwl2yr1jNHSy3R
          pxjGkx7DGWBveRwFl9sTxAyD+k/7eJ+ygJk4D5JxaMsOM334aBwsYoqhzwePL7SC
          LXcj92qj4DFasCmQSFUpKkT7YLJvTi16RwGM2qGklSTfxm5jWCI6XXNTkgyPZXZd
          76QnyCkT3w224M/g5MziPFyMrHfYnJl2tX2AKq6qS32uk6UQw1FH4lpxPuLc5F//
          yXG4/5j3+apMm3jhFcIQ3vuqZV3kz88HeeuBPbRwajkrhPxS/BcCAwEAAaNQME4w
          HQYDVR0OBBYEFNPLn9RQJ0u6prsffVi3a0QGxSgjMB8GA1UdIwQYMBaAFNPLn9RQ
          J0u6prsffVi3a0QGxSgjMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQENBQADggIB
          AGd5PjBAeWqpAM7kaGrKHY/d+kS1tKPH/c9HJcIsrZGNImKyuJ0KXLhmwIBMrARQ
          9Ly2km8FZEo1LKPd6EYzKzru/xUdY/vz2UO/4aouOyNn6rI9umXaahPKElSN6gka
          NIPY7DpGcaCmtMzE13e7wbh9IkqwWPrzRNwaZKybWyWp6/AJCSc6PoqqW0+3plBA
          XuCDlM6XJF8duqWcdJKBcdCwdYdrHtb0xcwEG4XF+G04R6uEA0AfCIylvwjOAKN/
          5AeiYJ+hz837XE3i1CZmsNR5uo1erijVuyMN8DD/9pr2QwYP/4b7nCSDMckTrHez
          um7gMtYIoy4OnLvSddjUboRpor/iaE1H/3LK1gvnMbII45EhUdPKIN2/nlfY0g5T
          jx9OW2UXl33WlZT7oA1II87CV2H6k72TnH6fDjGFepWPsnJQ+Fk7+zHSbJEIFJzr
          49rK+dahSjt3C9GB7aJu/NOhGA1W8iaWEyYPO/FOfmvJZwMlZgbeN0utWyJ1zsi5
          DWaofN3JwjaAD4nJfIbTF1iINJ3NhjIRETTQ31G/AWhV8H8ZCK+4iE+rQ3OuWzYU
          vd5u4z/jaVcUnJKukM0e9VAgxEC7A8rRFgko5XjKXrCZgkzbhQWA0uzYvx0ghIMe
          x8AH/WxuNFhZq3OmgppgVaGeuOvN7xSEbLACAOekJWp1
          -----END CERTIFICATE-----
        ''
      ];
    };
}
