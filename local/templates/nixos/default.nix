{lib, ...}: {
  imports =
    lib.optionals (builtins.pathExists ./hardware.nix) [./hardware.nix]
    ++ lib.optionals (builtins.pathExists ./swap.nix) [./swap.nix]
    ++ lib.optionals (builtins.pathExists ./packages.nix) [./packages.nix]
    ++ lib.optionals (builtins.pathExists ./services.nix) [./services.nix];
}
