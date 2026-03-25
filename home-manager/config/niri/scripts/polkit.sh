#!/usr/bin/env fish
# start polkit-gnome

set POLKIT_GNOME (nix eval --raw -f '<nixpkgs>' pkgs.polkit_gnome)

$POLKIT_GNOME/libexec/polkit-gnome-authentication-agent-1 &
