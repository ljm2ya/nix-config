#!/bin/bash

echo "Switching to full system configuration..."

# Link full system profile for home-manager
ln -sf ~/nix/profiles/full-system.nix ~/.config/home-manager/home.nix

# Create symlink for system configuration (requires sudo)
echo "Linking system configuration (requires sudo)..."
sudo ln -sf ~/nix/modules/system/configuration.nix /etc/nixos/configuration.nix

echo "Applying system configuration..."
sudo nixos-rebuild switch

echo "Applying home-manager configuration..."
home-manager switch

echo "✅ Full system configuration active!"
echo ""
echo "This configuration includes:"
echo "- All CLI tools and utilities"
echo "- System-level programs and services"
echo "- GUI applications and desktop environment"
echo "- Hardware and system services"