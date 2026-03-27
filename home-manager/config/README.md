# Config

This directory stores the shared application configuration that MD4N installs into the user's XDG config tree.
Most subdirectories map closely to `~/.config/<app>` and are linked into place through Home Manager.
Some linked trees such as `fish/`, `niri/`, and `custom-fonts/` intentionally allow a few ignored machine-local files to live beside the shared config.

## What You Will Find Here

- Shell and terminal config such as Fish, Starship, Alacritty, and Kitty-adjacent settings
- Desktop and UI config such as Niri, Noctalia, GTK, Kvantum, QT6CT, and xsettingsd
- Productivity and utility tool config such as Yazi, GitUI, Fastfetch, Btop, Cava, Clipse, and Nvtop
- Input method config such as Fcitx5 and Hazkey-related settings

## Shared vs Generated

This directory is for repository-managed, shareable config.
Generated machine-local files should not be committed here just because they eventually appear under `~/.config`.

Examples of files that stay outside the repo, or inside an explicitly reserved local slot:

- Display-topology-specific Niri output definitions generated as `outputs.kdl`
- Niri machine-local overrides kept in `config.local.kdl` or split into `local/*.local.kdl`
- Machine-local browser launch helpers
- Personal GTK or input-method font overrides
- Personal secrets or tokens
- Host-specific cache files

## Editing Guidance

Add config here when it should be reproducible across machines.
If a file depends on one machine's monitor layout, personal font set, or secret data, treat it as generated local state instead.
The main exceptions are small reserved local slots such as Niri's `outputs.kdl`, `config.local.kdl`, `local/`, or `custom-fonts/`, where the runtime file benefits from staying beside the linked shared config.
