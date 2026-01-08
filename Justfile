# Nix Configuration Management with Just
# =====================================
# Replaces the complicated nix-config bash script with clean, declarative recipes
#
# Usage:
#   just                    - Show available commands
#   just status             - Check current configuration
#   just switch-cli         - Switch to CLI-only profile
#   just switch-desktop     - Switch to desktop profile
#   just switch-full        - Switch to full system profile
#   just init desktop       - Bootstrap system with desktop profile
#   just migrate            - Migrate from old configuration

# Configuration
set shell := ["bash", "-c"]
nix_dir := justfile_directory()
state_file := env_var('HOME') / ".nix-config-state"

# Default recipe - show available commands
default:
    @just --list

# ═══════════════════════════════════════════════════════════════
# Profile Switching Commands
# ═══════════════════════════════════════════════════════════════

# Switch to CLI-only profile (minimal, no GUI)
switch-cli:
    @echo "🔄 Switching to CLI-only profile..."
    @just _check-bootstrapped
    home-manager switch --flake {{nix_dir}}#zeno-cli
    @just _update-state "current_profile" "cli-only"
    @echo "✅ CLI-only profile active!"

# Switch to desktop profile (CLI + GUI apps)
switch-desktop:
    @echo "🔄 Switching to desktop profile..."
    @just _check-bootstrapped
    home-manager switch --flake {{nix_dir}}#zeno-desktop
    @just _update-state "current_profile" "desktop"
    @echo "✅ Desktop profile active!"

# Switch to full system profile (NixOS + home-manager)
switch-full:
    @echo "🔄 Switching to full system configuration..."
    @just _check-bootstrapped
    @echo "📦 Applying NixOS configuration..."
    sudo nixos-rebuild switch --flake {{nix_dir}}#nixos
    @echo "🏠 Applying home-manager configuration..."
    home-manager switch --flake {{nix_dir}}#zeno-full
    @just _update-state "current_profile" "full"
    @echo "✅ Full system configuration active!"

# Switch to full system profile but only home-manager 
switch-home:
    @echo "🔄 Switching to full system (only home-manager) configuration..."
    @just _check-bootstrapped
    @echo "🏠 Applying home-manager configuration..."
    home-manager switch --flake {{nix_dir}}#zeno-full
    @just _update-state "current_profile" "full"
    @echo "✅ Full system home configuration active!"

# Switch to a profile. If no profile is specified, switch to the last used profile.
switch profile="":
    @if [ -z "{{profile}}" ]; then \
        last_profile=$(just _get-state current_profile); \
        if [ -z "$last_profile" ]; then \
            echo "❌ Error: No last profile found. Please run 'just switch <profile>' first."; \
            exit 1; \
        fi; \
        echo "🔄 Switching to last used profile: $last_profile..."; \
        just switch-$last_profile; \
    else \
        just switch-{{profile}}; \
    fi

# ═══════════════════════════════════════════════════════════════
# System Information & Status
# ═══════════════════════════════════════════════════════════════

# Show current configuration status
status:
    @just _print-banner
    @if [ -f "{{state_file}}" ]; then \
        echo "✅ Configuration: Bootstrapped"; \
        echo "ℹ️  Current Profile: $(just _get-state current_profile)"; \
        echo "ℹ️  Machine Type: $(just _get-state machine_type)"; \
        echo "ℹ️  Nix Directory: $(just _get-state nix_dir)"; \
        echo "ℹ️  Last Update: $(just _get-state last_update)"; \
        echo ""; \
        echo "📊 Recent home-manager generations:"; \
        home-manager generations | head -n 5; \
    else \
        echo "⚠️  Configuration: Not bootstrapped"; \
        echo "ℹ️  Run 'just init <profile>' to bootstrap the system"; \
    fi
    @echo ""

# Show flake outputs
show:
    @echo "📋 Flake outputs:"
    nix flake show {{nix_dir}}

# Show flake metadata
metadata:
    @echo "📋 Flake metadata:"
    nix flake metadata {{nix_dir}}

# Show registry configuration
registry:
    @echo "📋 Nix registry:"
    nix registry list | grep -E 'home|nixos' || echo "No custom registry entries found"

# Show recent generations
generations:
    @echo "📊 Home Manager generations:"
    home-manager generations | head -n 10

# ═══════════════════════════════════════════════════════════════
# Bootstrap & Setup
# ═══════════════════════════════════════════════════════════════

