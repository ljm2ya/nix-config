{ config, lib, pkgs, ... }:

{
  # CLI-only profile - imports the complete CLI configuration
  imports = [
    ../home-manager/cli.nix
  ];
}
