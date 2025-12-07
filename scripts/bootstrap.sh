#!/usr/bin/env bash
set -e

# Bootstrap script for fresh NixOS installations
# This script helps set up the nix configuration on a new system

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIX_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

# Banner
echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║   NixOS Configuration Bootstrap                        ║"
echo "║   3-Tier Modular Architecture Setup                    ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check if we're in the right directory
if [[ ! -f "$NIX_DIR/README.md" ]] || [[ ! -d "$NIX_DIR/dotfiles" ]]; then
    print_error "This script must be run from the nix repository"
    print_error "Current directory: $(pwd)"
    print_error "Expected: ~/nix/"
    exit 1
fi

print_success "Repository found at: $NIX_DIR"

# Parse arguments
PROFILE="cli"
SYSTEM_CONFIG=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --profile)
            PROFILE="$2"
            shift 2
            ;;
        --system)
            SYSTEM_CONFIG=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --profile <cli|gui|full>  Choose profile tier (default: cli)"
            echo "  --system                  Also configure system (NixOS rebuild)"
            echo "  --help, -h                Show this help message"
            echo ""
            echo "Profiles:"
            echo "  cli   - CLI tools only (home-manager)"
            echo "  gui   - CLI + GUI apps (home-manager, no system changes)"
            echo "  full  - Complete system (home-manager + NixOS rebuild)"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate profile
if [[ ! "$PROFILE" =~ ^(cli|gui|full)$ ]]; then
    print_error "Invalid profile: $PROFILE"
    print_error "Valid profiles: cli, gui, full"
    exit 1
fi

# For full profile, enable system config
if [[ "$PROFILE" == "full" ]]; then
    SYSTEM_CONFIG=true
fi

# Machine type detection (only for system config)
MACHINE_TYPE=""
if [[ "$SYSTEM_CONFIG" = true ]]; then
    echo ""
    print_info "Detecting machine type..."

    # Try to detect if running in VM
    if systemd-detect-virt --quiet; then
        DETECTED_TYPE="vm"
        print_info "Detected: Virtual Machine"
    # Check for battery (laptop indicator)
    elif [ -d /sys/class/power_supply/BAT* ] 2>/dev/null || [ -d /sys/class/power_supply/battery ] 2>/dev/null; then
        DETECTED_TYPE="laptop"
        print_info "Detected: Laptop (battery found)"
    else
        DETECTED_TYPE="desktop"
        print_info "Detected: Desktop"
    fi

    echo ""
    print_info "Select machine type:"
    echo "  1) Laptop  - Full power management, lid switch handling"
    echo "  2) Desktop - Basic power management, no lid handling"
    echo "  3) VM      - Minimal hardware config, VMware guest tools"
    echo ""

    # Default selection based on detection
    case $DETECTED_TYPE in
        laptop)  DEFAULT_CHOICE=1 ;;
        desktop) DEFAULT_CHOICE=2 ;;
        vm)      DEFAULT_CHOICE=3 ;;
    esac

    read -p "$(echo -e ${YELLOW}Enter choice [${DEFAULT_CHOICE}]:${NC} )" MACHINE_CHOICE
    MACHINE_CHOICE=${MACHINE_CHOICE:-$DEFAULT_CHOICE}

    case $MACHINE_CHOICE in
        1) MACHINE_TYPE="laptop" ;;
        2) MACHINE_TYPE="desktop" ;;
        3) MACHINE_TYPE="vm" ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac

    print_success "Machine type: $MACHINE_TYPE"
fi

echo ""
print_info "Configuration:"
print_info "  Profile: $PROFILE"
print_info "  System config: $([ "$SYSTEM_CONFIG" = true ] && echo 'yes' || echo 'no')"
if [[ "$SYSTEM_CONFIG" = true ]]; then
    print_info "  Machine type: $MACHINE_TYPE"
fi
echo ""

# Confirm before proceeding
read -p "$(echo -e ${YELLOW}Continue with installation? [y/N]:${NC} )" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Installation cancelled"
    exit 0
fi

echo ""
print_info "Step 1: Checking prerequisites..."

# Check if home-manager is available
if ! command -v home-manager &> /dev/null; then
    print_warning "home-manager not found in PATH"
    print_info "Installing home-manager..."

    if ! nix-channel --list | grep -q home-manager; then
        nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
        nix-channel --update
        print_success "Added home-manager channel"
    fi

    # Install home-manager
    nix-shell '<home-manager>' -A install
fi

print_success "Prerequisites checked"