# Bootstrap system (first-time setup)
init profile machine_type="auto":
    @just _print-banner
    @echo "🚀 Starting bootstrap process..."
    @echo "ℹ️  Profile: {{profile}}"
    @if [ "{{machine_type}}" = "auto" ]; then \
        detected=$(just _detect-machine-type); \
        echo "ℹ️  Machine Type: $detected (auto-detected)"; \
        just _bootstrap {{profile}} $detected; \
    else \
        echo "ℹ️  Machine Type: {{machine_type}}"; \
        just _bootstrap {{profile}} {{machine_type}}; \
    fi

# Migrate from old configuration
migrate:
    @just _print-banner
    @echo "🔄 Migrating from old configuration..."
    @detected_profile=$(just _detect-old-profile); \
    detected_machine=$(just _get-state machine_type); \
    if [ -z "$detected_machine" ]; then \
        detected_machine=$(just _detect-machine-type); \
    fi; \
    echo "ℹ️  Detected profile: $detected_profile"; \
    echo "ℹ️  Detected machine type: $detected_machine"; \
    read -p "Migrate with these settings? [y/N]: " -n 1 -r; \
    echo; \
    if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
        just _restore-ssh-keys; \
        just _create-state "bootstrapped" "true"; \
        just _update-state "current_profile" "$detected_profile"; \
        just _update-state "machine_type" "$detected_machine"; \
        just _update-state "migrated" "true"; \
        echo "✅ Migration complete!"; \
        echo "ℹ️  State file created at: {{state_file}}"; \
        just status; \
    else \
        echo "⚠️  Migration cancelled"; \
    fi

# ═══════════════════════════════════════════════════════════════
# Flake Operations
# ═══════════════════════════════════════════════════════════════

# Check flake for errors
check:
    @echo "🔍 Checking flake configuration..."
    nix flake check {{nix_dir}}
    @echo "✅ Flake check passed!"

# Update flake inputs
update:
    @echo "⬆️  Updating flake inputs..."
    nix flake update {{nix_dir}}
    @echo "✅ Flake inputs updated!"

# Update and check flake
update-check: update check

# Format all Nix files
format:
    @echo "🎨 Formatting Nix files..."
    nixpkgs-fmt {{nix_dir}}
    @echo "✅ Formatting complete!"

# Lint configuration with statix
lint:
    @echo "🔍 Linting Nix files..."
    statix check {{nix_dir}}
    @echo "✅ Lint check passed!"

# ═══════════════════════════════════════════════════════════════
# Cleanup & Maintenance
# ═══════════════════════════════════════════════════════════════

# Clean up old generations (keep last N)
clean days="5":
    @echo "🧹 Cleaning up old generations (older than {{days}} days)..."
    home-manager expire-generations "-{{days}} days"
    @echo "✅ Old generations removed!"

# Run Nix garbage collection
gc:
    @echo "🗑️  Running garbage collection..."
    nix-collect-garbage -d
    @echo "✅ Garbage collection complete!"

# Deep clean (generations + gc)
deep-clean: clean gc
    @echo "✨ Deep clean complete!"

# Optimize Nix store
optimize:
    @echo "⚡ Optimizing Nix store..."
    nix-store --optimize
    @echo "✅ Nix store optimized!"

# ═══════════════════════════════════════════════════════════════
# Git Operations
# ═══════════════════════════════════════════════════════════════

# Show git status
git-status:
    @cd {{nix_dir}} && git status

# Add all changes to git
git-add:
    @cd {{nix_dir}} && git add .
    @echo "✅ All changes staged"

# Commit changes with message
git-commit message:
    @cd {{nix_dir}} && git commit -m "{{message}}"

# Quick commit (add + commit with generated message)
git-save:
    @cd {{nix_dir}} && \
    git add . && \
    git commit -m "Update configuration - $(date '+%Y-%m-%d %H:%M')"

# ═══════════════════════════════════════════════════════════════
# Secrets Management
# ═══════════════════════════════════════════════════════════════

# Encrypt SSH keys for backup (safe to commit to GitHub)
ssh-backup:
    @echo "🔐 Encrypting SSH keys..."
    @if ! command -v age &> /dev/null; then \
        echo "❌ Error: 'age' not found"; \
        echo "Install with: nix-shell -p age"; \
        exit 1; \
    fi
    @mkdir -p {{nix_dir}}/secrets/ssh
    @echo "⚠️  You'll be prompted for a passphrase (remember it!)"
    @echo ""
    @count=0; \
    for key in $(ls -1 ~/.ssh/ 2>/dev/null | grep -v -E '\.pub$|known_hosts|config|authorized_keys'); do \
        if [ -f ~/.ssh/$key ]; then \
            echo "🔒 Encrypting: $key"; \
            age --encrypt --passphrase --output {{nix_dir}}/secrets/ssh/$key.age ~/.ssh/$key && \
            count=$((count + 1)); \
        fi; \
    done; \
    echo ""; \
    echo "✅ Encrypted $count key(s) to secrets/ssh/"; \
    echo ""; \
    echo "Next steps:"; \
    echo "  1. git add secrets/ssh/*.age"; \
    echo "  2. git commit -m 'Add encrypted SSH keys'"; \
    echo "  3. git push"

