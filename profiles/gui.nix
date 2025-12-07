{ config, lib, pkgs, ... }:

{
  # GUI profile - imports CLI + GUI configurations
  # This profile includes all CLI tools plus GUI applications
  # Does NOT include system-level configurations (drivers, hardware, kernel)

  imports = [
    ../home-manager/cli.nix
    ../home-manager/gui.nix
  ];

  # Additional GUI-specific home-manager settings can be added here
}
