{ config, lib, pkgs, ... }:

{
  # CLI-only profile - imports the complete CLI configuration
  imports = [
    ../modules/home-manager/cli.nix
  ];
}