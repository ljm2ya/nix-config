# Final improved flake.nix with automatic input inheritance
# - Multiple homeConfigurations outputs (no symlink needed)
# - Automatic input inheritance to all profiles
# - Registry support built-in
# - No manual profile modification required
#
# Migration from current flake.nix:
#   cp flake.nix flake.nix.backup
#   mv flake-final.nix.example flake.nix
#   nix flake check
#
# Usage:
#   home-manager switch --flake ~/nix#zeno-cli
#   home-manager switch --flake ~/nix#zeno-desktop
#   nixos-rebuild switch --flake ~/nix#nixos

{
  description = "Unified NixOS and Home Manager Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, antigravity-nix, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # ==================================================================
      # Common overlay configuration
      # Applied to both NixOS and home-manager
      # ==================================================================
      commonOverlays = [ antigravity-nix.overlays.default ];

      # ==================================================================
      # Shared module that provides registry configuration
      # Automatically included in all home-manager configs
      # ==================================================================
      registryModule = {
        nix = {
          package = pkgs.nix;
          registry = {
            # User-level registry for home-manager
            home.flake = self;
            nixpkgs.flake = nixpkgs;
          };
          settings.experimental-features = [ "nix-command" "flakes" ];
        };
      };

      # ==================================================================
      # Helper function to create home-manager configuration
      # Automatically passes inputs and adds registry support
      # ==================================================================
      mkHomeConfig = profilePath: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Automatically pass all inputs to modules
        # This means profiles can use 'inputs' without any changes
        extraSpecialArgs = { inherit inputs; };

        modules = [
          # Apply common overlay
          { nixpkgs.overlays = commonOverlays; }

          # Add registry configuration automatically
          registryModule

          # Import the actual profile
          profilePath
        ];
      };
    in
    {
      # ==================================================================
      # NixOS System Configuration
      # ==================================================================
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;

        # Pass inputs to NixOS modules
        specialArgs = { inherit inputs; };

        modules = [
          # Hardware configuration
          ./modules/nixos/hardware-configuration.nix

          # Main system configuration
          ./modules/nixos/configuration.nix

          # Apply common overlays
          { nixpkgs.overlays = commonOverlays; }

          # System-level registry configuration
          {
            nix.registry = {
              # System-level registry for nixos-rebuild
              nixos.flake = self;
              home.flake = self;
              nixpkgs.flake = nixpkgs;
            };

            # NIX_PATH for backwards compatibility
            nix.nixPath = [
              "nixpkgs=${nixpkgs}"
              "nixos-config=/etc/nixos/configuration.nix"
            ];

            # Enable flakes system-wide
            nix.settings.experimental-features = [ "nix-command" "flakes" ];

            # Note: Symlink configurations manually if needed:
            # sudo ln -sf ~/nix/flake.nix /etc/nixos/flake.nix
            # sudo ln -sf ~/nix/modules/nixos/configuration.nix /etc/nixos/configuration.nix
          }
        ];
      };

      # ==================================================================
      # Home Manager Configurations - Multiple Profiles
      # All profiles automatically get:
      # - inputs via extraSpecialArgs
      # - registry configuration
      # - common overlays
      # ==================================================================
      homeConfigurations = {
        # CLI-only profile
        # Usage: home-manager switch --flake ~/nix#zeno-cli
        #    or: home-manager switch --flake home:#zeno-cli
        zeno-cli = mkHomeConfig ./profiles/cli-only.nix;

        # Desktop profile (CLI + GUI apps, no system config)
        # Usage: home-manager switch --flake ~/nix#zeno-desktop
        #    or: home-manager switch --flake home:#zeno-desktop
        zeno-desktop = mkHomeConfig ./profiles/desktop.nix;

        # Full system profile (used with NixOS configuration)
        # Usage: home-manager switch --flake ~/nix#zeno-full
        #    or: home-manager switch --flake home:#zeno-full
        zeno-full = mkHomeConfig ./profiles/full-system.nix;

        # Default profile (alias for desktop)
        # Usage: home-manager switch --flake ~/nix
        #    or: home-manager switch --flake ~/nix#zeno
        zeno = mkHomeConfig ./profiles/desktop.nix;
      };

      # ==================================================================
      # Flake Apps (Optional convenience commands)
      # ==================================================================
      apps.${system} = {
        # Quick profile switching
        switch-cli = {
          type = "app";
          program = toString (pkgs.writeShellScript "switch-cli" ''
            echo "🔄 Switching to CLI-only profile..."
            ${pkgs.home-manager}/bin/home-manager switch --flake ${self}#zeno-cli
            echo "✅ CLI-only profile active!"
          '');
        };

        switch-desktop = {
          type = "app";
          program = toString (pkgs.writeShellScript "switch-desktop" ''
            echo "🔄 Switching to desktop profile..."
            ${pkgs.home-manager}/bin/home-manager switch --flake ${self}#zeno-desktop
            echo "✅ Desktop profile active!"
          '');
        };

        switch-full = {
          type = "app";
          program = toString (pkgs.writeShellScript "switch-full" ''
            echo "🔄 Switching to full system configuration..."
            echo "📦 Applying NixOS configuration..."
            sudo ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake ${self}#nixos
            echo "🏠 Applying home-manager configuration..."
            ${pkgs.home-manager}/bin/home-manager switch --flake ${self}#zeno-full
            echo "✅ Full system configuration active!"
          '');
        };

        # Status checker
        status = {
          type = "app";
          program = toString (pkgs.writeShellScript "status" ''
            echo "📊 Home Manager Status"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            ${pkgs.home-manager}/bin/home-manager generations | head -n 5
          '');
        };
      };

      # ==================================================================
      # Development Shell
      # ==================================================================
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nixpkgs-fmt
          nil
          statix
          # home-manager is available system-wide
        ];

        shellHook = ''
          echo "🛠️  Nix Configuration Development Shell"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "Commands:"
          echo "  nixpkgs-fmt .    - Format Nix files"
          echo "  statix check     - Lint configuration"
          echo "  nix flake check  - Validate flake"
          echo ""
          echo "Current flake outputs:"
          nix flake show
        '';
      };
    };
}

