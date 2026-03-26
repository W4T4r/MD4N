{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Add machine-local NixOS packages here.
  ];
}
