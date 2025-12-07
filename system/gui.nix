{ config, lib, pkgs, inputs, ... }:

{
  # System-level GUI configuration
  # This module contains X11, window managers, display managers, fonts,
  # input methods, and system-level GUI services

  # === X11 & Desktop Environment ===
  services.xserver = {
    enable = true;
    windowManager.awesome.enable = true;
    displayManager.startx.enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # === Keyboard Remapping (system-level) ===
  # Swap Ctrl and Capslock for internal laptop keyboard
  services.keyd = {
    enable = true;
    keyboards = {
      internal = {
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

  # === Touchpad Configuration ===
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
    };
  };

  # === Input Method (fcitx5) ===
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      kdePackages.fcitx5-qt
      fcitx5-hangul
    ];
  };

  # === Environment Variables for Input Method ===
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

  # === Desktop Services ===
  services = {
    gvfs.enable = true;      # Mount, trash, and other functionalities
    tumbler.enable = true;   # Thumbnail support for images
  };

  # === System-Wide GUI Programs ===
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

  # === GUI-Related System Packages ===
  environment.systemPackages = with pkgs; [
    # Window Manager
    awesome

    # System GUI utilities
    libnotify
    networkmanagerapplet
    sound-theme-freedesktop
    xfce.xfce4-icon-theme

    # X11 System utilities
    autorandr
    dex
    gtk2
    xorg.xev
    xorg.xmodmap
    xorg.xrdb

    # Auto-apply xmodmap on keyboard connect
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
        if echo "$newfile" | ${pkgs.gnugrep}/bin/grep -q "event"; then
          sleep 2
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

    # Antigravity input (assuming this is GUI-related)
    inputs.antigravity-nix.packages.${pkgs.system}.default
  ];
}
