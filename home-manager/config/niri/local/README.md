# Niri Local Snippets

This directory is reserved for machine-local Niri snippets that should stay out of Git.

Create files such as `touchpad.local.kdl` or `laptop.local.kdl` here, then include them from `../config.local.kdl`.
The shared `config.kdl` loads `config.local.kdl` last so those local overrides can replace earlier shared settings.
