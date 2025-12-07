# NixOS Full System Configuration
# This is the complete configuration including base system + GUI
# Maps to /etc/nixos/configuration.nix

{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./base.nix    # Hardware, drivers, kernel, system services
    ./gui.nix     # X11, window managers, fonts, GUI system services
  ];

  # Additional full-system specific configurations can be added here
}
