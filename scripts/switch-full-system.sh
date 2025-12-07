#!/usr/bin/env bash

echo "Switching to full system configuration..."

# Link full system profile for home-manager
ln -sf ~/nix/profiles/full-system.nix ~/.config/home-manager/home.nix

# Create symlinks for system configuration (requires sudo)
echo "Linking system configuration (requires sudo)..."
sudo ln -sf ~/nix/system/configuration.nix /etc/nixos/configuration.nix
sudo ln -sf ~/nix/flake.nix /etc/nixos/flake.nix

echo "Applying system configuration (flake-based)..."
sudo nixos-rebuild switch --flake ~/nix#nixos


echo "Applying home-manager configuration (flake-based)..."
home-manager switch --flake ~/nix#zeno

echo "✅ Full system configuration active!"
echo ""
echo "This configuration includes:"
echo "- All CLI tools and utilities"
echo "- System-level programs and services"
echo "- GUI applications and desktop environment"
echo "- Hardware and system services"
