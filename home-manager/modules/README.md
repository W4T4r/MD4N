# Modules

This directory contains the Home Manager modules imported by `../home.nix`.
These modules are the main composition layer for the user environment and are intended to keep `home.nix` readable and stable.

## Layout

- `core.nix`
  Base Home Manager wiring such as username, home directory, XDG file placement, wallpaper installation, input method setup, cursor configuration, and activation hooks.
- `programs.nix`
  User-facing programs and program modules such as Git, Kitty, Starship, direnv, GitUI, and NvChad.
- `services.nix`
  User-space services such as `gnome-keyring` and Hazkey integration.
- `fonts.nix`
  Shared font wiring for the repository-managed GTK and Fcitx font files when `user.enableLocalFonts` enables the feature.
- `packages/`
  Profile-specific package lists for `minimal` and `full`.

## Design Notes

These modules consume the `user` attribute set passed in by the active flake entrypoint.
That value can come from shared defaults alone or from the optional merge layer in [`lib/user.nix`](../../lib/user.nix).

Keep modules focused. If a file starts mixing XDG links, package selection, and service toggles all at once, it probably wants to be split further.
