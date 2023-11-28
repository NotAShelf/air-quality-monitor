{
  description = "An air quality monitoring service with a Raspberry Pi and a SDS011 sensor.";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = {
    self,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [./nix/tests];

      systems = ["x86_64-linux" "aarch64-linux"];
      perSystem = {
        self',
        pkgs,
        ...
      }: {
        formatter = pkgs.alejandra;

        packages = {
          default = self'.packages.pi-air-quality-monitor;
          pi-air-quality-monitor = pkgs.callPackage ./nix/default.nix {};
        };

        devShells = {
          default = self'.packages.pi-air-quality-monitor;
          pi-air-quality-monitor = pkgs.mkShell {
            inputsFrom = self'.packages.pi-air-quality-monitor.pythonPath;
          };
        };
      };

      flake = {
        nixosModules = {
          default = self.nixosModules.pi-air-quality-monitor;
          pi-air-quality-monitor = import ./nix/module.nix self;
        };
      };
    };
}
