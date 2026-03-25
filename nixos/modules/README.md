# Modules

This directory contains the NixOS modules imported by `../configuration.nix`.
Each file owns one part of the system so the top-level host definition stays readable and easy to change.

## Module Map

- `core.nix`
  Base operating system settings.
  This includes hostname, locale, time zone, user creation, shell selection, Nix feature flags, unfree package allowance, and suspend or hibernate behavior.
- `boot.nix`
  Bootloader and swap configuration.
  In the current setup this means GRUB on EFI systems, optional OS prober support for dual boot, and the shared swapfile definition.
- `desktop.nix`
  Desktop stack and multimedia plumbing.
  This enables Bluetooth, GDM on Wayland, Niri, Xwayland support, a trimmed GNOME environment, PipeWire, and RTKit.
- `services.nix`
  Service-backed features selected at the system level such as fingerprint support, printing, GVFS, input-remapper, Ollama, and Steam.
- `packages.nix`
  Shared system package selection, including GPU-aware packages and optional workstation tools.
- `virtualization.nix`
  Container and VM support for Podman, libvirt, SPICE USB redirection, and related virtualization plumbing.

## Design Intent

The repository uses generated user settings to decide which optional behavior should be active.
That means these modules should generally consume `user` flags rather than invent separate configuration switches unless a new shared concept is being introduced.

## Editing Guidance

Keep one responsibility per file.
If a change affects boot, desktop, and packages at once, prefer touching multiple focused modules instead of creating a catch-all file.
