# Scripts

This directory contains the operational interface for MD4N.
Instead of expecting the user to remember raw `nixos-rebuild`, `home-manager`, generation rollback, or cleanup commands, MD4N wraps those workflows in scripts with a consistent console style.

## Main Flow

- `install.sh`
  Repository entrypoint. Starts the normal install chain and cleans transient setup leftovers.
- `bootstrap.sh`
  Pre-flight stage that checks whether the machine can proceed into setup.
- `setup.sh`
  The most important script in the repository.
  It collects machine-local answers, generates `user.local.nix`, writes helper files such as the Niri outputs file and browser launcher, and can immediately apply the result.

## Daily Operation

- `mn.sh`
  Top-level menu that launches the other operational consoles.
- `forge.sh`
  Applies NixOS and or Home Manager changes from this repository.
- `rollback.sh`
  Switches to an earlier NixOS or Home Manager generation.
- `tune.sh`
  Handles maintenance tasks such as cleanup, garbage collection, and generation pruning.

## Supporting Helpers

- `fix-script-permissions.sh`
  Ensures the script directory has consistent executable bits.
- `prune-backups.sh`
  Cleans up stale Home Manager backup files.

## Expected Usage

These scripts are meant to be the supported operator interface for this repository.
If a machine-local choice changes, the preferred path is usually to re-run `setup.sh` and then apply with `forge.sh` or `mn.sh`, not to hand-edit generated local files.
