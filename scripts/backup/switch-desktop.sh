#!/usr/bin/env bash

echo "Switching to desktop profile..."

# Link desktop profile for home-manager
ln -sf ~/nix/profiles/desktop.nix ~/.config/home-manager/home.nix

echo "Applying home-manager configuration (flake-based)..."
home-manager switch --flake ~/nix#zeno

echo "✅ Desktop profile active!"
echo ""
echo "This configuration includes:"
echo "- All CLI tools and utilities"
echo "- Desktop applications (browsers, discord, file managers, etc.)"
echo "- Desktop environment user configurations"
echo ""
echo "System configuration remains unchanged."
echo "Note: This profile includes desktop apps but NOT system-level"
echo "desktop services (X11, display manager, etc.)"
echo "Use switch-full-system.sh to enable complete desktop system."
