{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    # Local-only licensed software belongs here, not in generated/user.nix.
    # inputs.globalprotect-openconnect.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
