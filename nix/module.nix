self: {
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;

  cfg = config.services.pi-air-quality-monitor;
in {
  options.services.pi-air-quality-monitor = {
    enable = mkEnableOption "pi-air-quality-monitor";
    package = mkOption {
      type = types.package;
      default = self.packages.${pkgs.system}.pi-air-quality-monitor;
    };
    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to open the firewall for the server";
    };

    settings = {
      port = mkOption {
        type = types.int;
        default = 8080;
        description = "Port to run the server on";
      };

      user = mkOption {
        type = types.str;
        default = "pi-aqm";
        description = "User to run the server as";
      };

      group = mkOption {
        type = types.str;
        default = "pi-aqm";
        description = "Group to run the server as";
      };
    };
  };

  config = mkIf config.services.pi-air-quality-monitor.enable {
    networking.firewall.allowedTCPPorts = [cfg.settings.port];
    users = {
      users.pi-aqm = {
        isSystemUser = true;
        group = "pi-aqm";
        home = "/var/lib/pi-aqm";
        createHome = true;
      };

      groups.pi-aqm = {};
    };

    systemd.services."pi-air-quality-monitor" = {
      description = "An air quality monitoring service with a Raspberry Pi and a SDS011 sensor";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        Type = "simple";
        User = cfg.settings.user;
        Group = cfg.settings.group;
        WorkingDirectory = "/var/lib/pi-aqm";
        ExecStart = "${lib.getExe cfg.package}";
        Restart = "always";
      };
    };
  };
}
