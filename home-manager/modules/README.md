# Modules

This directory contains the Home Manager modules imported by `../home.nix`.
These modules are the main composition layer for the user environment and are intended to keep `home.nix` readable and stable.

## Layout

- `core.nix`
  Base Home Manager wiring such as username, home directory, XDG file placement, wallpaper installation, input method setup, cursor configuration, and activation hooks.
- `programs.nix`
  User-facing programs and program modules such as Git, Kitty, Starship, direnv, GitUI, Beyond Compare 5, and NvChad.
- `services.nix`
  User-space services such as `gnome-keyring` and Hazkey integration.
- `fonts.nix`
  Optional W4T4r personal font defaults enabled only when the generated local settings opt into that personal font module.
- `packages/`
  Profile-specific package lists for `minimal`, `full`, `custom`, and `max`.

## Design Notes

These modules are driven by the merged `user` attribute set built in [`lib/user.nix`](../../lib/user.nix).
That means feature gates should usually depend on generated user settings rather than on ad hoc local edits.

Keep modules focused. If a file starts mixing XDG links, package selection, and service toggles all at once, it probably wants to be split further.
