# Nix Configuration

Modern, declarative NixOS and Home Manager configuration with multiple profiles, automatic input inheritance, and registry support.

## Features

- ✅ **Multiple Flake Outputs** - No symlinks, clean profile switching
- ✅ **Automatic Input Inheritance** - DRY, maintainable configuration
- ✅ **Built-in Registry** - Short, convenient commands
- ✅ **Just-based Management** - Clean, declarative command runner
- ✅ **Idempotent Bootstrap** - Safe, resumable setup
- ✅ **State Tracking** - Know what's configured
- ✅ **Version-controlled Dotfiles** - Including Doom Emacs
- ✅ **Encrypted SSH Backup** - Safe key storage in git

## Quick Start

### Fresh Installation

```bash
# Clone repository
git clone <your-repo-url> ~/nix
cd ~/nix

# Bootstrap (auto-detects machine type)
just init desktop

# Or specify machine type
just init desktop laptop
```

### Existing System

```bash
# Check status
just status

# Switch profiles
just switch-cli         # CLI-only
just switch-desktop     # CLI + Desktop apps
just switch-full        # Full system (NixOS + home-manager)

# List all commands
just
```

## Profiles

| Profile | Description | Sudo Required |
|---------|-------------|---------------|
| **cli-only** | CLI tools and development utilities | No |
| **desktop** | CLI + Desktop applications | No |
| **full** | Complete system (NixOS + home-manager) | Yes |

## Installation

### Prerequisites

- NixOS installed
- Git available
- Internet connection

### Bootstrap Steps

```bash
# 0. Load dependancies
nix-shell -p just git
# 1. Clone repository
cd ~ && git clone <your-repo-url> nix && cd nix

# 2. Bootstrap with desired profile
just init desktop           # Auto-detect machine type
just init desktop laptop    # Specify laptop
just init full auto         # Full system, auto-detect

# 3. Verify installation
just status
```

**Machine Types:**
- `laptop` - Power management, lid handling, battery optimization
- `desktop` - Basic power management, no lid handling
- `vm` - Minimal config, VMware tools
- `auto` - Auto-detect (default)

## Usage

### Profile Management

```bash
# Switch to different profile
just switch-cli
just switch-desktop
just switch-full

# Or use home-manager directly
home-manager switch --flake ~/nix#zeno-desktop --impure
home-manager switch --flake flake:home#zeno-desktop --impure
```

### System Information

```bash
just status              # Current configuration
just sysinfo             # System details
just generations         # Recent generations
just show                # Flake outputs
just registry            # Registry configuration
```

### Updates & Maintenance

```bash
just update-check        # Update flake and verify
just check               # Check flake for errors
just clean               # Clean old generations (>5 days)
just gc                  # Garbage collection
just deep-clean          # Clean + GC
just optimize            # Optimize Nix store
```

### Development

```bash
just format              # Format Nix files
just lint                # Lint configuration
just dev                 # Enter development shell
just build <output>      # Build specific output
```

### Git Workflow

```bash
just git-status          # Show git status
just git-add             # Add all changes
just git-commit "msg"    # Commit with message
just git-save            # Quick commit with timestamp
```

### Secrets Management

Securely backup SSH keys to this repository with age encryption:

```bash
# Backup SSH keys (encrypt with passphrase)
just ssh-backup

# List encrypted keys
just ssh-list

# Restore SSH keys (decrypt with passphrase)
just ssh-restore
```

