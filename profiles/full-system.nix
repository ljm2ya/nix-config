{ config, lib, pkgs, ... }:

{
  # Full system profile - includes CLI + Desktop configurations
  # This profile is used with modules/nixos/configuration.nix for complete system
  imports = [
    ./desktop.nix  # Imports both CLI and desktop configurations
  ];

  # Additional full-system specific home-manager configurations
  # can be added here if needed
}
