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

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    bcompare5,
    ...
  }: let
    lib = nixpkgs.lib;
    user = import ./lib/user.nix;
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    nixFiles = [
      "flake.nix"
      "user.nix"
      "lib/user.nix"
      "nixos/configuration.nix"
      "nixos/hardware-configuration.nix"
      "nixos/modules/core.nix"
      "nixos/modules/boot.nix"
      "nixos/modules/desktop.nix"
      "nixos/modules/services.nix"
      "nixos/modules/packages.nix"
      "nixos/modules/virtualization.nix"
      "home-manager/home.nix"
      "home-manager/modules/core.nix"
      "home-manager/modules/programs.nix"
      "home-manager/modules/services.nix"
      "home-manager/modules/fonts.nix"
      "home-manager/modules/packages/minimal.nix"
      "home-manager/modules/packages/full.nix"
      "home-manager/modules/packages/personal.nix"
    ];
    shellFiles = [
      "install.sh"
      "scripts/bootstrap.sh"
      "scripts/configure-local.sh"
      "scripts/configure-niri-outputs.sh"
      "scripts/configure-displays.sh"
      "scripts/setup.sh"
      "scripts/forge.sh"
      "scripts/mn.sh"
      "scripts/rollback.sh"
      "scripts/tune.sh"
      "scripts/prune-backups.sh"
      "scripts/fix-script-permissions.sh"
      "scripts/lib/display-config.sh"
    ];
  in {
    formatter.${system} = pkgs.alejandra;

    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        actionlint
        alejandra
        deadnix
        shellcheck
        statix
      ];

      shellHook = ''
        echo "MD4N validation shell"
        echo "Available tools: alejandra, shellcheck, statix, deadnix, actionlint"
      '';
    };

    checks.${system} = {
      nix-format =
        pkgs.runCommand "md4n-nix-format-check"
        {
          nativeBuildInputs = [pkgs.alejandra];
        }
        ''
          cd ${self}
          alejandra --check ${lib.escapeShellArgs nixFiles}
          touch "$out"
        '';

      shellcheck =
        pkgs.runCommand "md4n-shellcheck"
        {
          nativeBuildInputs = [pkgs.shellcheck];
        }
        ''
          cd ${self}
          shellcheck -S warning ${lib.escapeShellArgs shellFiles}
          touch "$out"
        '';
    };

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
