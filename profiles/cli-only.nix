{ config, lib, pkgs, ... }:

{
  # CLI-only profile - imports the complete CLI configuration
  imports = [
    ../modules/home/cli.nix
  ];
}
