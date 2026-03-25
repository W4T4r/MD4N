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
- Keep `user.local.nix` untracked.
- Keep generated machine-local runtime files untracked unless they are explicitly sanitized and intended for sharing.
