# MD4N-private Template

This directory is a tracked starter for a separate `MD4N-private` repository.
Copy it into its own repository, then keep the real machine directories there.

# MD4N-private

Private local configuration for MD4N.

Visible layout at the repository root:

- `README.md`
- `link-md4n.sh`
- `new-machine.sh`
- one or more machine directories

You choose the machine directory names yourself.
The linker script does not try to derive or normalize them from system information.

Each machine directory stores:

- `local/`
  Files that should be linked into the ignored `MD4N/local/` tree
- `home-manager/`
  Machine-specific Home Manager side files that should be linked into ignored paths under `MD4N/home-manager/config/`
- `README.md`
  Human-readable notes and machine facts for that directory

For Niri, keep machine-only files under `<machine>/home-manager/niri/`:

- `outputs.kdl`
  generated display topology
- `config.local.kdl`
  loaded last by shared `config.kdl` so it can override shared settings
- `local/*.local.kdl`
  optional extra local snippets included from `config.local.kdl`
- `browser.sh`
  machine-local browser helper

Use `bash ./new-machine.sh <machine-dir>` to create a new machine directory scaffold.
Use `bash ./link-md4n.sh` to apply one of the existing machine directories.

`new-machine.sh` seeds tracked templates and safe shared defaults.
It does not copy the current machine's private `MD4N/local/` overrides into the new scaffold.
