# Unified Nix Configuration

Centralized NixOS and Home Manager configuration with CLI-only and full system profile selection.

## Structure

```
~/nix/
├── modules/
│   ├── home-manager/
│   │   ├── cli.nix              # Complete CLI configuration (current home-manager)
│   │   └── tmux.nix            # Tmux configuration module
│   └── system/
│       └── configuration.nix   # System configuration
├── profiles/
│   ├── cli-only.nix            # CLI-only profile
│   └── full-system.nix         # Full system profile
├── dotfiles/                   # Centralized dotfiles (.zshrc, .vimrc, etc.)
├── scripts/                    # Helper switching scripts
└── docs/                      # Documentation and migration info
```

## Usage

### Quick Profile Switching

**CLI-Only Mode:**
```bash
~/nix/scripts/switch-cli-only.sh
```

**Full System Mode:**
```bash
~/nix/scripts/switch-full-system.sh
```

### Manual Profile Switching

**CLI-Only Mode** - manages only command-line tools:
```bash
ln -sf ~/nix/profiles/cli-only.nix ~/.config/home-manager/home.nix
home-manager switch
```

**Full System Mode** - manages CLI + system + GUI:
```bash
ln -sf ~/nix/profiles/full-system.nix ~/.config/home-manager/home.nix
sudo ln -sf ~/nix/modules/system/configuration.nix /etc/nixos/configuration.nix
sudo nixos-rebuild switch && home-manager switch
```

## What's Included

### CLI Configuration
- **Development tools**: autoconf, cmake, docker, go, nodejs, rust, etc.
- **CLI utilities**: bat, eza, fzf, ripgrep, yazi, zoxide, glow, etc.
- **Programs**: neovim, zsh, tmux (with dotbar styling), git, direnv
- **Services**: lorri (nix development shells)
- **Dotfiles**: Centralized in `~/nix/dotfiles/`

### System Configuration (Full Mode)
- **GUI applications**: browsers, discord, file managers, etc.
- **Desktop environment**: awesome WM, X11 configuration
- **System services**: networking, bluetooth, audio, VPN
- **Hardware support**: graphics, power management

## Features

- **Single CLI Module**: Your complete CLI setup as one cohesive module
- **Profile Selection**: Easy switching between usage modes
- **Centralized Management**: All configs in one git repository
- **Modular Design**: Add/modify components easily
- **Version Controlled**: Track all configuration changes