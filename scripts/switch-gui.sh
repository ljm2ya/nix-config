#!/usr/bin/env bash

echo "Switching to GUI profile..."

# Link GUI profile for home-manager
ln -sf ~/nix/profiles/gui.nix ~/.config/home-manager/home.nix

echo "Applying home-manager configuration (flake-based)..."
home-manager switch --flake ~/nix#zeno

echo "✅ GUI profile active!"
echo ""
echo "This configuration includes:"
echo "- All CLI tools and utilities"
echo "- GUI applications (browsers, discord, file managers, etc.)"
echo "- Desktop environment user configurations"
echo ""
echo "System configuration remains unchanged."
echo "Note: This profile includes GUI apps but NOT system-level"
echo "GUI services (X11, display manager, etc.)"
echo "Use switch-full-system.sh to enable complete GUI system."
