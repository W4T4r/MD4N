# NixOS

This directory contains the system-level half of MD4N.
It is responsible for host configuration such as boot, users, services, desktop stack, system packages, and virtualization support.

## Structure

- `configuration.nix`
  Stable NixOS entrypoint used by the flake output.
  Its job is mainly to import the internal modules and decide whether optional pieces such as virtualization should be included.
- `hardware-configuration.nix`
  Hardware-specific settings generated in the usual NixOS style.
  This is the one file in this tree that is expected to be strongly machine-specific.
- `modules/`
  System modules split by responsibility so the entrypoint can stay thin.

## How It Connects To The Rest Of The Repo

`flake.nix` exports a NixOS configuration keyed by the generated hostname.
That configuration imports `configuration.nix`, which then consumes the merged `user` settings from [`lib/user.nix`](../lib/user.nix).
In other words, this directory is where the machine-level answers collected during setup actually become system behavior.

## Editing Guidance

Keep reusable system behavior inside `modules/`.
Try not to pile policy directly into `configuration.nix` unless it truly belongs at the top-level composition layer.