# System configuration
if [[ "$SYSTEM_CONFIG" = true ]]; then
    echo ""
    print_info "Step 2: Setting up system configuration..."

    # Check for hardware-configuration.nix
    if [[ ! -f "$NIX_DIR/system/hardware-configuration.nix" ]]; then
        print_warning "hardware-configuration.nix not found"
        print_info "Generating hardware configuration..."

        if ! sudo nixos-generate-config --show-hardware-config > "$NIX_DIR/system/hardware-configuration.nix"; then
            print_error "Failed to generate hardware configuration"
            exit 1
        fi

        print_success "Generated hardware-configuration.nix"
        print_warning "Review $NIX_DIR/system/hardware-configuration.nix"
        print_warning "You may need to customize boot/swap settings"
    else
        print_success "hardware-configuration.nix exists"
    fi

    # Detect and configure UUIDs (skip for VM)
    if [[ "$MACHINE_TYPE" != "vm" ]]; then
        print_info "Detecting swap and resume device UUIDs..."

        # Try to find swap partition UUID
        SWAP_UUID=$(lsblk -no UUID,TYPE | awk '$2=="part" {print $1}' | while read uuid; do
            if swapon --show=UUID --noheadings | grep -q "$uuid" 2>/dev/null; then
                echo "$uuid"
                break
            fi
        done)

        # If no active swap, try to find swap partition by type
        if [[ -z "$SWAP_UUID" ]]; then
            SWAP_UUID=$(lsblk -no UUID,FSTYPE | awk '$2=="swap" {print $1; exit}')
        fi

        # Resume device is usually the same as swap
        RESUME_UUID="$SWAP_UUID"

        if [[ -n "$SWAP_UUID" ]]; then
            print_success "Swap UUID: $SWAP_UUID"
        else
            print_warning "No swap device found - hibernation will be disabled"
            SWAP_UUID="00000000-0000-0000-0000-000000000000"  # Placeholder
            RESUME_UUID="$SWAP_UUID"
        fi
    else
        print_info "VM detected - skipping UUID detection"
        SWAP_UUID=""
        RESUME_UUID=""
    fi

    # Update base.nix with machine type and UUIDs
    print_info "Updating base.nix with machine type and UUIDs..."

    # Create a backup
    cp "$NIX_DIR/system/base.nix" "$NIX_DIR/system/base.nix.backup"

    # Update machine type
    sed -i "s/machineType = \".*\";/machineType = \"$MACHINE_TYPE\";/" "$NIX_DIR/system/base.nix"

    # Update UUIDs (only if not VM)
    if [[ "$MACHINE_TYPE" != "vm" ]] && [[ -n "$SWAP_UUID" ]]; then
        sed -i "s/swapUUID = \".*\";/swapUUID = \"$SWAP_UUID\";/" "$NIX_DIR/system/base.nix"
        sed -i "s/resumeUUID = \".*\";/resumeUUID = \"$RESUME_UUID\";/" "$NIX_DIR/system/base.nix"
    fi

    print_success "base.nix updated"
    print_info "  Machine type: $MACHINE_TYPE"
    if [[ "$MACHINE_TYPE" != "vm" ]]; then
        print_info "  Swap UUID: ${SWAP_UUID:0:8}..."
        print_info "  Resume UUID: ${RESUME_UUID:0:8}..."
    fi

    # Link system configuration
    print_info "Linking system configuration..."
    if sudo ln -sf "$NIX_DIR/system/configuration.nix" /etc/nixos/configuration.nix; then
        print_success "System configuration linked"
    else
        print_error "Failed to link system configuration"
        exit 1
    fi

    # Rebuild system
    print_info "Building NixOS system configuration..."
    print_warning "This may take several minutes..."

    if sudo nixos-rebuild switch; then
        print_success "System configuration applied"
    else
        print_error "System rebuild failed"
        print_error "Check the error messages above"
        exit 1
    fi
else
    print_info "Step 2: Skipping system configuration"
fi

# Home Manager configuration
echo ""
print_info "Step 3: Setting up home-manager configuration..."

# Create home-manager config directory
mkdir -p ~/.config/home-manager

# Link appropriate profile
case $PROFILE in
    cli)
        PROFILE_FILE="$NIX_DIR/profiles/cli-only.nix"
        ;;
    gui)
        PROFILE_FILE="$NIX_DIR/profiles/gui.nix"
        ;;
    full)
        PROFILE_FILE="$NIX_DIR/profiles/full-system.nix"
        ;;
esac

print_info "Linking profile: $PROFILE"
if ln -sf "$PROFILE_FILE" ~/.config/home-manager/home.nix; then
    print_success "Profile linked: $PROFILE_FILE"
else
    print_error "Failed to link profile"
    exit 1
fi

# Apply home-manager configuration
print_info "Applying home-manager configuration..."
print_warning "This may take several minutes on first run..."

if home-manager switch; then
    print_success "Home-manager configuration applied"
else
    print_error "Home-manager switch failed"
    print_error "Check the error messages above"
    exit 1
fi

# Verify symlinks
echo ""
print_info "Step 4: Verifying installation..."

# Check CLI dotfiles
if [[ -L ~/.zshrc ]] && [[ -L ~/.vimrc ]]; then
    print_success "CLI dotfiles linked correctly"
else
    print_warning "Some CLI dotfiles may not be linked"
fi

# Check GUI dotfiles if GUI profile
if [[ "$PROFILE" == "gui" ]] || [[ "$PROFILE" == "full" ]]; then
    if [[ -L ~/.xinitrc ]] && [[ -L ~/.config/awesome ]]; then
        print_success "GUI dotfiles linked correctly"
    else
        print_warning "Some GUI dotfiles may not be linked"
    fi
fi

# Final summary
echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║   Installation Complete!                               ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
print_success "Profile: $PROFILE"
print_success "Dotfiles: ~/nix/dotfiles/"
print_success "Configuration: ~/nix/"
echo ""

print_info "Next steps:"
echo "  1. Customize dotfiles in ~/nix/dotfiles/"
echo "  2. Add packages to ~/nix/home-manager/{cli,gui}.nix"
echo "  3. Commit your changes: cd ~/nix && git add . && git commit"
echo ""

if [[ "$PROFILE" == "cli" ]]; then
    print_info "To enable GUI later, run:"
    echo "  ~/nix/scripts/switch-gui.sh"
    echo ""
fi

if [[ "$SYSTEM_CONFIG" = false ]] && [[ "$PROFILE" != "cli" ]]; then
    print_warning "Note: GUI apps installed, but system GUI services not configured"
    print_info "To enable full system (X11, WM, etc.), run:"
    echo "  ~/nix/scripts/switch-full-system.sh"
    echo ""
fi

print_info "For more information, see:"
echo "  ~/nix/README.md - Complete documentation and installation guide"
echo ""
