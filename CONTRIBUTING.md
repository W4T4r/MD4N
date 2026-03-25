# Contributing

## Scope

MD4N is a personal NixOS and Home Manager configuration published as a reusable repository. Contributions are welcome when they improve reliability, clarity, or portability without weakening the script-driven setup flow.

## Local Configuration Policy

Do not ask users to hand-edit `user.local.nix`.

- Machine-local values should be generated through `bash scripts/setup.sh`.
- Shared defaults belong in `user.nix`.
- Reusable behavior belongs in `nixos/`, `home-manager/`, or `scripts/`.
- Runtime-only machine files under `~/.local/share/md4n/` should stay out of Git.

## Change Guidelines

- Keep the stable entrypoints in `flake.nix`, `nixos/configuration.nix`, and `home-manager/home.nix` simple.
- Prefer adding or adjusting internal modules over growing entrypoint files.
- Keep shell scripts non-interactive where possible and consistent with the existing console UX.
- Update `README.md` when behavior, install flow, or package/profile semantics change.

## Validation

Before opening a change, run the checks you can on a NixOS machine and include the results in the PR or patch notes.

- `direnv allow` (optional, for the local validation shell)
- `nix flake check`
- `bash scripts/setup.sh`
- `bash scripts/forge.sh --home`
- `bash scripts/forge.sh --os`

If a change is documentation-only or cannot be fully tested in the current environment, say so explicitly.

## Pull Requests

- Keep changes focused.
- Explain user-visible behavior changes.
- Call out any risks around package selection, hardware detection, or generated local files.
