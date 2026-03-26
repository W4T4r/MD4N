{
  description = "MD4N local entrypoint";

  inputs = {
    md4n.url = "path:__MD4N_ROOT__";

    # Add local-only flake inputs here.
  };

  outputs = inputs @ {md4n, ...}: let
    generatedUserPath = ./generated/user.nix;
    extraHomeModulesPath = ./home-manager/extra-modules.nix;
    extraNixosModulesPath = ./nixos/extra-modules.nix;
    user =
      if builtins.pathExists generatedUserPath
      then import generatedUserPath
      else import ../user.nix;
    extraInputs = builtins.removeAttrs inputs ["self" "md4n"];
    extraHomeModules =
      if builtins.pathExists extraHomeModulesPath
      then import extraHomeModulesPath {inherit inputs user;}
      else [];
    extraNixosModules =
      if builtins.pathExists extraNixosModulesPath
      then import extraNixosModulesPath {inherit inputs user;}
      else [];
  in {
    inherit (md4n) checks devShells formatter;

    nixosConfigurations.${user.hostname} = md4n.lib.mkNixosConfiguration {
      inherit user;
      extraInputs = extraInputs;
      extraSpecialArgs = {
        shared = md4n;
      };
      extraModules =
        [
          ./nixos/default.nix
        ]
        ++ extraNixosModules;
    };

    homeConfigurations.${user.name} = md4n.lib.mkHomeConfiguration {
      inherit user;
      extraInputs = extraInputs;
      extraSpecialArgs = {
        shared = md4n;
      };
      extraModules =
        [
          ./home-manager/default.nix
        ]
        ++ extraHomeModules;
    };
  };
}
