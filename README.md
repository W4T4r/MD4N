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

**MD4N** is a modular NixOS + Home Manager configuration centered around the **Niri** scrollable tiling window manager. It uses a script-driven workflow for installation, rebuilds, rollback, and maintenance, while keeping shared defaults in `user.nix` and personal machine-specific values in `user.local.nix`.

---

## 🌟 Highlights

- 🌌 **Niri WM**: A Wayland-first setup built around Niri and Noctalia Shell.
- 🧩 **Modular Layout**: `configuration.nix` and `home.nix` stay as stable entrypoints while internal modules split system, services, programs, fonts, and package profiles.
- 👤 **Private Local Overrides**: Setup writes hostname, locale, timezone, Git identity, package profile, virtualization preference, GPU vendor, dual-boot support, hibernate preference, and optional personal font settings into `user.local.nix`, which stays out of Git.
- 📦 **Profile-Aware Packages**: `minimal`, `full`, `custom`, and `max` profiles are selected in setup and loaded internally by Home Manager and NixOS modules.
- 🎛️ **Guided Package Selection**: `full` asks about less-common apps one by one, `custom` asks one by one about everything outside the minimal baseline, and `max` applies the author's all-in preset after an explicit confirmation.
- 🖥️ **GPU-Aware Defaults**: AMD systems use ROCm variants such as `btop-rocm` and `ollama-rocm`; other systems fall back to the generic packages.
- ⌨️ **Japanese Input Ready**: Fcitx5 is configured with both Hazkey and Mozc.
- 📁 **Dual File Tools**: Nemo is the graphical file manager, while Yazi covers terminal workflows.
- 🛠️ **Console Workflow**: `install`, `bootstrap`, `setup`, `mn`, `forge`, `rollback`, and `tune` provide an opinionated flow on top of raw Nix commands.

---

## 🧱 Technical Stack

