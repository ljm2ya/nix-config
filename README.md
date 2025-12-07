# Unified Nix Configuration

Centralized NixOS and Home Manager configuration with **3-tier modular architecture**.

## Overview

This repository provides a complete, portable NixOS configuration with three tiers:
- **CLI Profile**: Development tools and terminal utilities
- **GUI Profile**: CLI + desktop applications (no system changes)
- **Full System**: Complete system configuration with hardware drivers and services

All dotfiles are version-controlled and managed declaratively through home-manager.

## Quick Start

### Fresh Installation

```bash
# Clone repository
cd ~ && git clone <your-repo-url> nix && cd nix

# Automated installation (recommended)
./scripts/bootstrap.sh --profile gui

# Follow prompts to complete setup
```

### Profile Switching (Existing System)

```bash
# CLI only (no GUI apps or system changes)
~/nix/scripts/switch-cli-only.sh

# GUI apps (no system rebuild required)
~/nix/scripts/switch-gui.sh

# Full system (requires sudo)
~/nix/scripts/switch-full-system.sh
```

## Architecture

### 3-Tier System

```
Tier 1: CLI Profile
  ├─ CLI tools (neovim, zsh, tmux, git, etc.)
  ├─ Development tools (docker, nodejs, rust, etc.)
  └─ No system changes, no sudo required

Tier 2: GUI Profile (imports CLI)
  ├─ All CLI tools
  ├─ Desktop applications (firefox, discord, etc.)
  ├─ GUI dotfiles (awesome, alacritty, rofi)
  └─ No system changes, no sudo required

Tier 3: Full System (imports GUI)
  ├─ All CLI + GUI tools
  ├─ System configuration (X11, drivers, services)
  ├─ Hardware optimization
  └─ Requires sudo for system rebuild
```

### Directory Structure

```
~/nix/
├── dotfiles/               # Centralized dotfiles (CLI + GUI)
│   ├── .zshrc             # Shell configuration
│   ├── .vimrc             # Vim configuration
│   ├── .gitconfig         # Git configuration
│   ├── .xinitrc           # X11 startup
│   ├── .Xmodmap           # Keyboard mappings
│   └── .config/
│       ├── awesome/       # Window manager
│       ├── alacritty/     # Terminal emulator
│       └── rofi/          # Application launcher
├── home-manager/
│   ├── cli.nix            # CLI packages and configs
│   ├── gui.nix            # GUI packages and dotfile symlinks
│   └── tmux.nix           # Tmux configuration
├── system/
│   ├── base.nix           # Hardware, drivers, kernel, services
│   ├── gui.nix            # System-level GUI (X11, fonts, input)
│   ├── configuration.nix  # Main system config (imports base + gui)
│   └── hardware-configuration.nix
├── profiles/
│   ├── cli-only.nix       # Tier 1: CLI only
│   ├── gui.nix            # Tier 2: CLI + GUI apps
│   └── full-system.nix    # Tier 3: Complete system
└── scripts/
    ├── bootstrap.sh       # Fresh installation script
    ├── switch-cli-only.sh
    ├── switch-gui.sh
    └── switch-full-system.sh
```

## What's Included

### CLI Profile (45+ packages)

**Core Programs**: neovim, zsh, tmux, git, direnv
**Development**: docker, go, nodejs, rust, cmake, gcc
**Utilities**: bat, eza, fzf, ripgrep, yazi, zoxide, age, jq, htop
**Services**: lorri (nix shell caching)

### GUI Profile (CLI + 15+ apps)

**Applications**: firefox, chrome, discord, telegram, emacs
**Media**: mpv, obs-studio, feh
**Productivity**: libreoffice, file-roller, remmina
**Desktop**: alacritty, rofi, pavucontrol

### Full System

**Desktop**: Awesome WM, X11, startx
**Graphics**: Intel/Nvidia drivers (configurable)
**Input**: fcitx5 (Japanese/Korean), keyd (keyboard remapping)
**Fonts**: IBM Plex, Noto CJK, Nerd Fonts
**Hardware**: Power management, bluetooth, audio (pipewire)
**Services**: networking, VPN, SSH, tailscale

