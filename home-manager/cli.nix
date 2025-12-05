{ config, lib, pkgs, ... }:

{
  imports = [
    ./tmux.nix
  ];

  home = {
    username = "zeno";
    homeDirectory = "/home/zeno";
    stateVersion = "23.11";

    # CLI packages migrated from system configuration
    packages = with pkgs; [
      # Development tools
      autoconf
      automake
      cmake
      direnv
      docker
      fakeroot
      gcc
      gnumake
      go
      libtool
      nodejs_24
      openssl
      pkg-config
      rustc
      rustup
      uv

      # Command line utilities
      age
      bashSnippets
      bat
      bluetui
      claude-code
      croc
      eza # ls replacement
      fd
      file
      fzf
      git
      glow # CLI markdown viewer
      htop
      jq
      nix-search-cli
      poppler
      ttyd
      tree
      rclone
      ripgrep
      rlwrap
      rsync
      scrot
      ueberzugpp
      wget
      (yazi.override {
        _7zz = _7zz-rar;  # Support for RAR extraction
      })
      zoxide

      # Essential user utilities
      vim-full
      xclip
      yadm
    ];

    # Dotfiles management with stow-like approach
    file = {
      # Create symlinks to actual dotfiles (excluding those managed by programs)
      ".vimrc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/dotfiles/.vimrc";
    };
  };

  # Program-specific configurations
  programs = {
    # Enable home-manager
    home-manager.enable = true;

    # Neovim configuration - migrated from system
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      # Additional user-specific neovim config can go here
    };

    # Git configuration - using dotfiles
    git = {
      enable = true;
      includes = [
        { path = "${config.home.homeDirectory}/nix/dotfiles/.gitconfig"; }
      ];
    };

    # Zsh configuration - migrated from system, using dotfiles
    zsh = {
      enable = true;
      initContent = ''
        # Source custom zsh config if it exists
        [ -f ~/nix/dotfiles/.zshrc ] && source ~/nix/dotfiles/.zshrc
      '';
    };

    # Tmux configuration is handled in tmux.nix import

    # direnv integration
    direnv = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  # Services that can be user-level
  services = {
    # lorri - nix development shell caching (user-level service)
    lorri.enable = true;
  };
}