| Category | Component |
| --- | --- |
| **OS** | NixOS (Unstable) |
| **Window Manager** | [Niri](https://github.com/YaLTeR/niri) |
| **Shell / Bar** | [Noctalia Shell](https://github.com/noctalia-dev/noctalia-shell) |
| **Terminal** | Kitty + Alacritty |
| **Shell** | Fish + Starship Prompt |
| **File Manager** | Nemo + Yazi |
| **Editor** | Neovim ([NvChad](https://nvchad.com/) via Nix4NvChad) |
| **Input Method** | Fcitx5 (Hazkey / Mozc) |
| **Virtualization** | Podman, Libvirt, Distrobox (`full` / `custom` / `max`) |
| **AI / Dev Tools** | Codex, Claude Code, Gemini CLI |

---

## 🔧 Configuration Philosophy

MD4N keeps the flake entrypoints stable and separates shared defaults from local machine choices.

- **`flake.nix`**: Always points at [nixos/configuration.nix](/home/donghang/Documents/MD4N/nixos/configuration.nix) and [home-manager/home.nix](/home/donghang/Documents/MD4N/home-manager/home.nix).
- **`user.nix`**: Repository-safe defaults that can be shared publicly.
- **`user.local.nix`**: Generated during setup. It stores username, full name, hostname, locale, timezone, Git name/email, package profile, custom-font opt-in, virtualization preference, GPU vendor, dual-boot support, hibernate preference, and derived paths.
- **`nixos/`**: System-level modules for core settings, boot, desktop, services, packages, and virtualization support that can be toggled in setup.
- **`home-manager/`**: User-level modules for core dotfiles, programs, services, optional fonts, and profile-specific package sets.
- **`scripts/`**: Interactive bash consoles and bootstrap helpers that wrap common Nix operations.

The package profile affects both layers:

- **`minimal`**: Lighter package set. Virtualization is off, `texliveFull` and `globalprotect-openconnect` stay out, and the extra desktop/dev tools are disabled.
- **`full`**: Default workstation profile. Uses the fuller package set and asks about less-common apps individually.
- **`custom`**: Starts from the minimal baseline and asks one by one about the extra apps and services from the fuller profiles, including optional virtualization helpers.
- **`max`**: The repository author's personal all-in profile. It enables the broad package and service set after an explicit confirmation and should be assumed to include many tools you probably do not need.

Virtualization can still be disabled independently during setup for non-`minimal` profiles.

---

## 🚀 Getting Started

### 1. Installation

Clone the repository and run the installer:

```bash
git clone https://github.com/W4T4r/MD4N
cd MD4N
bash install.sh
```

The install flow is:
1. `install.sh`: entrypoint and cleanup.
2. `scripts/bootstrap.sh`: verifies `bash`, `sudo`, and `nix`, and enables `nix-command` / `flakes` if needed.
3. `scripts/setup.sh`: generates or updates `user.local.nix`, writes the Fish PATH helper, and can run in automatic or guided mode.
4. `scripts/forge.sh`: applies the resulting NixOS and/or Home Manager configuration.

During setup, MD4N can run in either guided mode or automatic mode.

- **Guided mode** asks for the full machine/user configuration:
  Full name, locale, time zone, hostname, Git author name/email, package profile, custom font preferences, virtualization preference, GPU vendor, fingerprint auth, dual-boot support, and hibernate preference.
- **Automatic mode** skips the identity and machine-detail prompts:
  It uses detected/default values for full name, locale, time zone, hostname, Git identity, GPU vendor, fingerprint auth, and dual-boot/hibernate.
  It still asks about the package profile, virtualization, and profile-specific optional packages.
- **`full` profile prompts**:
  Beyond Compare 5, Google Chrome, Thunderbird, OBS Studio, DaVinci Resolve, Zotero, Podman Desktop, Distrobox, Distroshelf, TeX Live Full, GlobalProtect OpenConnect, and virt-manager.
- **`custom` profile prompts**:
  Beyond Compare 5, Vesktop, CAVA, Gemini CLI, Codex, Claude Code, Google Chrome, Thunderbird, OBS Studio, DaVinci Resolve, Zotero, Ollama, Steam, TeX Live Full, GlobalProtect OpenConnect, and virtualization helpers.
- **`max` profile behavior**:
  Setup asks for explicit confirmation because it is the author's personal setup, then enables the broad package/service set and skips the remaining optional package prompts.
- **Virtualization note**:
  Podman/Desktop, Distrobox, Distroshelf, and virt-manager prompts are skipped automatically when virtualization is disabled.
- **Google Chrome note**:
  When you log in with `fprintd`, Chrome may still ask for your password in some cases.
- **GPU detection**:
  Auto-detection prefers `/sys/class/drm` PCI vendor IDs and falls back to `lspci`; you can still override it manually in guided mode.
- **Fingerprint note**:
  When fingerprint authentication is enabled, setup can launch `fprintd-enroll <username>` after applying the configuration.
- **Dependency fallback**:
  When setup dependencies such as `git` or `lspci` are missing from `PATH`, the script can fall back to temporary `nix shell` commands when `nix` is available.

---

## 🛠️ Command Center

MD4N provides shell wrappers so you do not need to remember the longer `nixos-rebuild`, `home-manager`, or generation-management commands. The console tools use a consistent `fzf` interface with `j/k` for navigation and `q` to go back.

### 🎮 `mn.sh` - The Control Center
The main hub for daily use. It launches `forge`, `rollback`, or `tune`.

```bash
mn.sh
```

### ⚒️ `forge.sh` - The Apply Tool
Applies NixOS and/or Home Manager from this repository.

```bash
forge.sh [options]
```
- `--all`: Apply both NixOS and Home Manager.
- `--os`: Apply only the NixOS system configuration.
- `--home`: Apply only the Home Manager user configuration.
- `--update`: Update `flake.lock` before applying.
- `--no-backup`: Disable the `md4nbak` backup suffix for Home Manager.

### ⏪ `rollback.sh` - The Rollback Tool
Interactively switch to an earlier NixOS or Home Manager generation.

```bash
rollback.sh
```
- `os`: Roll back the system profile.
- `home`: Roll back the Home Manager profile.

### 🧹 `tune.sh` - The Maintenance Tool
Interactive maintenance for generations and the Nix store.

```bash
tune.sh
```
- `system`: Delete selected system generations.
- `user`: Delete selected user profile generations.
- `home`: Delete selected Home Manager generations.
- `opt`: Run garbage collection, deduplication, or both.
- `clean`: Run `nix-collect-garbage --delete-older-than 7d`, expire Home Manager generations older than 7 days, and optimize the store.

### 🧱 `bootstrap.sh` and `setup.sh`
These are usually called by `install.sh`, but can also be run directly during debugging or iterative setup work.

- `bootstrap.sh`: Ensures Nix prerequisites and launches setup.
- `setup.sh`: Regenerates `user.local.nix` and the Fish PATH helper, and can optionally call `forge.sh` at the end.

---

## 🗂️ Repository Layout

```text
.
├── flake.nix                        # Flake entrypoint
├── user.nix                         # Generated machine/user settings
├── nixos/
│   ├── configuration.nix            # Stable NixOS entrypoint
│   ├── hardware-configuration.nix   # Hardware config
│   └── modules/                     # Core, boot, desktop, services, packages, virtualization
├── home-manager/
│   ├── home.nix                     # Stable Home Manager entrypoint
│   ├── modules/                     # Core, programs, services, fonts, package profiles
│   ├── config/                      # App configs (Niri, Fish, Fcitx5, Noctalia, Yazi, etc.)
│   ├── applications/                # Desktop entry overrides
│   └── Wallpapers/                  # Wallpaper assets
└── scripts/                         # install/bootstrap/setup and console tools
```

---

## 📝 Notes

- **Target**: Currently wired for `x86_64-linux`.
- **Display**: Wayland-first desktop built around Niri.
- **Fonts**: Personal font choices are opt-in and intentionally separated from the shared baseline.
- **Scripts**: `setup.sh` writes [home-manager/config/fish/conf.d/md4n-env.fish](/home/donghang/Documents/MD4N/home-manager/config/fish/conf.d/md4n-env.fish) so the repository's `scripts/` directory is added to Fish `PATH`.

## 📄 License

This project is licensed under the MIT License.