# Restore SSH keys from encrypted backup
ssh-restore:
    @echo "🔓 Restoring SSH keys from backup..."
    @if ! command -v age &> /dev/null; then \
        echo "❌ Error: 'age' not found"; \
        echo "Install with: nix-shell -p age"; \
        exit 1; \
    fi
    @if [ ! -d "{{nix_dir}}/secrets/ssh" ]; then \
        echo "❌ No encrypted keys found in secrets/ssh/"; \
        exit 1; \
    fi
    @mkdir -p ~/.ssh
    @chmod 700 ~/.ssh
    @echo "🔑 Enter your encryption passphrase"
    @echo ""
    @count=0; \
    for encrypted in {{nix_dir}}/secrets/ssh/*.age; do \
        if [ -f "$encrypted" ]; then \
            keyname=$(basename "$encrypted" .age); \
            echo "🔓 Decrypting: $keyname"; \
            if age --decrypt --output ~/.ssh/$keyname "$encrypted"; then \
                chmod 600 ~/.ssh/$keyname; \
                count=$((count + 1)); \
            fi; \
        fi; \
    done; \
    echo ""; \
    echo "✅ Restored $count key(s) to ~/.ssh/"; \
    echo ""; \
    echo "Test with:"; \
    echo "  ssh-add -l"; \
    echo "  ssh -T git@github.com"

# List encrypted SSH keys
ssh-list:
    @echo "🔐 Encrypted SSH Keys"
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @if [ -d "{{nix_dir}}/secrets/ssh" ]; then \
        count=0; \
        for file in {{nix_dir}}/secrets/ssh/*.age; do \
            if [ -f "$file" ]; then \
                name=$(basename "$file"); \
                size=$(du -h "$file" | cut -f1); \
                echo "✓ $name ($size)"; \
                count=$((count + 1)); \
            fi; \
        done; \
        if [ $count -eq 0 ]; then \
            echo "No encrypted keys found"; \
        else \
            echo ""; \
            echo "Total: $count encrypted key(s)"; \
        fi; \
    else \
        echo "No secrets directory found"; \
    fi

# ═══════════════════════════════════════════════════════════════
# Development & Testing
# ═══════════════════════════════════════════════════════════════

# Enter development shell
dev:
    @echo "🛠️  Entering development shell..."
    nix develop {{nix_dir}}

# Build a specific flake output
build output:
    @echo "🔨 Building {{output}}..."
    nix build {{nix_dir}}#{{output}}

# Run a flake app
run app:
    @echo "▶️  Running {{app}}..."
    nix run {{nix_dir}}#{{app}}

# Test profile switch without applying (dry-run)
test-switch profile:
    @echo "🧪 Testing {{profile}} profile switch (dry-run)..."
    home-manager switch --flake {{nix_dir}}#zeno-{{profile}} --dry-run

# ═══════════════════════════════════════════════════════════════
# Utility Commands
# ═══════════════════════════════════════════════════════════════

# Show system information
sysinfo:
    @echo "💻 System Information"
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "Hostname: $(hostname)"
    @echo "Kernel: $(uname -r)"
    @echo "Architecture: $(uname -m)"
    @echo "NixOS Version: $(nixos-version 2>/dev/null || echo 'Not NixOS')"
    @echo "Nix Version: $(nix --version | head -n1)"
    @echo "Home Manager: $(home-manager --version 2>/dev/null || echo 'Not found')"
    @echo ""
    @echo "Machine Type: $(just _detect-machine-type)"

# Search for packages in nixpkgs
search query:
    @echo "🔍 Searching for: {{query}}"
    nix search nixpkgs {{query}}

# Show documentation for a command
help command:
    @just --show {{command}}

# ═══════════════════════════════════════════════════════════════
# Internal Helper Functions (prefixed with _)
# ═══════════════════════════════════════════════════════════════

# Print banner
_print-banner:
    @echo ""
    @echo "╔════════════════════════════════════════════════════════╗"
    @echo "║   Nix Configuration Manager                            ║"
    @echo "║   Powered by Just                                      ║"
    @echo "╚════════════════════════════════════════════════════════╝"
    @echo ""

# Check if system is bootstrapped
_check-bootstrapped:
    @if [ ! -f "{{state_file}}" ]; then \
        echo "❌ Error: System not bootstrapped yet"; \
        echo "ℹ️  Run 'just init <profile>' first"; \
        exit 1; \
    fi

# Get state value
_get-state key:
    @if [ -f "{{state_file}}" ]; then \
        jq -r ".{{key}} // empty" "{{state_file}}" 2>/dev/null || echo ""; \
    else \
        echo ""; \
    fi

# Update state value
_update-state key value:
    @if [ -f "{{state_file}}" ]; then \
        tmp=$(mktemp); \
        jq ".{{key}} = \"{{value}}\" | .last_update = \"$(date -Iseconds)\"" "{{state_file}}" > "$tmp"; \
        mv "$tmp" "{{state_file}}"; \
    fi

# Create initial state
_create-state key value:
    @echo '{ "{{key}}": "{{value}}",  "last_update": "'$(date -Iseconds)'", "nix_dir": "{{nix_dir}}" }' > "{{state_file}}"

# Detect machine type
_detect-machine-type:
    @if systemd-detect-virt --quiet 2>/dev/null; then \
        echo "vm"; \
    elif [ -d /sys/class/power_supply/BAT* ] 2>/dev/null || [ -d /sys/class/power_supply/battery ] 2>/dev/null; then \
        echo "laptop"; \
    else \
        echo "desktop"; \
    fi

# Detect old profile from symlink
_detect-old-profile:
    @if [ -L "$HOME/.config/home-manager/home.nix" ]; then \
        target=$(readlink "$HOME/.config/home-manager/home.nix"); \
        case "$target" in \
            */cli-only.nix) echo "cli-only" ;; \
            */desktop.nix) echo "desktop" ;; \
            */full-system.nix) echo "full" ;; \
            *) echo "desktop" ;; \
        esac; \
    else \
        echo "desktop"; \
    fi

