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

  outputs = { self, nixpkgs, home-manager, antigravity-nix, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./system/hardware-configuration.nix
        ./system/configuration.nix

        # Make antigravity available as an overlay
        { nixpkgs.overlays = [ antigravity-nix.overlays.default ]; }
      ];
    };

    homeConfigurations.zeno = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        ./profiles/gui.nix

        # Make antigravity available
        {
          nixpkgs.overlays = [ antigravity-nix.overlays.default ];
        }
      ];
    };
  };
}
