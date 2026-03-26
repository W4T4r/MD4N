# NixOS

This directory contains the system-level half of MD4N.
It is responsible for host configuration such as boot, users, services, desktop stack, system packages, and virtualization support.

## Structure

- `configuration.nix`
  Stable NixOS entrypoint used by the flake output.
  Its job is mainly to import the internal shared modules and decide whether optional pieces such as virtualization should be included.
- `hardware-configuration.nix`
  Shared fallback hardware definition kept for compatibility and template seeding.
  The active local entrypoint can instead import `local/nixos/hardware.nix`.
- `modules/`
  System modules split by responsibility so the entrypoint can stay thin.

## How It Connects To The Rest Of The Repo

`flake.nix` exports the shared NixOS modules plus a default configuration keyed by the shared default hostname.
The local operational flake can consume those shared modules and add machine-specific imports such as `local/nixos/hardware.nix` and `local/nixos/swap.nix`.

## Editing Guidance

Keep reusable system behavior inside `modules/`.
Try not to pile policy directly into `configuration.nix` unless it truly belongs at the top-level composition layer.
