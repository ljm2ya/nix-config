#!/usr/bin/env bash

echo "Switching to CLI-only configuration..."

# Link CLI-only profile
ln -sf ~/nix/profiles/cli-only.nix ~/.config/home-manager/home.nix

echo "Applying home-manager configuration..."
home-manager switch

echo "✅ CLI-only configuration active!"
echo ""
echo "This configuration includes:"
echo "- All CLI tools and utilities"
echo "- Neovim, tmux, zsh configurations"
echo "- Development tools and command-line programs"
echo "- Dotfile management"
echo ""
echo "System configuration remains unchanged."
