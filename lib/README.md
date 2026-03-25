# Lib

This directory holds small shared Nix helpers used by the rest of the repository.
Right now the main purpose is to centralize how user configuration is assembled before it is handed to NixOS and Home Manager.

## Current Contents

- `user.nix`
  Loads the committed defaults from the repository root, optionally merges the generated `user.local.nix`, derives fallback paths such as `home`, `dotroot`, `cfg`, and `app`, and normalizes values like the GPU vendor.

## Why It Matters

Without this layer, both NixOS and Home Manager would need to repeat the same merge and normalization logic.
Keeping it here means the rest of the configuration can treat `user` as a stable interface instead of caring where each value came from.

## Editing Guidance

This directory is for small reusable helpers, not for major configuration modules.
If logic is specific to NixOS or Home Manager behavior, keep it in those trees.
If logic defines the shared shape of input data for both sides, `lib/` is the right place.