## Fresh Installation Guide

### Prerequisites

- Fresh NixOS installation
- Git installed: `nix-shell -p git`
- Internet connection

### Installation Steps

#### 1. Clone Repository

```bash
cd ~
git clone <your-repo-url> nix
cd nix
```

#### 2. Customize System Settings (Full System Only)

If using full system profile, customize these settings in `system/base.nix`:

```bash
vim ~/nix/system/base.nix
```

**Important settings:**
- `machineType = "laptop";` - Options: "laptop", "desktop", "vm" (auto-detected during bootstrap)
- `enableNvidia = false;` - Set to `true` for Nvidia GPU
- `networking.hostName = "nixos";` - Change to your hostname
- `time.timeZone = "Asia/Seoul";` - Change to your timezone
- `users.users.zeno` - Change username if needed

**Machine Type Configuration:**

The system supports three machine types with optimized configurations:

- **Laptop**: Full power management, lid switch handling, battery optimizations, all hardware features
- **Desktop**: Basic power management, no lid handling, all hardware features
- **VM**: Minimal configuration, VMware guest tools, disabled hardware features (swap, Bluetooth, graphics acceleration)

The bootstrap script will auto-detect your machine type and configure UUIDs automatically.

#### 3. Generate Hardware Configuration (Full System Only)

```bash
sudo nixos-generate-config --show-hardware-config > ~/nix/system/hardware-configuration.nix
```

#### 4. Run Bootstrap Script

```bash
# For CLI profile
./scripts/bootstrap.sh --profile cli

# For GUI profile (recommended)
./scripts/bootstrap.sh --profile gui

# For full system
./scripts/bootstrap.sh --profile full
```

**What the Bootstrap Script Does:**

For all profiles:
- Installs home-manager if needed
- Links home-manager profile
- Applies home-manager configuration
- Verifies installation

For full system profile (additional steps):
- Auto-detects machine type (laptop/desktop/vm)
- Prompts for confirmation with detected default
- Auto-detects swap and resume device UUIDs
- Updates `system/base.nix` with detected values
- Generates hardware configuration if missing
- Links system configuration to `/etc/nixos/`
- Runs `nixos-rebuild switch`

#### 5. Verify Installation

```bash
# Check symlinks
ls -la ~/.zshrc          # → ~/nix/dotfiles/.zshrc
ls -la ~/.vimrc          # → ~/nix/dotfiles/.vimrc

# For GUI profile:
ls -la ~/.xinitrc        # → ~/nix/dotfiles/.xinitrc
ls -la ~/.config/awesome # → ~/nix/dotfiles/.config/awesome

# Test programs
zsh
nvim --version

# For GUI: test X11
startx
```

### Manual Installation

If you prefer manual setup:

```bash
# Create home-manager directory
mkdir -p ~/.config/home-manager

# Link your chosen profile
ln -sf ~/nix/profiles/gui.nix ~/.config/home-manager/home.nix

# Apply configuration
home-manager switch

# For full system, also:
sudo ln -sf ~/nix/system/configuration.nix /etc/nixos/configuration.nix
sudo nixos-rebuild switch
```

## Making Changes

### Edit Configuration Files

```bash
# Add/remove CLI tools
vim ~/nix/home-manager/cli.nix
home-manager switch

# Add/remove GUI applications
vim ~/nix/home-manager/gui.nix
home-manager switch

# Modify system configuration
vim ~/nix/system/base.nix
sudo nixos-rebuild switch
```

### Edit Dotfiles

```bash
# CLI dotfiles
vim ~/nix/dotfiles/.zshrc
vim ~/nix/dotfiles/.vimrc
vim ~/nix/dotfiles/.gitconfig

# GUI dotfiles
vim ~/nix/dotfiles/.xinitrc
vim ~/nix/dotfiles/.config/awesome/rc.lua
vim ~/nix/dotfiles/.config/alacritty/alacritty.toml
vim ~/nix/dotfiles/.config/rofi/config.rasi

# Changes apply immediately (symlinked)
```

