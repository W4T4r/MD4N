# Package Profiles

This directory holds the Home Manager package layers selected by `user.packageProfile`.
The profile is chosen during `scripts/setup.sh` and then imported by `home.nix`.

## Profiles

- `minimal.nix`
  Baseline user package set with a lighter footprint.
- `full.nix`
  Default workstation-oriented package set.
- `custom.nix`
  Starts from the lighter baseline and adds packages based on the interactive answers collected during setup.
- `w4t4r.nix`
  Personal all-in profile with a broad package set enabled by design.

## Why This Exists

Splitting profile-specific packages out of the main module layer keeps the rest of Home Manager logic stable.
It also makes it easier to reason about package changes without digging through unrelated shell, desktop, or service config.

## Editing Guidance

Use this directory for package selection only.
If a change needs extra config files, service options, or activation logic, place that behavior in another module and gate it with the same user setting rather than overloading the package profile file.
