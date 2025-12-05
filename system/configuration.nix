# NixOS Configuration 
#Help: configuration.nix(5) man page or 'nixos-help' 

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
    ./hardware-configuration.nix 
  ];

  #=== Boot Configuration === 
  boot = { 
    loader = { 
     systemd-boot.enable = true; 
     systemd-boot.sortKey = "z-nixos"; 
     efi.canTouchEfiVariables = false; 
    };

    # Kernel Parameters: Conditional based on GPU
    # Use kernel parameters for both the resume device and the offset
    kernelParams = [
      "resume=${config.boot.resumeDevice}"
      # "resume_offset=${toString config.swapDevices.0.offset}"
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

  # May help if FFmpeg/VAAPI/QSV init fails (esp. on Arc with i915):
  hardware.enableRedistributableFirmware = true;

  # May help services that have trouble accessing /dev/dri (e.g., jellyfin/plex):
  # users.users.<service>.extraGroups = [ "video" "render" ];
  # Select Video Drivers based on switch
  services.xserver.videoDrivers = if enableNvidia 
    then [ "nvidia" ]
    else [ "modesetting" ];

  # === Nvidia Specific Config (Active only when enableNvidia = true) ===
  hardware.nvidia = lib.mkIf enableNvidia {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    open = false; # Proprietary drivers are usually more stable for gaming/productivity
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # Ensure these IDs match your `lspci` output!
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # === X11 & Desktop ===
  services.xserver = {
    enable = true;
    windowManager.awesome.enable = true;
    displayManager.startx.enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };
  # swap ctrl and capslock only for internal laptop keyboard
  services.keyd = {
    enable = true;
    keyboards = {
      internal = {
        # Use the exact name found in /proc/bus/input/devices
        ids = [ "0001:0001" ];
        settings = {
          main = {
            capslock = "layer(control)";
            leftcontrol = "capslock";
          };
        };
      };
    };
  };
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
    };
  };

  # === System Wide Programs ===
  # Note: neovim, tmux migrated to home-manager per-user configuration
  programs.zsh.enable = true; # Enable zsh system-wide, configuration via home-manager
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
    ];
  };
  programs.xfconf.enable = true;
  programs.light.enable = true;
  programs.thunderbird.enable = true;

  # === Environment Variables ===
  environment.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };

  # === Fonts ===
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      ibm-plex
      noto-fonts-cjk-sans
      nerd-fonts.blex-mono
      nerd-fonts.d2coding
    ];
  };

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

  # === User Configuration ===
  users.users.zeno = {
    isNormalUser = true;
    description = "zeno";
    extraGroups = ["networkmanager" "wheel" "video" "render" ];
    packages = with pkgs; [];
  };
  users.defaultUserShell = pkgs.zsh; # Keep zsh available, but configuration managed by home-manager

  services.getty.autologinUser = "zeno";

  # === Packages ===
  nixpkgs.config.allowUnfree = true;
  
  environment.systemPackages = with pkgs; [
    # System utilities (keep at system level)
    home-manager
    ffmpeg
    pamixer
    p7zip
    usbutils
    brightnessctl

    # Desktop applications
    alacritty
    awesome
    discord
    emacs
    google-chrome
    feh
    file-roller
    firefox
    gtk2
    kdePackages.filelight
    libnotify
    libreoffice-qt
    mpv
    networkmanagerapplet
    obs-studio
    pavucontrol
    pinentry-all
    remmina
    rofi
    sound-theme-freedesktop
    xfce.mousepad
    xfce.xfce4-icon-theme
    telegram-desktop
    inputs.antigravity-nix.packages.${pkgs.system}.default

    # X11 utilities
    autorandr
    dex
    xorg.xcalc
    xorg.xev
    xorg.xmodmap
    xorg.xrdb
    
    # Auto-apply xmodmap on keyboard connect
    # Usage: Add to awesome rc.lua: awful.spawn.with_shell("xmodmap-watcher &")
    (writeShellScriptBin "xmodmap-watcher" ''
      # Monitor /dev/input for new keyboard devices
      # Wait for X
      while ! ${pkgs.xorg.xset}/bin/xset q >/dev/null 2>&1; do
        sleep 1
      done
      if [ -f "$HOME/.Xmodmap" ]; then
        ${pkgs.xorg.xmodmap}/bin/xmodmap "$HOME/.Xmodmap" 2>/dev/null || true
      fi
      (sleep 5 && [ -f "$HOME/.Xmodmap" ] && ${pkgs.xorg.xmodmap}/bin/xmodmap "$HOME/.Xmodmap" 2>/dev/null) &
      ${pkgs.inotify-tools}/bin/inotifywait -m -e create /dev/input --format '%w%f' | while read newfile; do
        # Check if it's an event device
        if echo "$newfile" | ${pkgs.gnugrep}/bin/grep -q "event"; then
          sleep 2  # Wait for device initialization
          # Apply xmodmap if file exists
          if [ -f "$HOME/.Xmodmap" ]; then
            ${pkgs.xorg.xmodmap}/bin/xmodmap "$HOME/.Xmodmap" 2>/dev/null || true
          fi
        fi
      done
    '')
    # Simple autorandr watcher  
    (writeShellScriptBin "autorandr-watcher" ''
      # Initial setup
      ${pkgs.autorandr}/bin/autorandr --change --match-edid
      
      # Monitor for changes
      ${pkgs.systemd}/bin/udevadm monitor --subsystem-match=drm | while read -r line; do
        if [[ "$line" == *"change"* ]] && [[ "$line" == *"HOTPLUG=1"* ]]; then
          sleep 2
          ${pkgs.autorandr}/bin/autorandr --change --match-edid
        fi
      done
    '')
  ];


  # === System Version ===
 # Don't change this after first install
  system.stateVersion = "25.05";
}