### Version Control

```bash
cd ~/nix
git add .
git commit -m "Update configuration"
git push
```

## How It Works (Bidirectional Sync)

### Your System → Repository

```
Edit ~/nix/dotfiles/.zshrc
         ↓
Changes apply immediately (symlinked file)
         ↓
git add . && git commit -m "Update zsh config"
         ↓
git push (backup to remote)
```

### Repository → New System

```
git clone <repo> ~/nix
         ↓
./scripts/bootstrap.sh --profile gui
         ↓
home-manager creates symlinks:
  ~/.zshrc → ~/nix/dotfiles/.zshrc
  ~/.config/awesome → ~/nix/dotfiles/.config/awesome
         ↓
Your exact setup deployed!
```

**Key concept:** Dotfiles live in the repository. Home-manager creates symlinks from your home directory to the repo. Clone on any system and run bootstrap to get your exact configuration.

## Customization

### User-Specific Settings

```bash
# Git identity
vim ~/nix/dotfiles/.gitconfig

# Shell aliases and settings
vim ~/nix/dotfiles/.zshrc

# Window manager keybindings
vim ~/nix/dotfiles/.config/awesome/rc.lua
```

### Hardware-Specific Settings

```bash
# Display configuration
vim ~/nix/dotfiles/.xinitrc

# Machine type and hardware configuration
vim ~/nix/system/base.nix
```

**Machine Type Settings** (in `system/base.nix`):

```nix
# Machine type determines which features are enabled
machineType = "laptop";  # Options: "laptop", "desktop", "vm"

# GPU configuration
enableNvidia = false;  # Set to true for Nvidia GPU

# Hardware UUIDs (auto-detected during bootstrap)
swapUUID = "your-swap-uuid";
resumeUUID = "your-resume-uuid";
```

**What Each Type Enables:**

- **Laptop**: Power management, lid switch (suspend-then-hibernate), battery handling, all hardware features
- **Desktop**: Power management, power button handling (no lid switch), all hardware features
- **VM**: VMware guest tools only, disables: swap, hardware graphics, Bluetooth, firmware, power management

To change machine type after installation, edit `machineType` in `system/base.nix` and run `sudo nixos-rebuild switch`.

### Multi-Machine Setup

**Option 1: Branches**
```bash
git checkout -b laptop-work
# Customize for this machine
git commit -m "Laptop-specific config"
```

**Option 2: Hostname-based conditionals**
```nix
# Example in base.nix
networking.hostName =
  if builtins.pathExists /etc/hostname
  then lib.removeSuffix "\n" (builtins.readFile /etc/hostname)
  else "nixos";
```

## Troubleshooting

### Symlinks not created

```bash
# Verify profile is linked
ls -la ~/.config/home-manager/home.nix

# Re-run with verbose output
home-manager switch --show-trace
```

### Permission errors

```bash
# Fix ownership
sudo chown -R $USER:users ~/nix

# Make scripts executable
chmod +x ~/nix/scripts/*.sh
```

### System build fails

```bash
# Check syntax
nix-instantiate --parse ~/nix/system/configuration.nix

# Build with trace
sudo nixos-rebuild switch --show-trace
```

### Existing dotfiles conflict

```bash
# home-manager creates .backup files automatically
ls -la ~/.zshrc.backup

# Review and merge if needed
diff ~/.zshrc.backup ~/nix/dotfiles/.zshrc
```

## Design Philosophy

- **Pure declarative Nix** - No scripting hacks or manual configuration
- **Modular composition** - Each tier cleanly builds on the previous
- **Dotfiles in repository** - All configs version-controlled and portable
- **Symlink-based** - Changes propagate immediately, no rebuild needed for dotfiles
- **Zero sudo for user tools** - Only system-level changes require sudo

## Resources

- **NixOS Manual**: https://nixos.org/manual/nixos/stable/
- **Home Manager Manual**: https://nix-community.github.io/home-manager/
- **Awesome WM Docs**: https://awesomewm.org/doc/
