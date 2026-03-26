# Scripts

This directory contains the operational interface for MD4N.
Instead of expecting the user to remember raw `nixos-rebuild`, `home-manager`, generation rollback, or cleanup commands, MD4N wraps those workflows in scripts with a consistent console style.

## Main Flow

- `install.sh`
  Repository entrypoint. Starts the normal install chain, previews the local targets, and forwards into the interactive local setup flow.
- `bootstrap.sh`
  Pre-flight stage that reviews the local targets, checks whether the machine can proceed into local configuration, enables flakes when needed, and then launches the interactive local setup.
- `configure-local.sh`
  Main local-configuration console.
  It collects machine-local answers, generates `local/generated/user.nix`, ensures the local flake scaffold exists, writes helper files such as the browser launcher and Fish environment file, calls the dedicated Niri output generator, and can immediately apply the result through `local/flake.nix` when present.

## Daily Operation

- `mn.sh`
  Top-level menu that launches the local-configuration, display, apply, rollback, and maintenance consoles.
- `configure-local.sh`
  Regenerates machine-local answers and helper files.
- `configure-niri-outputs.sh`
  Regenerates Niri display outputs in place.
- `forge.sh`
  Applies NixOS and or Home Manager changes from the active flake entrypoint, preferring `local/flake.nix` over the shared root flake. When `--update` is used, it refreshes the shared root lock and the local lock when present.
- `rollback.sh`
  Switches to an earlier NixOS or Home Manager generation.
- `tune.sh`
  Handles maintenance tasks such as cleanup, garbage collection, and generation pruning.

## Supporting Helpers

- `configure-displays.sh`
  Compatibility alias that forwards to `configure-niri-outputs.sh`.
- `fix-script-permissions.sh`
  Ensures the script directory has consistent executable bits.
- `prune-backups.sh`
  Cleans up stale Home Manager backup files.
- `setup.sh`
  Compatibility alias that forwards to `configure-local.sh`.

## Expected Usage

These scripts are meant to be the supported operator interface for this repository.
If a machine-local choice changes, the preferred path is usually to re-run `configure-local.sh` and then apply with `forge.sh` or `mn.sh`, not to hand-edit generated local files.