# Restore SSH keys if available
_restore-ssh-keys:
    @echo ""
    @echo "🔑 Checking for encrypted SSH keys..."
    @if [ -d "{{nix_dir}}/secrets/ssh" ] && [ -n "$(ls -A {{nix_dir}}/secrets/ssh/*.age 2>/dev/null)" ]; then \
        echo "✓ Found encrypted SSH keys"; \
        echo ""; \
        read -p "Restore SSH keys now? [Y/n]: " -n 1 -r; \
        echo; \
        if [[ ! $$REPLY =~ ^[Nn]$$ ]]; then \
            if ! command -v age &> /dev/null; then \
                echo "Installing age..."; \
                nix-shell -p age --run "echo '✓ age installed'"; \
            fi; \
            echo ""; \
            nix-shell -p age --run "cd {{nix_dir}} && just ssh-restore" || \
            echo "⚠️  SSH key restoration failed - you can restore later with: just ssh-restore"; \
        else \
            echo "⏭️  Skipped SSH key restoration"; \
            echo "ℹ️  Run 'just ssh-restore' later to restore keys"; \
        fi; \
    else \
        echo "ℹ️  No encrypted SSH keys found (this is normal for first-time setup)"; \
        echo "ℹ️  After setup, backup keys with: just ssh-backup"; \
    fi
    @echo ""

# Bootstrap implementation
_bootstrap profile machine_type:
    @echo "📦 Installing prerequisites..."
    @if ! command -v home-manager &> /dev/null; then \
        echo "Installing home-manager..."; \
        nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager || true; \
        nix-channel --update; \
        nix-shell '<home-manager>' -A install; \
    fi
    @echo "✅ Prerequisites installed"
    @just _restore-ssh-keys
    @if [ "{{profile}}" = "full" ]; then \
        just _bootstrap-system {{machine_type}}; \
    fi
    @echo "🏠 Initializing flake..."
    @cd {{nix_dir}} && if [ ! -f "flake.lock" ]; then nix flake update; fi
    @echo "🔄 Applying configuration..."
    @if [ "{{profile}}" = "full" ]; then \
        sudo nixos-rebuild switch --flake {{nix_dir}}#nixos; \
        home-manager switch --flake {{nix_dir}}#zeno-full; \
    elif [ "{{profile}}" = "desktop" ]; then \
        home-manager switch --flake {{nix_dir}}#zeno-desktop; \
    else \
        home-manager switch --flake {{nix_dir}}#zeno-cli; \
    fi
    @just _create-state "bootstrapped" "true"
    @just _update-state "current_profile" "{{profile}}"
    @just _update-state "machine_type" "{{machine_type}}"
    @echo "✅ Bootstrap complete!"
    @just status

