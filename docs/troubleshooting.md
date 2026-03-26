# Troubleshooting

This guide collects the failure modes that are most likely to show up when installing, regenerating local state, or applying MD4N.

The main scripts involved are:

- [install.sh](../install.sh)
- [scripts/bootstrap.sh](../scripts/bootstrap.sh)
- [scripts/configure-local.sh](../scripts/configure-local.sh)
- [scripts/forge.sh](../scripts/forge.sh)

## `local/generated/user.nix` Is Missing

Symptoms:

- `forge.sh` reports that it could not find `user.nix` or `local/generated/user.nix`
- the machine-specific answers were never generated

What to do:

1. Run [scripts/configure-local.sh](../scripts/configure-local.sh) again.
2. Check whether the script completed all the way through the generation step.
3. Verify that `local/generated/user.nix` now exists in the repository root.

Do not hand-edit `local/generated/user.nix` as a workaround.
MD4N treats it as generated local state.

## `nix flake` Does Not See Local Changes

Symptoms:

- a local file exists, but evaluation behaves as if it is missing
- `local/generated/user.nix` or other local state is ignored during apply

What to do:

Use a `path:` flake reference when applying from the local checkout.

Example:

```bash
sudo nixos-rebuild switch --flake path:/absolute/path/to/MD4N/local#<hostname>
home-manager switch -b md4nbak --flake path:/absolute/path/to/MD4N/local#<username>
```

The repository scripts already do this for you.
If you bypass them and use `.#...`, local files may be left out of evaluation.

## `fzf` Is Missing

Symptoms:

- `mn.sh`, `forge.sh`, `rollback.sh`, or `tune.sh` exits with a missing `fzf` error

What to do:

- Use [install.sh](../install.sh) or [scripts/bootstrap.sh](../scripts/bootstrap.sh) instead of running the menu scripts first
- `bootstrap.sh` can launch local configuration through a temporary `nix shell` when `fzf` is not already present

If the system is already configured, you can also enter the repo and run:

```bash
direnv allow
```

That gives you the local validation shell, but the normal interactive operator flow is still the script layer.

## GPU Detection Looks Wrong

Symptoms:

- the local configuration script chooses the wrong GPU vendor
- ROCm-specific packages are not selected when expected

What to know:

- [scripts/configure-local.sh](../scripts/configure-local.sh) first checks `/sys/class/drm`
- if needed, it falls back to `lspci`
- in guided mode, you can still choose a different value before generation

What to do:

1. Re-run [scripts/configure-local.sh](../scripts/configure-local.sh).
2. In guided mode, pick the correct GPU vendor manually.
3. Apply again after regeneration.

## Niri Output Detection Fails

Symptoms:

- no connected outputs are detected
- the generated `outputs.local.kdl` is not updated

What to know:

- [scripts/configure-niri-outputs.sh](../scripts/configure-niri-outputs.sh) uses `modetest -c`
- if `modetest` is not in `PATH`, it can fall back to a temporary `nix shell`
- when no outputs can be detected, the script keeps the existing Niri outputs config instead of guessing

What to do:

1. Re-run [scripts/configure-niri-outputs.sh](../scripts/configure-niri-outputs.sh).
2. Watch for warnings about `modetest`.
3. If detection still fails, keep the previous generated file or investigate DRM access on that machine.

## Hardware Configuration Generation Fails

Symptoms:

- local configuration fails while generating `local/nixos/hardware.nix`
- `sudo` works, but the hardware file is not updated

What to know:

- local configuration uses `sudo nixos-generate-config --show-hardware-config`
- the result is written back into `local/nixos/hardware.nix`

What to do:

1. Make sure `sudo` is available and your user can use it.
2. Re-run [scripts/configure-local.sh](../scripts/configure-local.sh).
3. If you do not want to regenerate hardware config on that machine, skip the prompt and keep the existing file.

## Fingerprint Enrollment Did Not Happen

Symptoms:

- fingerprint support is enabled, but no fingerprint is enrolled
- setup skipped or failed the enrollment step

What to do:

Run the enrollment command manually after apply:

```bash
fprintd-enroll <username>
```

This is the same command the setup flow uses when fingerprint support is enabled.

## `nix flake check` Fails

Symptoms:

- local validation fails before a commit or PR

What to know:

The flake checks currently cover:

- Nix formatting through `alejandra --check`
- shell validation through `shellcheck`

What to do:

1. If you use `direnv`, run `direnv allow` once in the repository root.
2. Re-run:

```bash
nix flake check
```

3. Fix the reported formatter or shell issues.

For local tooling, the repository dev shell exposes `alejandra`, `shellcheck`, `statix`, `deadnix`, and `actionlint`.

## Home Manager Or NixOS Apply Fails

Symptoms:

- `forge.sh` fails during `nixos-rebuild` or `home-manager switch`

What to do:

1. Re-run the failing command directly to isolate whether the problem is in the wrapper or the underlying tool.
2. Check whether `local/generated/user.nix` was regenerated after your latest local configuration change.
3. Confirm that you are applying from the repository you expect.
4. Use the `path:` flake form if you are invoking the raw commands yourself.

## Still Stuck

When reporting a problem or debugging locally, capture:

- which script you ran
- the exact error message
- whether you were in guided mode or automatic mode
- whether the failure happened during generation, apply, or a later maintenance step

That usually narrows the failure down to one layer quickly.
