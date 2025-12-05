# Quick Usage Guide

## Current Status
✅ **CLI-only profile is currently active**
Your home-manager configuration is now managed from `~/nix/` with the CLI module active.

## Profile Switching

### CLI-Only Mode (Current)
```bash
~/nix/scripts/switch-cli-only.sh
```
**Manages:**
- All CLI tools (45+ packages)
- Development tools (docker, go, nodejs, rust, etc.)
- Command utilities (bat, eza, fzf, ripgrep, glow, etc.)
- Program configs (neovim, zsh, tmux with dotbar styling)
- Dotfiles (centralized in `~/nix/dotfiles/`)

### Full System Mode
```bash
~/nix/scripts/switch-full-system.sh
```
**Manages:**
- Everything from CLI-only mode
- System configuration
- GUI applications and desktop environment

## File Locations

### Active Configuration
- **Home-manager**: `~/.config/home-manager/home.nix` → `~/nix/profiles/cli-only.nix`
- **CLI Module**: `~/nix/modules/home-manager/cli.nix`
- **Dotfiles**: `~/nix/dotfiles/`

### Directory Structure
```
~/nix/
├── modules/home-manager/cli.nix    # Your complete CLI configuration
├── modules/system/configuration.nix # System configuration
├── profiles/cli-only.nix           # CLI-only profile (active)
├── profiles/full-system.nix        # Full system profile
├── dotfiles/                       # Your dotfiles (.zshrc, .vimrc, etc.)
├── scripts/                        # Profile switching scripts
└── docs/                          # Documentation
```

## Making Changes

### Add/Remove CLI Tools
Edit `~/nix/modules/home-manager/cli.nix` and run:
```bash
home-manager switch
```

### Modify Dotfiles
Edit files in `~/nix/dotfiles/` - changes are automatically applied.

### Version Control
```bash
cd ~/nix
git add .
git commit -m "your changes"
```

## Benefits Achieved
- ✅ **Single Repository**: All configs in `~/nix/` under git control
- ✅ **Modular System**: Choose CLI-only or full system management
- ✅ **Clean Organization**: Centralized dotfiles and configurations
- ✅ **Easy Switching**: Simple scripts to change between profiles
- ✅ **Maintainable**: Clear structure with your CLI setup as one cohesive module