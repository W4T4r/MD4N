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
[![CI](https://github.com/W4T4r/MD4N/actions/workflows/ci.yml/badge.svg)](https://github.com/W4T4r/MD4N/actions/workflows/ci.yml)
[![Wayland](https://img.shields.io/badge/Session-Wayland-00A3FF?logo=wayland&logoColor=white)](https://wayland.freedesktop.org)
[![WM](https://img.shields.io/badge/WM-Niri-7C4DFF)](https://github.com/YaLTeR/niri)
[![Theme](https://img.shields.io/badge/Theme-Catppuccin-F5E0DC?logo=catppuccin&logoColor=white)](https://github.com/catppuccin/catppuccin)

MD4N is a modular NixOS + Home Manager setup built around Niri, Noctalia, and a script-driven workflow.
This top-level README is the operator guide: how to install it, regenerate machine-local state, apply changes, and find the detailed documentation for each part of the repository.

## Preview

| Launcher | Settings |
| --- | --- |
| [![Launcher](assets/screenshots/launcher-overview.png)](assets/screenshots/launcher-overview.png) | [![Settings](assets/screenshots/settings-overview.png)](assets/screenshots/settings-overview.png) |

## Before You Start

- This repository targets NixOS on `x86_64-linux`.
- Shared defaults live in [user.nix](user.nix).
- Machine-local answers are generated into `user.local.nix` by [scripts/setup.sh](scripts/setup.sh).
- Generated local state should be regenerated through the scripts, not hand-edited.
- `direnv` users can run `direnv allow` in the repository root to load the local validation toolchain automatically.

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

For input methods, the shared setup now keeps Japanese input on Fcitx5 through
Hazkey and Mozc, and Simplified Chinese input on Fcitx5 through Rime.
The detailed Fcitx5 and Rime layout is documented in
[home-manager/config/fcitx5/README.md](home-manager/config/fcitx5/README.md).

## Local Validation

If you use `direnv`, run `direnv allow` once in the repository root.
That loads the flake dev shell with local validation tools such as `alejandra`, `shellcheck`, `statix`, `deadnix`, and `actionlint`.

The main validation entrypoint remains:

```bash
nix flake check
```

## Setup Behavior

During setup, MD4N can run in guided mode or automatic mode.

- Guided mode asks for identity, locale, time zone, hostname, package profile, virtualization, GPU vendor, browser choice, fingerprint support, dual-boot support, hibernate support, and profile-specific package choices.
- Automatic mode keeps the main machine-detection path and only asks for the choices that still need operator input.
- The selected package profile drives both NixOS and Home Manager behavior.

Current profiles:

- `minimal`: lighter baseline with virtualization disabled
- `full`: default workstation profile
- `custom`: interactive profile built from prompt-by-prompt choices
- `w4t4r`: personal all-in preset after explicit confirmation

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

If you fork this repository and want to rename the personal profile for your own use, change these places together:

- [scripts/setup.sh](scripts/setup.sh)
  Update `USER_PACKAGE_PROFILE` near the top of the script. The setup prompts and profile comparisons use that variable instead of hard-coded string checks.
- [home-manager/home.nix](home-manager/home.nix)
  Update `userPackageProfile` so Home Manager imports your renamed personal package layer.
- [home-manager/modules/packages/w4t4r.nix](home-manager/modules/packages/w4t4r.nix)
  Rename the file to match your profile name.
- [README.md](README.md) and [home-manager/modules/packages/README.md](home-manager/modules/packages/README.md)
  Update the displayed profile name in the docs.

If you also want to rename the personal font toggle, update:

- [user.nix](user.nix)
  Rename `enableW4T4rFonts`.
- [scripts/setup.sh](scripts/setup.sh)
  Rename the generated field and prompt text.
- [home-manager/home.nix](home-manager/home.nix)
  Update the condition that decides when to import [fonts.nix](home-manager/modules/fonts.nix).

## Repository Guide

Use these documents when you want the detailed explanation for each area:

- [NixOS Overview](nixos/README.md): system-level structure, entrypoints, and module ownership
- [NixOS Modules](nixos/modules/README.md): what each system module is responsible for
- [Home Manager Overview](home-manager/README.md): user-level structure and how files are linked into the home directory
- [Home Manager Modules](home-manager/modules/README.md): core, programs, services, fonts, and package layering
- [Home Manager Package Profiles](home-manager/modules/packages/README.md): the role of `minimal`, `full`, `custom`, and `w4t4r`
- [Shared Config Tree](home-manager/config/README.md): what belongs under the repository-managed config tree
- [Fcitx5 and Rime](home-manager/config/fcitx5/README.md): Japanese and Chinese input layout, shared profile, and Rime deployment
- [Desktop Entry Overrides](home-manager/applications/README.md): how `.desktop` overrides are organized
- [Wallpapers](home-manager/Wallpapers/README.md): wallpaper assets bundled with the setup
- [Scripts](scripts/README.md): install, apply, rollback, and maintenance workflow
- [Shared Nix Helpers](lib/README.md): how the merged `user` attribute set is built
- [Documentation Assets](assets/README.md): screenshots and other repository-owned media
- [Troubleshooting](docs/troubleshooting.md): common install, setup, and apply failures
- [Third-Party Notices](THIRD_PARTY_NOTICES.md): bundled assets that carry upstream attribution or license requirements

## Important Files

- [flake.nix](flake.nix): flake entrypoint and outputs
- [user.nix](user.nix): repository-safe shared defaults
- [lib/user.nix](lib/user.nix): merge and normalization layer for user settings
- [nixos/configuration.nix](nixos/configuration.nix): stable NixOS entrypoint
- [home-manager/home.nix](home-manager/home.nix): stable Home Manager entrypoint

## Notes

- Wayland-first desktop centered on Niri and Noctalia
- Input methods are configured around Fcitx5, with Hazkey and Mozc for Japanese and Rime for Simplified Chinese
- GNOME is present as a compatibility layer, not as the primary desktop
- The repository scripts are added to `PATH` through Home Manager
- Machine-local Niri helpers are generated into the linked `home-manager/config/niri/` directory and appear at `~/.config/niri/`

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
