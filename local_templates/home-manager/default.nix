{
  lib,
  user,
  ...
}: {
  imports =
    lib.optionals (builtins.pathExists ./packages.nix) [./packages.nix]
    ++ lib.optionals (builtins.pathExists ./programs.nix) [./programs.nix]
    ++ lib.optionals (builtins.pathExists ./services.nix) [./services.nix]
    ++ lib.optionals ((user.enableLocalFonts or false) && builtins.pathExists ./fonts.nix) [./fonts.nix];
}
