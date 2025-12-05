# Unified Nix Configuration

Centralized NixOS and Home Manager configuration with modular profile selection.

## Quick Start

**Switch to CLI-only mode:**
```bash
~/nix/scripts/switch-cli-only.sh
```

**Switch to full system mode:**
```bash
~/nix/scripts/switch-full-system.sh
```

## Structure

```
~/nix/
├── home-manager/cli.nix    # Complete CLI configuration
├── system/configuration.nix # System configuration
├── profiles/{cli-only,full-system}.nix # Profile selectors
├── dotfiles/                       # Centralized dotfiles
├── scripts/                        # Profile switching helpers
```

## What's Included

### CLI Configuration (45+ packages)
- **Core programs**: neovim, zsh, tmux (with dotbar prefix highlighting), git, direnv
- **Development**: docker, go, nodejs, rust, cmake, gcc, autoconf, automake
- **Utilities**: bat, eza, fzf, ripgrep, glow, yazi, zoxide, age, jq, htop
- **Services**: lorri (nix development shell caching)
- **Dotfiles**: Centralized in `~/nix/dotfiles/` (.zshrc, .vimrc, .gitconfig, tmux.conf)

### Tmux Features
- ✅ **vim-tmux-navigator**: Seamless pane navigation with Ctrl+hjkl
- ✅ **Dotbar styling**: Custom status bar with prefix highlighting
- ✅ **Vi-mode copy**: Enhanced copy-mode with xclip integration
- ✅ **Yazi support**: Image preview passthrough

### System Configuration (Full Mode)
- **GUI applications**: browsers, discord, file managers
- **Desktop**: awesome WM, X11, graphics drivers
- **Services**: networking, bluetooth, audio, VPN, power management

## Making Changes

### Add/Remove CLI Tools
```bash
vim ~/nix/home-manager/cli.nix
home-manager switch
```

### Edit Dotfiles
```bash
vim ~/nix/dotfiles/.zshrc  # Changes apply automatically
```

### Version Control
```bash
cd ~/nix
git add . && git commit -m "your changes"
```

## Migration Summary

Successfully migrated from separate configurations to unified system:
- ✅ **~80% reduction** in system-managed CLI programs
- ✅ **Complete separation** of user tools from system configuration
- ✅ **Zero sudo required** for CLI tool management
- ✅ **Single git repository** for all configurations
- ✅ **Modular design** with easy profile switching

**Before**: Scattered configs in `/etc/nixos/`, `~/.config/home-manager/`, `~/dotfiles/`
**After**: Unified in `~/nix/` with profile-based management

All CLI development tools now managed at user-level with proper separation between user tools and system services.
