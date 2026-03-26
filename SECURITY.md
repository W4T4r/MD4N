# Security Policy

## Supported Use

MD4N targets NixOS systems and assumes the repository is evaluated locally with machine-specific state kept outside Git when appropriate.

## Reporting

If you find a security issue, do not open a public issue with exploit details.

Report it privately to the repository owner first. Include:

- affected file or module
- impact
- reproduction steps
- any mitigation or fix you already validated

## Sensitive Data

This repository is intended to keep secrets and machine-specific private state out of Git.

- Do not commit credentials, tokens, private keys, or personal machine secrets.
- Keep `local/flake.nix`, `local/flake.lock`, `local/generated/`, `local/home-manager/`, and `local/nixos/` untracked.
- Keep linked local runtime files such as `home-manager/config/gtk-3.0/bookmarks` and `home-manager/config/niri/outputs.local.kdl` untracked.
- Keep generated machine-local runtime files untracked unless they are explicitly sanitized and intended for sharing.
