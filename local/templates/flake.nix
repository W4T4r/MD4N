{
  description = "MD4N local entrypoint";

  inputs = {
    md4n.url = "path:__MD4N_ROOT__";
    bcompare5 = {
      url = "github:W4T4r/nix-bcompare5";
      inputs.nixpkgs.follows = "md4n/nixpkgs";
    };
    globalprotect-openconnect.url = "github:yuezk/GlobalProtect-openconnect";
  };

  outputs = inputs @ {md4n, ...}: let
    generatedUserPath = ./generated/user.nix;
    user =
      if builtins.pathExists generatedUserPath
      then import generatedUserPath
      else import ../user.nix;
    extraInputs = builtins.removeAttrs inputs ["self" "md4n"];
  in {
    inherit (md4n) checks devShells formatter;

    nixosConfigurations.${user.hostname} = md4n.lib.mkNixosConfiguration {
      inherit user;
      extraInputs = extraInputs;
      extraSpecialArgs = {
        shared = md4n;
      };
      extraModules = [
        ./nixos/default.nix
      ];
    };

    homeConfigurations.${user.name} = md4n.lib.mkHomeConfiguration {
      inherit user;
      extraInputs = extraInputs;
      extraSpecialArgs = {
        shared = md4n;
      };
      extraModules = [
        ./home-manager/default.nix
        inputs.bcompare5.homeManagerModules.default
      ];
    };
  };
}
