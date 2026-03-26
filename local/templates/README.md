# Local Templates

Copy the files you need from this directory into `local/` and edit them there.

The dependency direction stays one-way:

- `local/flake.nix` imports the shared root flake.
- The shared root flake does not import `local/`.

- `flake.nix`
  Local operational flake that wraps the shared root flake and accepts extra inputs.
  `configure-local.sh` renders the live copy with the current repository path.
- `nixos/`
  Local NixOS modules such as hardware, swap, packages, and services.
- `home-manager/`
  Local Home Manager modules such as packages, programs, services, and fonts.
