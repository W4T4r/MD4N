# Editing Guide

Use this guide when you know what you want to change, but are not sure which tree owns it.

## Source Of Truth

- Shared defaults for every machine:
  edit `MD4N/` in files such as `user.nix`, `nixos/modules/*`, `home-manager/modules/*`, and shared config under `home-manager/config/`.
- Generated machine answers:
  re-run `bash ./scripts/configure-local.sh` or `bash ./scripts/mn.sh` -> `local`.
  Do not hand-edit `local/generated/user.nix`.
- Machine-local Nix modules and private flake inputs:
  keep them in `MD4N/local/` if you are working without a private repo, or in `MD4N-private/<machine>/local/` if you are using the private workflow.
- Machine-local runtime files that apps edit in place:
  keep them in `MD4N-private/<machine>/home-manager/`.
  After linking, the runtime path inside `MD4N/home-manager/config/` points back to the private file.

## Edit Here When

- You want the change on every machine:
  edit the shared `MD4N/` module or shared config file.
- You want to change setup answers such as hostname, locale, package profile, browser, or GPU vendor:
  regenerate with `configure-local.sh`.
- You want a machine-only package, module, or flake input:
  edit `local/nixos/*.nix`, `local/home-manager/*.nix`, or the equivalent path in `MD4N-private/<machine>/local/`.
- You want a machine-only Niri override:
  edit `MD4N-private/<machine>/home-manager/niri/config.local.kdl` or `local/*.local.kdl`.
- You want shared Niri behavior:
  edit tracked files in `MD4N/home-manager/config/niri/`.
- You want machine-only Fish snippets, custom GTK/Fcitx font UI overrides, or browser launcher helpers:
  edit `MD4N-private/<machine>/home-manager/fish/`, `custom-fonts/`, or `niri/browser.sh`.

## Day-To-Day Flows

- Shared Nix change:
  edit `MD4N/`, then run `bash ./scripts/mn.sh` and apply with `forge`.
- Machine-answer change:
  run `bash ./scripts/mn.sh`, choose `local`, then apply with `forge`.
- Private runtime change:
  edit the file in `MD4N-private/<machine>/home-manager/`, run `bash ./link-md4n.sh --machine <machine>` if needed, then return to `MD4N/` and use `mn.sh`.
- Display topology refresh:
  run `bash ./scripts/mn.sh`, choose `display`, then apply if needed.

## Do Not Treat These As Hand-Maintained

- `local/generated/user.nix`
  generated output from `configure-local.sh`
- `local_templates/`
  starter content for new local trees, not the live runtime tree
- `private_templates/MD4N-private/`
  starter content for new private repos, not the long-term private source of truth
- `home-manager/config/niri/outputs.kdl`
  generated display topology; re-run `configure-niri-outputs.sh` instead of curating it manually
