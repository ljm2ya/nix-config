# NixOS Full System Configuration
# This is the complete configuration including base system + GUI
# Maps to /etc/nixos/configuration.nix

{ config, pkgs, lib, ... }:

{
  imports = [
    ./base.nix       # Hardware, drivers, kernel, system services
    ./desktop.nix    # X11, window managers, fonts, desktop environment services
  ];

  # Additional full-system specific configurations can be added here
}
