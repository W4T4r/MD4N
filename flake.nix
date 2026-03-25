# ███╗   ███╗██████╗ ██╗  ██╗███╗   ██╗
# ████╗ ████║██╔══██╗██║  ██║████╗  ██║
# ██╔████╔██║██║  ██║███████║██╔██╗ ██║
# ██║╚██╔╝██║██║  ██║╚════██║██║╚██╗██║
# ██║ ╚═╝ ██║██████╔╝     ██║██║ ╚████║
# ╚═╝     ╚═╝╚═════╝      ╚═╝╚═╝  ╚═══╝
#
# flake.nix
{
  description = "My NixOS + Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.noctalia-qs.follows = "noctalia-qs";
    };

    noctalia-qs = {
      url = "github:noctalia-dev/noctalia-qs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix4nvchad = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-grub-themes.url = "github:jeslie0/nixos-grub-themes";

    bcompare5 = {
      url = "github:W4T4r/nix-bcompare5";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-hazkey = {
      url = "github:aster-void/nix-hazkey";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    globalprotect-openconnect.url = "github:yuezk/GlobalProtect-openconnect";

  };

  outputs = inputs@{ self, nixpkgs, home-manager, bcompare5, ... }:
  let
    user = import ./lib/user.nix;
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in
  {

    nixosConfigurations = {
      ${user.hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { 
          inherit inputs user;
        };
        modules = [
          ./nixos/configuration.nix
        ];
      }; 
    };

    homeConfigurations.${user.name} = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { 
        inherit inputs user;
      };
      modules = [
        ./home-manager/home.nix
        bcompare5.homeManagerModules.default
      ]; 
    };
  };
}
