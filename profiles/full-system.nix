{ config, lib, pkgs, ... }:

{
  # Full system profile - CLI + potential GUI additions
  imports = [
    ../modules/home-manager/cli.nix
  ];

  # Additional packages for full system (if needed)
  home.packages = with pkgs; [
    # GUI applications can be added here
    # Currently most GUI apps are managed at system level
  ];

  # Additional program configurations for full system
  programs = {
    # GUI-specific program configurations can be added here
  };
}