{ config, pkgs, lib, ... }:

let
  # =================================================================
  #  SYSTEM PROFILE SWITCH
  #  Change this to 'true' to activate Nvidia configuration.
  #  Change to 'false' for Intel Integrated graphics only.
  # =================================================================
  enableNvidia = false;
in
{
  # Base system configuration - hardware, drivers, kernel, system services
  # This module contains ONLY system-level configurations
  # GUI configurations are in system/gui.nix

  imports = [
    ./hardware-configuration.nix
  ];

  # === Boot Configuration ===
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

  # === Nix Configuration ===
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # === Power Management ===
  powerManagement.enable = true;

  services.logind.extraConfig = ''
    HandleLidSwitch=suspend-then-hibernate
    HandleLidSwitchExternalPower=suspend
    HandlePowerKey=hibernate
    HandlePowerKeyLongPress=poweroff
    PowerKeyIgnoreInhibited=yes
  '';

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

  # === Graphics Configuration (Conditional) ===
  hardware.graphics = {
    enable = true;
    # Load Intel specific media drivers ONLY if we are NOT using Nvidia mode
    extraPackages = if enableNvidia then [] else with pkgs; [
      intel-media-driver     # VA-API (iHD) userspace
      vpl-gpu-rt             # oneVPL (QSV) runtime
      intel-compute-runtime  # OpenCL
    ];
  };

  environment.sessionVariables = {
    # If Nvidia is disabled, force Intel iHD. If Nvidia is enabled, let it auto-detect or set to nvidia.
    LIBVA_DRIVER_NAME = if enableNvidia then "nvidia" else "iHD";
  };

  hardware.enableRedistributableFirmware = true;

  # Select Video Drivers based on switch
  services.xserver.videoDrivers = if enableNvidia
    then [ "nvidia" ]
    else [ "modesetting" ];

  # === Nvidia Specific Config (Active only when enableNvidia = true) ===
  hardware.nvidia = lib.mkIf enableNvidia {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # === System Services ===
  services = {
    openssh.enable = true;
    acpid.enable = true; # battery status daemon
    mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
    };
    tailscale.enable = true;
  };

  # === User Configuration ===
  users.users.zeno = {
    isNormalUser = true;
    description = "zeno";
    extraGroups = ["networkmanager" "wheel" "video" "render"];
    packages = with pkgs; [];
  };
  users.defaultUserShell = pkgs.zsh;
  services.getty.autologinUser = "zeno";

  # === System Programs ===
  programs.zsh.enable = true; # Enable zsh system-wide

  # === System Packages ===
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # System utilities
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