# ═══════════════════════════════════════════════════════════════
# KEY FEATURES
# ═══════════════════════════════════════════════════════════════
#
# ✅ Automatic Input Inheritance
#    - All profiles automatically get 'inputs' via extraSpecialArgs
#    - No need to modify individual profile files
#    - Just works out of the box
#
# ✅ Built-in Registry Support
#    - System-level registry (nixos-rebuild)
#    - User-level registry (home-manager)
#    - No separate module files needed
#
# ✅ Automatic Overlay Application
#    - Common overlays applied to all configs
#    - Centralized overlay management
#
# ✅ DRY (Don't Repeat Yourself)
#    - Helper function mkHomeConfig reduces duplication
#    - Registry module shared across all profiles
#    - Single source of truth for common settings
#
# ✅ Zero Profile Modification Required
#    - Profiles stay clean and simple
#    - All magic happens in flake.nix
#    - Easy to add new profiles
#
# ═══════════════════════════════════════════════════════════════
# USAGE EXAMPLES
# ═══════════════════════════════════════════════════════════════
#
# After applying this flake:
#
# 1. Full path (works immediately):
#    home-manager switch --flake ~/nix#zeno-cli
#    home-manager switch --flake ~/nix#zeno-desktop
#    sudo nixos-rebuild switch --flake ~/nix#nixos
#
# 2. Registry-based (works after first switch):
#    home-manager switch --flake home:#zeno-cli
#    home-manager switch --flake home:#zeno-desktop
#    sudo nixos-rebuild switch --flake nixos:#nixos
#
# 3. With flake apps:
#    nix run ~/nix#switch-cli
#    nix run ~/nix#switch-desktop
#    nix run ~/nix#switch-full
#    nix run ~/nix#status
#
# 4. Development:
#    nix develop  # Enter dev shell
#
# ═══════════════════════════════════════════════════════════════
# ADDING NEW PROFILES
# ═══════════════════════════════════════════════════════════════
#
# To add a new profile (e.g., "server"):
#
# 1. Create profile file:
#    profiles/server.nix
#
# 2. Add one line to homeConfigurations:
#    zeno-server = mkHomeConfig ./profiles/server.nix;
#
# 3. Done! The profile automatically gets:
#    - inputs inheritance
#    - registry support
#    - common overlays
#
# No other changes needed!
