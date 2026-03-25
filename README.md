<!--
███╗   ███╗██████╗ ██╗  ██╗███╗   ██╗
████╗ ████║██╔══██╗██║  ██║████╗  ██║
██╔████╔██║██║  ██║███████║██╔██╗ ██║
██║╚██╔╝██║██║  ██║╚════██║██║╚██╗██║
██║ ╚═╝ ██║██████╔╝     ██║██║ ╚████║
╚═╝     ╚═╝╚═════╝      ╚═╝╚═╝  ╚═══╝
-->

# MD4N: My Dotfiles for NixOS

[![NixOS](https://img.shields.io/badge/NixOS-unstable-5277C3?logo=nixos&logoColor=white)](https://nixos.org)
[![Home Manager](https://img.shields.io/badge/Home_Manager-enabled-3FB950?logo=nixos&logoColor=white)](https://github.com/nix-community/home-manager)
[![Wayland](https://img.shields.io/badge/Session-Wayland-00A3FF?logo=wayland&logoColor=white)](https://wayland.freedesktop.org)
[![WM](https://img.shields.io/badge/WM-Niri-7C4DFF)](https://github.com/YaLTeR/niri)
[![Theme](https://img.shields.io/badge/Theme-Catppuccin-F5E0DC?logo=catppuccin&logoColor=white)](https://github.com/catppuccin/catppuccin)

MD4N is a modular NixOS + Home Manager setup built around Niri, Noctalia, and a script-driven workflow.
This top-level README is the operator guide: how to install it, regenerate machine-local state, apply changes, and find the detailed documentation for each part of the repository.

## Before You Start

- This repository targets NixOS on `x86_64-linux`.
- Shared defaults live in [user.nix](user.nix).
- Machine-local answers are generated into `user.local.nix` by [scripts/setup.sh](scripts/setup.sh).
- Generated local state should be regenerated through the scripts, not hand-edited.

## Quick Start

Clone the repository and run the entrypoint:

```bash
git clone https://github.com/W4T4r/MD4N
cd MD4N
bash install.sh
```

The normal flow is:

1. [install.sh](install.sh)
2. [scripts/bootstrap.sh](scripts/bootstrap.sh)
3. [scripts/setup.sh](scripts/setup.sh)
4. [scripts/forge.sh](scripts/forge.sh)

## Daily Use

Use the script layer instead of raw commands whenever possible.

- Open the main console with [scripts/mn.sh](scripts/mn.sh)
- Apply changes with [scripts/forge.sh](scripts/forge.sh)
- Roll back with [scripts/rollback.sh](scripts/rollback.sh)
- Clean up and maintain generations with [scripts/tune.sh](scripts/tune.sh)

If you need to change machine-local answers later, re-run [scripts/setup.sh](scripts/setup.sh) and then apply again.

## Setup Behavior

During setup, MD4N can run in guided mode or automatic mode.

- Guided mode asks for identity, locale, time zone, hostname, package profile, virtualization, GPU vendor, browser choice, fingerprint support, dual-boot support, hibernate support, and profile-specific package choices.
- Automatic mode keeps the main machine-detection path and only asks for the choices that still need operator input.
- The selected package profile drives both NixOS and Home Manager behavior.

Current profiles:

- `minimal`: lighter baseline with virtualization disabled
- `full`: default workstation profile
- `custom`: interactive profile built from prompt-by-prompt choices
- `max`: author's all-in preset after explicit confirmation

## Updating Your Fork

If you maintain your own copy, keep reusable changes in Git and keep secrets or machine-local state out of Git.

Typical fork workflow:

```bash
git clone git@github.com:<your-name>/MD4N.git
cd MD4N
git remote add upstream https://github.com/W4T4r/MD4N.git
git fetch upstream
git rebase upstream/main
git push origin main
```

When moving to another machine or changing local answers, regenerate the local state with [scripts/setup.sh](scripts/setup.sh) instead of editing `user.local.nix` manually.

## Repository Guide

Use these documents when you want the detailed explanation for each area:

- [NixOS Overview](nixos/README.md): system-level structure, entrypoints, and module ownership
- [NixOS Modules](nixos/modules/README.md): what each system module is responsible for
- [Home Manager Overview](home-manager/README.md): user-level structure and how files are linked into the home directory
- [Home Manager Modules](home-manager/modules/README.md): core, programs, services, fonts, and package layering
- [Home Manager Package Profiles](home-manager/modules/packages/README.md): the role of `minimal`, `full`, `custom`, and `max`
- [Shared Config Tree](home-manager/config/README.md): what belongs under the repository-managed config tree
- [Desktop Entry Overrides](home-manager/applications/README.md): how `.desktop` overrides are organized
- [Wallpapers](home-manager/Wallpapers/README.md): wallpaper assets bundled with the setup
- [Scripts](scripts/README.md): install, apply, rollback, and maintenance workflow
- [Shared Nix Helpers](lib/README.md): how the merged `user` attribute set is built

## Important Files

- [flake.nix](flake.nix): flake entrypoint and outputs
- [user.nix](user.nix): repository-safe shared defaults
- [lib/user.nix](lib/user.nix): merge and normalization layer for user settings
- [nixos/configuration.nix](nixos/configuration.nix): stable NixOS entrypoint
- [home-manager/home.nix](home-manager/home.nix): stable Home Manager entrypoint

## Notes

- Wayland-first desktop centered on Niri and Noctalia
- Japanese input is configured around Fcitx5, Hazkey, and Mozc
- GNOME is present as a compatibility layer, not as the primary desktop
- The repository scripts are added to `PATH` through Home Manager
- Machine-local runtime helpers are generated under `~/.local/share/md4n/`

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
