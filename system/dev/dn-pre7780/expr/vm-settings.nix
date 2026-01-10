{
  pkgs,
  lib,
  inputs,
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;

  vmList =
    let
      kubeMasterIP = "192.168.0.6";
      kubeMasterHostname = "api.kube";
      kubeMasterAPIServerPort = 6443;
      kubeApi = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
    in
    {
      # master
      vm-1 = {
        ip = "192.168.0.6";
        mac = "02:00:00:00:00:01";
        extraConfig = {
          networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";
          environment.systemPackages = with pkgs; [
            kompose
            kubectl
            kubernetes
          ];

          services.kubernetes = {
            roles = [
              "master"
              "node"
            ];

            masterAddress = kubeMasterHostname;
            apiserverAddress = kubeApi;
            easyCerts = true;
            apiserver = {
              securePort = kubeMasterAPIServerPort;
              advertiseAddress = kubeMasterIP;
            };

            addons.dns.enable = true;
          };

          systemd.services.link-kube-config = {
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.writeShellScript "link-kube-config.sh" ''
                target="/etc/kubernetes/cluster-admin.kubeconfig"
                if [ -e "$target" ]; then
                  [ ! -d "/root/.kube" ] && mkdir -p "/root/.kube"
                  ln -sf $target /root/.kube/config
                fi
              ''}";
            };
          };
        };
      };

      # Node
      vm-2 = {
        ip = "192.168.0.7";
        mac = "02:00:00:00:00:02";
        extraConfig = {
          networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";

          environment.systemPackages = with pkgs; [
            kompose
            kubectl
            kubernetes
          ];

          services.kubernetes = {
            roles = [ "node" ];
            masterAddress = kubeMasterHostname;
            easyCerts = true;

            kubelet.kubeconfig.server = kubeApi;
            apiserverAddress = kubeApi;
            addons.dns.enable = true;
          };
        };
      };
    };

  mkMicrovm = name: value: {
    hypervisor = "qemu";
    vcpu = 4;
    mem = 8192;
    interfaces = [
      {
        type = "tap";
        id = "${name}";
        mac = value.mac;
      }
    ];
    shares = [
      {
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
      }
    ];
  };
in
lib.mapAttrs' (
  name: value:
  lib.nameValuePair name (
    lib.nixosSystem {
      inherit system;
      modules = [
        inputs.microvm.nixosModules.microvm
        value.extraConfig
        {
          microvm = mkMicrovm name value;
          system.stateVersion = lib.trivial.release;
          networking.hostName = name;
          networking.domain = "kube";
          networking.firewall.enable = false;
          users.users.root.password = "";
          services.getty.autologinUser = "root";

          programs.fish.enable = true;
          programs.bash = {
            shellInit = ''
              if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
              then
                shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
                exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
              fi
            '';
          };

          systemd.network.enable = true;
          systemd.network.networks."20-lan" = {
            matchConfig.Type = "ether";
            networkConfig = {
              Address = [ "${value.ip}/24" ];
              Gateway = "192.168.0.1";
              DNS = [ "192.168.0.1" ];
              DHCP = "no";
            };
          };

          systemd.services.br-netfilter = {
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              ExecStart = "/run/current-system/sw/bin/modprobe br_netfilter";
            };
          };

          environment.systemPackages = with pkgs; [
            dig.dnsutils
            openssl

            fishPlugins.done
            fishPlugins.fzf-fish
            fishPlugins.forgit
            fishPlugins.hydro
            fzf
            fishPlugins.grc
            grc
            git
          ];
        }
      ];
    }
  )
) vmList
