{
  self,
  config,
  inputs,
  lib,
  ...
}: {
  perSystem = {
    pkgs,
    self',
    ...
  }: let
    callPackage = lib.callPackageWith (pkgs
      // {
        inherit (config.flake) nixosModules;
        inherit inputs;
      });
  in {
    packages.test = self'.checks.basic.driverInteractive;

    checks = {
      basic = callPackage ./checks/basic.nix {inherit self self';};
      default = self'.checks.basic;
    };
  };
}
