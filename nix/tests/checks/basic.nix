{
  nixosTest,
  self,
  ...
}: let
  serialPort = "/dev/ttyS0";
in
  nixosTest {
    name = "basic";

    nodes = {
      client = {pkgs, ...}: {
        imports = [../profiles/test-setup.nix];

        environment.systemPackages = with pkgs; [
          netcat
        ];
      };

      server = {pkgs, ...}: {
        imports = [
          ../profiles/test-setup.nix
          self.nixosModules.pi-air-quality-monitor
        ];

        users.users.test = {
          isNormalUser = true;
          extraGroups = ["wheel"];
          packages = with pkgs; [
            tree
          ];
        };

        services.pi-air-quality-monitor = {
          enable = true;
          openFirewall = true;

          settings = {
            port = 8080;
            user = "pi-aqm";
            group = "pi-aqm";
            inherit serialPort;
          };
        };

        system.stateVersion = "23.11";
      };
    };

    testScript = ''
      server.start()

      server.wait_for_unit("default.target")
      log.info("Checking if configured serial port exists")
      server.succeed("ls -lah ${serialPort}")

      log.info("Check if unit is running correctly")
      server.wait_for_unit("pi-air-quality-monitor.service")
      server.succeed("systemctl status pi-air-quality-monitor.service | grep 'Active: active (running)' >&2")
      server.succeed("journalctl -u pi-air-quality-monitor.service >&2")

      log.info("Showing units content")
      server.succeed("systemctl status pi-air-quality-monitor.service >&2")
      server.succeed("systemctl cat pi-air-quality-monitor.service >&2")
      server.succeed("systemctl cat pi-air-quality-monitor.socket >&2")

      log.info("Checking if service is accessible locally")
      server.succeed("nc -vz localhost 8080")

      client.start()
      client.wait_for_unit("default.target")
      #client.succeed("nc -vz server 8080")
    '';
  }
