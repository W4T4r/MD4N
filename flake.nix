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

    nix-hazkey = {
      url = "github:aster-void/nix-hazkey";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    ...
  }: let
    nixLib = nixpkgs.lib;
    defaultSystem = "x86_64-linux";
    defaultUser = import ./user.nix;
    mkPkgs = system: import nixpkgs {inherit system;};
    mergeInputs = extraInputs: inputs // extraInputs;
    mkNixosConfiguration = {
      system ? defaultSystem,
      user ? defaultUser,
      extraInputs ? {},
      extraModules ? [],
      extraSpecialArgs ? {},
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs =
          {
            inputs = mergeInputs extraInputs;
            inherit user;
          }
          // extraSpecialArgs;
        modules =
          [
            ./nixos/configuration.nix
          ]
          ++ extraModules;
      };
    mkHomeConfiguration = {
      system ? defaultSystem,
      user ? defaultUser,
      extraInputs ? {},
      extraModules ? [],
      extraSpecialArgs ? {},
    }: let
      pkgs = mkPkgs system;
    in
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs =
          {
            inputs = mergeInputs extraInputs;
            inherit user;
          }
          // extraSpecialArgs;
        modules =
          [
            ./home-manager/home.nix
          ]
          ++ extraModules;
      };
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
      "local_templates/flake.nix"
      "local_templates/nixos/default.nix"
      "local_templates/nixos/extra-modules.nix"
      "local_templates/nixos/hardware.nix"
      "local_templates/nixos/packages.nix"
      "local_templates/nixos/services.nix"
      "local_templates/nixos/swap.nix"
      "local_templates/home-manager/default.nix"
      "local_templates/home-manager/extra-modules.nix"
      "local_templates/home-manager/packages.nix"
      "local_templates/home-manager/programs.nix"
      "local_templates/home-manager/services.nix"
      "local_templates/home-manager/fonts.nix"
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
    formatter.${defaultSystem} = (mkPkgs defaultSystem).alejandra;

    devShells.${defaultSystem}.default = (mkPkgs defaultSystem).mkShell {
      packages = with (mkPkgs defaultSystem); [
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

    checks.${defaultSystem} = {
      nix-format =
        (mkPkgs defaultSystem).runCommand "md4n-nix-format-check"
        {
          nativeBuildInputs = [(mkPkgs defaultSystem).alejandra];
        }
        ''
          cd ${self}
          alejandra --check ${nixLib.escapeShellArgs nixFiles}
          touch "$out"
        '';

      shellcheck =
        (mkPkgs defaultSystem).runCommand "md4n-shellcheck"
        {
          nativeBuildInputs = [(mkPkgs defaultSystem).shellcheck];
        }
        ''
          cd ${self}
          shellcheck -S warning ${nixLib.escapeShellArgs shellFiles}
          touch "$out"
        '';
    };

    lib = {
      inherit mkHomeConfiguration mkNixosConfiguration;
    };

    nixosModules = {
      configuration = ./nixos/configuration.nix;
      hardware = ./nixos/hardware-configuration.nix;
      core = ./nixos/modules/core.nix;
      boot = ./nixos/modules/boot.nix;
      desktop = ./nixos/modules/desktop.nix;
      services = ./nixos/modules/services.nix;
      packages = ./nixos/modules/packages.nix;
      virtualization = ./nixos/modules/virtualization.nix;
    };

    homeManagerModules = {
      home = ./home-manager/home.nix;
      core = ./home-manager/modules/core.nix;
      programs = ./home-manager/modules/programs.nix;
      services = ./home-manager/modules/services.nix;
      fonts = ./home-manager/modules/fonts.nix;
    };

    nixosConfigurations = {
      ${defaultUser.hostname} = mkNixosConfiguration {
        user = defaultUser;
        extraModules = [
          ./nixos/hardware-configuration.nix
        ];
      };
    };

    homeConfigurations.${defaultUser.name} = mkHomeConfiguration {user = defaultUser;};
  };
}
