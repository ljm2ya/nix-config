# NixOS System Configuration - Base
# This is a modularized version of the original /etc/nixos/configuration.nix

{ config, pkgs, lib, inputs, ... }:

let
  # =================================================================
  #  SYSTEM PROFILE SWITCH
  #  Change this to 'true' to activate Nvidia configuration.
  #  Change to 'false' for Intel Integrated graphics only.
  # =================================================================
  enableNvidia = false;
in
{
  imports = [
    /etc/nixos/hardware-configuration.nix
    ./desktop.nix
  ];

  #=== Boot Configuration ===
  boot = {
    loader = {
     systemd-boot.enable = true;
     systemd-boot.sortKey = "z-nixos";
     efi.canTouchEfiVariables = false;
    };

    # Kernel Parameters: Conditional based on GPU
    kernelParams = [
      "resume=${config.boot.resumeDevice}"
    ] ++ (if enableNvidia then [
      "nvidia-drm.modeset=1" # Essential for NVIDIA hibernation/wayland
    ] else [
      "i915.enable_guc=3"    # Intel GuC for iGPU
    ]);
    kernelModules = ["iwlwifi"];
    resumeDevice = "/dev/disk/by-uuid/5a4cf021-8203-453b-877f-164c5c6e1128";
  };

  # auto cleanup old nixos builds
  nix.gc = {
     automatic = true;
     dates = "weekly";
     options = "--delete-older-than 7d";
  };

  # === Power Management ===
  powerManagement.enable = true;

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend";
    HandlePowerKey = "hibernate";
    HandlePowerKeyLongPress = "poweroff";
    PowerKeyIgnoreInhibited = "yes";
  };

  swapDevices = [{
    device = "/dev/disk/by-uuid/5a4cf021-8203-453b-877f-164c5c6e1128";
  }];

  # === Networking ===
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    nameservers = ["1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one"];
  };

  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = ["~."];
    fallbackDns = ["1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one"];
    dnsovertls = "true";
  };

  # === Locale & Time ===
  time.timeZone = "Asia/Seoul";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-mozc
        kdePackages.fcitx5-qt
        fcitx5-hangul
      ];
    };
  };

  # === Audio ===
  security.rtkit.enable = true; # Realtime scheduler for Pipewire

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    extraConfig = {
      pipewire."99-silent-bell.conf" = {
        "context.properties" = {
          "module.x11.bell" = false;
        };
      };
    };
  };

  # === Bluetooth ===
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true; # Show battery charge
      };
    };
  };
  services.blueman.enable = true;

  # === User Configuration ===
  users.users.zeno = {
    isNormalUser = true;
    description = "zeno";
    extraGroups = ["networkmanager" "wheel" "video" "render" ];
    packages = with pkgs; [];
  };
  users.defaultUserShell = pkgs.zsh; # Keep zsh available, but configuration managed by home-manager

  services.getty.autologinUser = "zeno";

  # === Services ===
  services = {
    gvfs.enable = true;      # Mount, trash, and other functionalities
    tumbler.enable = true;   # Thumbnail support for images
    openssh.enable = true;
    # Note: lorri migrated to home-manager per-user configuration
    acpid.enable = true; # battery status deamon
    mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
    };
    tailscale.enable = true; # Keep system-level for network service
  };

  # === Packages ===
  nixpkgs.config.allowUnfree = true;

  # System utilities (keep at system level)
  environment.systemPackages = with pkgs; [
    home-manager
    ffmpeg
    pamixer
    p7zip
    usbutils
    brightnessctl
  ];

  # === System Version ===
  # Don't change this after first install
  system.stateVersion = "25.05";
}