self: {
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types optional;

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
      description = "Whether to open the firewall for the service";
    };

    settings = {
      port = mkOption {
        type = types.int;
        default = 8080;
        description = "Port to run the service on";
      };

      user = mkOption {
        type = types.str;
        default = "pi-aqm";
        description = "User to run the servvice as";
      };

      group = mkOption {
        type = types.str;
        default = "pi-aqm";
        description = "Group to run the service as";
      };

      serialPort = mkOption {
        type = types.path;
        default = "/dev/ttyUSB0";
        description = "Serial port device to read data from";
      };

      environmentFile = mkOption {
        type = with types; nullOr path;
        default = null;
        example = "/etc/pi-aqm.env";
        description = "File to read environment variables from";
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/pi-aqm";
        description = "Directory to store data in";
      };

      redis = {
        createLocally = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to create a Redis instance locally";
        };

        host = mkOption {
          type = types.str;
          default = "localhost";
          description = "Redis host";
        };

        port = mkOption {
          type = types.int;
          default = 6379;
          description = "Redis port";
        };

        redis_db = mkOption {
          type = types.int;
          default = 0;
          description = "Redis database";
        };
      };
    };
  };

  config = mkIf config.services.pi-air-quality-monitor.enable {
    networking.firewall.allowedTCPPorts = [cfg.settings.port];
    users = {
      groups."${cfg.settings.group}" = {};
      users."${cfg.settings.user}" = {
        isSystemUser = true;
        group = "${cfg.settings.group}";
        home = "${cfg.settings.dataDir}";
        createHome = true;
      };
    };

    services.redis = mkIf cfg.settings.redis.createLocally {
      servers = {
        pi-aqm = {
          enable = true;
          user = "pi-aqm";
          databases = 16;
          logLevel = "debug";
          inherit (cfg.settings.redis) port;
        };
      };
    };

    systemd.services."pi-air-quality-monitor" = let
      globalEnv = pkgs.writeText "global.env" ''
        PORT=${toString cfg.settings.port}
        SERIAL_DEVICE=${cfg.settings.serialPort}
      '';

      redisEnv = pkgs.writeText "redis.env" ''
        REDIS_HOST=${cfg.settings.redis.host}
        REDIS_PORT=${toString cfg.settings.redis.port}
        REDIS_DB=${toString cfg.settings.redis.redis_db}
      '';
    in {
      description = "An air quality monitoring service with a Raspberry Pi and a SDS011 sensor";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        Type = "simple";
        User = cfg.settings.user;
        Group = cfg.settings.group;
        EnvironmentFile = lib.concatLists [
          [globalEnv]
          (optional (cfg.settings.environmentFile != null) [cfg.settings.environmentFile])
          (optional cfg.settings.redis.createLocally [redisEnv])
        ];
        WorkingDirectory = "${cfg.settings.dataDir}";
        ExecStart = "${lib.getExe cfg.package}";
        Restart = "always";

        # Hardening
        CapabilityBoundingSet = "";
        DeviceAllow = [cfg.settings.serialPort];
        DevicePolicy = "closed";
        DynamicUser = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = false;
        NoNewPrivileges = true;
        PrivateUsers = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        RemoveIPC = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        UMask = "0077";
        SystemCallFilter = [
          "@system-service @pkey"
          "~@privileged @resources"
        ];
      };
    };
  };
}
