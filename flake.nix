{
  description = "An air quality monitoring service with a Raspberry Pi and a SDS011 sensor.";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = ["aarch64-linux"];
    forEachSystem = nixpkgs.lib.genAttrs systems;
    pkgsForEach = nixpkgs.legacyPackages;
  in rec {
    packages = forEachSystem (system: {
      default = pkgsForEach.${system}.callPackage ./nix {};
    });

    devShells = forEachSystem (system: {
      default = pkgsForEach.${system}.callPackage ./nix/shell.nix {};
    });

    hydraJobs = packages;
  };
}
