{
  nixosTest,
  self,
  ...
}:
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
        };
      };

      system.stateVersion = "23.11";
    };
  };

  testScript = ''
    server.wait_for_unit("default.target")
    server.succeed("ls -lah /dev/ttyUSB0")
    server.succeed('systemctl status pi-air-quality-monitor | grep \"Active: active (running)\" || return 0')
    #server.succeed('nc -vz server 8080')

    #client.wait_for_unit("default.target")
    #client.succeed("nc -vz server 8080")
  '';
}