# Bootstrap system configuration
_bootstrap-system machine_type:
    @echo "⚙️  Configuring NixOS system..."
    @echo "⚙️  Updating hardware-configuration.nix..."
    @if [ -f "/etc/nixos/hardware-configuration.nix" ]; then \
        cp /etc/nixos/hardware-configuration.nix {{nix_dir}}/modules/nixos/hardware-configuration.nix; \
        echo "✅ Copied existing hardware-configuration.nix from /etc/nixos."; \
    else \
        echo "ℹ️  No existing hardware configuration found. Generating a new one..."; \
        if ! NGC_PATH=$(command -v nixos-generate-config); then \
            echo "❌ Error: nixos-generate-config command not found."; \
            echo "ℹ️  Please make sure you are running this on a NixOS installer or a NixOS system."; \
            exit 1; \
        fi; \
        sudo "$NGC_PATH" --show-hardware-config > {{nix_dir}}/modules/nixos/hardware-configuration.nix; \
        echo "✅ Generated new hardware-configuration.nix."; \
    fi
    @echo "⚙️  Detecting boot system and configuring bootloader..."
    @if [ -d /sys/firmware/efi ]; then \
        echo "ℹ️  UEFI system detected. Using systemd-boot."; \
        sed -i 's/bootloader = ".*";/bootloader = "systemd-boot";/' {{nix_dir}}/modules/nixos/base.nix; \
    else \
        echo "ℹ️  BIOS system detected. Using GRUB."; \
        ROOT_PART=$(findmnt -n -o SOURCE /); \
        BOOT_DISK_NAME=$(lsblk -no PKNAME "$ROOT_PART"); \
        BOOT_DEVICE="/dev/$BOOT_DISK_NAME"; \
        echo "ℹ️  Setting GRUB device to: $BOOT_DEVICE"; \
        sed -i 's/bootloader = ".*";/bootloader = "grub";/' {{nix_dir}}/modules/nixos/base.nix; \
        escaped_boot_device=$(echo "$BOOT_DEVICE" | sed 's#/#\\\/#g'); \
        sed -i "s/grubDevice = \".*\";/grubDevice = \"$escaped_boot_device\";/" {{nix_dir}}/modules/nixos/base.nix; \
    fi
    @if [ -f "{{nix_dir}}/modules/nixos/base.nix" ]; then \
        sed -i "s/machineType = \".*\";/machineType = \"{{machine_type}}\";/" {{nix_dir}}/modules/nixos/base.nix; \
        echo "✅ Updated base.nix with machine type"; \
        if [ "{{machine_type}}" != "vm" ]; then \
            echo "⚙️  Detecting swap and resume UUIDs..."; \
            SWAP_UUID=$(lsblk -no UUID,TYPE | awk '$$2=="part" {print $$1}' | while read uuid; do if swapon --show=UUID --noheadings | grep -q "$$uuid" 2>/dev/null; then echo "$$uuid"; break; fi; done); \
            if [ -z "$SWAP_UUID" ]; then \
                SWAP_UUID=$(lsblk -no UUID,FSTYPE | awk '$$2=="swap" {print $$1; exit}'); \
            fi; \
            if [ -n "$SWAP_UUID" ]; then \
                echo "ℹ️  Found Swap UUID: $SWAP_UUID"; \
                RESUME_UUID="$SWAP_UUID"; \
                sed -i "s/swapUUID = \".*\";/swapUUID = \"$SWAP_UUID\";/" {{nix_dir}}/modules/nixos/base.nix; \
                sed -i "s/resumeUUID = \".*\";/resumeUUID = \"$RESUME_UUID\";/" {{nix_dir}}/modules/nixos/base.nix; \
                echo "✅ Updated base.nix with swap and resume UUIDs."; \
            else \
                echo "⚠️  No swap partition found. Hibernation will be disabled."; \
            fi; \
        else \
            echo "ℹ️  VM detected, skipping swap UUID detection."; \
        fi; \
    fi
    @sudo ln -sf {{nix_dir}}/modules/nixos/configuration.nix /etc/nixos/configuration.nix
    @sudo ln -sf {{nix_dir}}/flake.nix /etc/nixos/flake.nix
    @echo "✅ System configuration linked"
