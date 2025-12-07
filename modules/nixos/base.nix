{ config, pkgs, lib, ... }:

let
  # =================================================================
  #  MACHINE TYPE CONFIGURATION
  #  Set your machine type: "laptop", "desktop", or "vm"
  #  This can be overridden during bootstrap
  # =================================================================
  machineType = "laptop";  # Options: "laptop", "desktop", "vm"

  # Bootloader configuration (will be auto-detected during bootstrap)
  bootloader = "systemd-boot"; # Options: "systemd-boot", "grub"
  grubDevice = "/dev/sda";     # Dummy, will be replaced by bootstrap script

  # GPU configuration
  enableNvidia = false;  # Set to true for Nvidia GPU

  # Helper functions
  isLaptop = machineType == "laptop";
  isDesktop = machineType == "desktop";
  isVM = machineType == "vm";

  # Hardware UUIDs (auto-detected during bootstrap, or set manually)
  # For VM: these will be empty/disabled
  swapUUID = "5a4cf021-8203-453b-877f-164c5c6e1128";  # Replace with your swap UUID
  resumeUUID = "5a4cf021-8203-453b-877f-164c5c6e1128";  # Replace with your resume device UUID
in
{
  # Base system configuration - hardware, drivers, kernel, system services
  # This module contains ONLY system-level configurations
  # GUI configurations are in system/gui.nix

  imports = [
  ];

  # === Boot Configuration ===
  boot = {
    loader =
      if bootloader == "grub" then {
        grub.enable = true;
        grub.device = grubDevice;
      } else { # systemd-boot is default
        systemd-boot.enable = true;
        systemd-boot.sortKey = "z-nixos";
        efi.canTouchEfiVariables = false;
      };

    # Kernel Parameters: Conditional based on machine type and GPU
    kernelParams = lib.optionals (!isVM) (
      [ "resume=/dev/disk/by-uuid/${resumeUUID}" ] ++
      (if enableNvidia then [
        "nvidia-drm.modeset=1"  # Essential for NVIDIA hibernation/wayland
      ] else [
        "i915.enable_guc=3"     # Intel GuC for iGPU
      ])
    );

    # Kernel modules: Only for physical hardware
    kernelModules = lib.optionals (!isVM) [ "iwlwifi" ];

    # Resume device: Only for physical hardware with swap
    resumeDevice = lib.mkIf (!isVM) "/dev/disk/by-uuid/${resumeUUID}";
  };

  # === Nix Configuration ===
  nix = {
    # Enable flakes and new nix command
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };

    # Garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # === Power Management ===
  # Enabled for laptop and desktop, disabled for VM
  powerManagement.enable = !isVM;

  # Logind configuration: Conditional based on machine type
  services.logind.settings.Login =
    if isLaptop then {
      HandleLidSwitch= "suspend-then-hibernate";
      HandleLidSwitchExternalPower= "suspend";
      HandlePowerKey= "hibernate";
      HandlePowerKeyLongPress= "poweroff";
      #PowerKeyIgnoreInhibited= yes
    }
    else if isDesktop then {
      HandlePowerKey= "hibernate";
      HandlePowerKeyLongPress= "poweroff";
      #PowerKeyIgnoreInhibited=yes
    }
    else {};  # VM: no special power handling

  # Swap devices: Only for physical hardware
  swapDevices = lib.optionals (!isVM) [{
    device = "/dev/disk/by-uuid/${swapUUID}";
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
  security.rtkit.enable = true;

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
        Experimental = true;
      };
    };
  };
  services.blueman.enable = true;

  # === Graphics Configuration ===
  # Only for physical hardware, disabled for VM
  hardware.graphics = lib.mkIf (!isVM) {
    enable = true;
    extraPackages = if enableNvidia then [] else with pkgs; [
      intel-media-driver     # VA-API (iHD) userspace
      vpl-gpu-rt             # oneVPL (QSV) runtime
      intel-compute-runtime  # OpenCL
    ];
  };

  # Session variables: Only for physical hardware
  environment.sessionVariables = lib.mkIf (!isVM) {
    LIBVA_DRIVER_NAME = if enableNvidia then "nvidia" else "iHD";
  };

  # Firmware: Only for physical hardware
  hardware.enableRedistributableFirmware = !isVM;

  # Video drivers: Conditional based on machine type
  services.xserver.videoDrivers =
    if isVM then [ "vmware" "modesetting" ]
    else if enableNvidia then [ "nvidia" ]
    else [ "modesetting" ];

  # === Nvidia Specific Config ===
  hardware.nvidia = lib.mkIf (enableNvidia && !isVM) {
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

  # === VM Specific Configuration ===
  virtualisation.vmware.guest.enable = isVM;

  # === System Services ===
  services = {
    openssh.enable = true;
    acpid.enable = !isVM;  # Battery status daemon - only for physical hardware
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
  programs.zsh.enable = true;

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
