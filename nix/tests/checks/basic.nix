{
  nixosTest,
  self,
  self',
  lib,
  ...
}: let
  serialPort = "/dev/pts/2";
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

      server.wait_for_unit("network.target")
      log.info("Checking if configured serial port exists")
      serialPort = server.succeed("${lib.getExe self'.packages.dummy-serial} --quiet")

      if any(serialPort):
        log.info("Serial port exists!")
      else:
        log.info("Serial port does not exist")

      log.info("Check if unit is running correctly")
      server.wait_for_unit("pi-air-quality-monitor.service")
      server.succeed("systemctl status pi-air-quality-monitor.service | grep 'Active: active (running)'")
      server.fail("journalctl -xeu pi-air-quality-monitor.service | grep 'RuntimeError'")

      log.info("Checking if service is accessible locally")
      server.succeed("curl --fail http://localhost:8080 | grep 'Air'")

      client.start()
      client.wait_for_unit("network.target")
      client.succeed("nc -vz server 8080")
    '';
  }