**How it works:**
- Keys are encrypted with [age](https://github.com/FiloSottile/age) using a passphrase
- Encrypted `.age` files are **safe to commit to GitHub**
- During `just init`, you'll be prompted to restore keys automatically
- Unencrypted keys are protected by `.gitignore`

See [secrets/README.md](secrets/README.md) for detailed documentation.

## Directory Structure

```
~/nix/
├── flake.nix                    # Main flake with multiple outputs
├── Justfile                     # Command runner
│
├── profiles/                    # Profile definitions
│   ├── cli-only.nix            # CLI-only profile
│   ├── desktop.nix             # Desktop profile (CLI + GUI)
│   └── full-system.nix         # Full system profile
│
├── modules/
│   ├── home/                   # Home-manager modules
│   │   ├── cli.nix            # CLI packages and config
│   │   ├── desktop.nix        # Desktop applications
│   │   └── tmux.nix           # Tmux configuration
│   │
│   └── nixos/                  # NixOS modules
│       ├── base.nix           # Base system config
│       ├── desktop.nix        # Desktop environment
│       ├── configuration.nix  # Main system config
│       └── hardware-configuration.nix
│
├── dotfiles/                   # Managed dotfiles
│   ├── .doom.d/               # Doom Emacs configuration
│   ├── .vimrc
│   ├── .zshrc
│   ├── .gitconfig
│   ├── .xinitrc
│   ├── .Xmodmap
│   └── .config/
│       ├── awesome/           # Window manager
│       ├── alacritty/         # Terminal emulator
│       └── rofi/              # Application launcher
│
└── scripts/
    ├── nix-config             # Legacy unified script (use just instead)
    └── backup/                # Old scripts backup
```

## What's Included

### CLI Profile (50+ packages)

**Core**: neovim, zsh, tmux, git, direnv, just
**Development**: docker, go, nodejs, rust, cmake, gcc
**Utilities**: bat, eza, fzf, ripgrep, yazi, zoxide, jq, htop, claude-code

### Desktop Profile (CLI + 20+ apps)

**Browsers**: firefox, chrome
**Communication**: discord, telegram
**Media**: mpv, obs-studio, feh
**Productivity**: emacs, libreoffice, file-roller
**Desktop**: alacritty, rofi, pavucontrol

### Full System

**Desktop**: Awesome WM, X11, startx
**Graphics**: Intel/Nvidia drivers (configurable)
**Input**: fcitx5, keyd
**Fonts**: IBM Plex, Noto CJK, Nerd Fonts
**Hardware**: Power management, bluetooth, audio (pipewire)
**Services**: networking, VPN, SSH, tailscale

## Making Changes

### Add/Remove Packages

```bash
# Edit module files
vim ~/nix/modules/home/cli.nix        # CLI packages
vim ~/nix/modules/home/desktop.nix    # Desktop apps

# Apply changes
just switch-desktop

# Or use home-manager directly
home-manager switch --flake ~/nix#zeno-desktop --impure
```

### Edit Dotfiles

```bash
# Dotfiles are symlinked - edit in repository
vim ~/nix/dotfiles/.zshrc
vim ~/nix/dotfiles/.doom.d/config.el
vim ~/nix/dotfiles/.config/awesome/rc.lua

# Changes apply immediately (no rebuild needed)
```

### System Configuration

```bash
# Edit system settings
vim ~/nix/modules/nixos/base.nix

# Apply changes
just switch-full

# Or use nixos-rebuild directly
sudo nixos-rebuild switch --flake ~/nix#nixos
```

### Version Control

```bash
# Save changes
just git-add
just git-commit "Update configuration"
git push

# Or use git directly
git add .
git commit -m "Update configuration"
git push
```

## Configuration

### Machine Type

Edit `modules/nixos/base.nix`:

```nix
machineType = "laptop";  # Options: laptop, desktop, vm
enableNvidia = false;    # Set to true for Nvidia GPU
```

### User Settings

Edit dotfiles directly:
- Git identity: `dotfiles/.gitconfig`
- Shell aliases: `dotfiles/.zshrc`
- Editor config: `dotfiles/.doom.d/config.el`
- WM keybindings: `dotfiles/.config/awesome/rc.lua`

### Hardware Settings

Edit `modules/nixos/base.nix`:
- Display: `dotfiles/.xinitrc`
- Swap UUIDs: Auto-detected during bootstrap
- Power management: Based on machine type

## Advanced Usage

### Adding New Profile

```nix
# 1. Create profile file
# profiles/server.nix
{ config, lib, pkgs, ... }:
{
  imports = [ ../modules/home/cli.nix ];
  # Server-specific config
}

# 2. Add to flake.nix (one line!)
zeno-server = mkHomeConfig ./profiles/server.nix;

# 3. Use it
home-manager switch --flake ~/nix#zeno-server --impure
```

### Custom Just Commands

```justfile
# Add to Justfile
my-workflow:
    just update-check
    just switch-desktop
    just clean

# Use it
just my-workflow
```

### Multi-Machine Setup

**Option 1: Branches**
```bash
git checkout -b laptop-work
# Customize for this machine
git commit && git push
```

**Option 2: Host-based conditionals**
```nix
networking.hostName =
  if hostname == "laptop" then "my-laptop"
  else "my-desktop";
```

## State Management

State file: `~/.nix-config-state`

```bash
# View current state
cat ~/.nix-config-state | jq .

# Example output:
{
  "bootstrapped": "true",
  "current_profile": "desktop",
  "machine_type": "laptop",
  "last_update": "2025-12-08T01:08:12+09:00",
  "nix_dir": "/home/zeno/nix"
}
```

## Troubleshooting

### Command Not Found

```bash
# Reload shell
source ~/.zshrc

# Or restart shell
exec zsh
```

### Flake Check Fails

```bash
just check               # See errors
nix flake update         # Update inputs
just check               # Retry
```

### Unfree Package Issues

The `--impure` flag is required for unfree packages (like claude-code):

```bash
home-manager switch --flake ~/nix#zeno-desktop --impure
```

Or set environment variable:
```bash
export NIXPKGS_ALLOW_UNFREE=1
```

### Rollback Changes

```bash
# List generations
just generations
home-manager generations

# Rollback to previous
home-manager switch --switch-generation <id>
```

### Existing Files Conflict

```bash
# Backup conflicting files
home-manager switch --flake ~/nix#zeno-desktop --impure -b backup

# Check backups
ls -la ~/.*.backup
```

## Design Philosophy

- **Declarative** - Everything in Nix, no manual setup
- **Modular** - Clean composition with automatic inheritance
- **DRY** - Single helper function, zero duplication
- **Transparent** - No hidden state, explicit configurations
- **Version-controlled** - All dotfiles tracked in git
- **Portable** - Clone and bootstrap on any NixOS system

## How It Works

### Profile Switching

```
just switch-desktop
      ↓
home-manager switch --flake flake:home#zeno-desktop --impure
      ↓
flake.nix: mkHomeConfig ./profiles/desktop.nix
      ↓
Automatic: inputs inheritance + registry + overlays
      ↓
Profile: imports modules/home/cli.nix + modules/home/desktop.nix
      ↓
Configuration applied ✅
```

### Dotfile Management

```
Edit ~/nix/dotfiles/.zshrc
      ↓
Changes apply immediately (symlinked)
      ↓
git commit && git push
      ↓
Clone on new system → just init desktop
      ↓
Exact configuration restored ✅
```

## Resources

- **NixOS Manual**: https://nixos.org/manual/nixos/stable/
- **Home Manager**: https://nix-community.github.io/home-manager/
- **Just Manual**: https://github.com/casey/just
- **Nix Flakes**: https://nixos.wiki/wiki/Flakes
- **Awesome WM**: https://awesomewm.org/doc/

## Tips & Tricks

### Shell Aliases

Add to your shell config for even shorter commands:

```bash
alias j='just'
alias jst='just status'
alias jsd='just switch-desktop'
alias jsc='just switch-cli'
```

### Quick Commands

```bash
# One-liner update
just update-check && just switch-desktop && just clean

# Dry-run (test without applying)
home-manager switch --flake ~/nix#zeno-desktop --impure --dry-run

# Build specific output
nix build ~/nix#homeConfigurations.zeno-desktop.activationPackage
```

### Development Workflow

```bash
# Enter dev shell with all tools
just dev

# Format before committing
just format && just check

# Quick save
just git-save
```

## Migration from Old Setup

If you have existing dotfiles:

```bash
# 1. Backup your current dotfiles
cp -r ~/.config ~/.config.backup

# 2. Bootstrap will create backups automatically
just init desktop

# 3. Merge your old configs if needed
diff ~/.zshrc.backup ~/nix/dotfiles/.zshrc
```

## License

This configuration is provided as-is for personal use.
