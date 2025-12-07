{ config, lib, pkgs, ... }:

{
  # Desktop profile - imports CLI + Desktop configurations
  # This profile includes all CLI tools plus desktop applications
  # Does NOT include system-level configurations (drivers, hardware, kernel)

  imports = [
    ../modules/home/cli.nix
    ../modules/home/desktop.nix
  ];

  # Additional desktop-specific home-manager settings can be added here
}
