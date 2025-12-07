{ config, lib, pkgs, ... }:

{
  # Full system profile - includes CLI + GUI configurations
  # This profile is used with system/configuration.nix for complete system
  imports = [
    ./gui.nix  # Imports both CLI and GUI configurations
  ];

  # Additional full-system specific home-manager configurations
  # can be added here if needed
}
