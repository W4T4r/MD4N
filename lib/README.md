# Lib

This directory holds small shared Nix helpers used by the rest of the repository.
Right now the main purpose is to centralize optional merge and normalization logic for user configuration data.

## Current Contents

- `user.nix`
  Loads the committed defaults from the repository root, optionally merges the generated `local/generated/user.nix`, derives fallback paths such as `home`, `dotroot`, `cfg`, and `app`, normalizes values like the GPU vendor, and maps legacy local keys to the current shape.

## Why It Matters

When a caller wants repository defaults plus local generated values, this layer keeps the merge logic in one place instead of repeating it.

## Editing Guidance

This directory is for small reusable helpers, not for major configuration modules.
If logic is specific to NixOS or Home Manager behavior, keep it in those trees.
If logic defines the shared shape of input data for both sides, `lib/` is the right place.
