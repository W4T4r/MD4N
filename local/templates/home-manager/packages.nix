{pkgs, ...}: {
  home.packages = with pkgs; [
    # Local-only packages that should stay out of generated/user.nix.
    # obs-studio
    # davinci-resolve
  ];
}
