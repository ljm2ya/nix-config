{ config, lib, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  # Desktop applications and user-level desktop environment configurations
  # This module extends the CLI configuration with desktop applications
  # Intended to be imported alongside cli.nix for desktop environments

  home.packages = with pkgs; [
    # GUI Applications
    alacritty           # Terminal emulator
    google-antigravity  # Agentic IDE (provided by flake overlay)
    discord             # Communication
    emacs               # Editor
    feh                 # Image viewer
    file-roller         # Archive manager
    firefox             # Browser
    google-chrome       # Browser
    kdePackages.filelight # Disk usage analyzer
    libreoffice-qt      # Office suite
    mpv                 # Media player
    obs-studio          # Streaming/recording
    pavucontrol         # Audio control
    pinentry-all        # GPG PIN entry
    remmina             # Remote desktop
    rofi                # Application launcher
    telegram-desktop    # Messaging
    xfce.mousepad       # Simple text editor

    # X11 Utilities (user-level)
    xorg.xcalc          # Calculator
    xclip               # Clipboard (already in CLI, but emphasized here)
    scrot               # Screenshot tool (already in CLI)
  ];

  # GUI dotfiles management
  home.file = {
    # X11 configuration files
    ".xinitrc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/.xinitrc";
    ".Xmodmap".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/.Xmodmap";

    # Awesome WM configuration
    ".config/awesome".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/.config/awesome";

    # Alacritty configuration
    ".config/alacritty".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/.config/alacritty";

    # Rofi configuration
    ".config/rofi".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/.config/rofi";

    # Doom Emacs configuration
    ".doom.d".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/.doom.d";
  };

  # GUI-specific program configurations
  programs = {
    # Alacritty can use home-manager module or dotfiles (we're using dotfiles)
    # Firefox, GTK, etc. can be configured here if needed
  };

  # GUI-specific services
  services = {
    # Add user-level GUI services here if needed
  };

  # XDG user directories
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
