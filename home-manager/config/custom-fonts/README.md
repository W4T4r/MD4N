# Custom Fonts

This directory is a reserved machine-local slot for GTK and Fcitx font UI overrides.
The shared repository keeps only this README. The actual runtime files in this directory should stay ignored by Git.

Home Manager still links these files into place through [`../../modules/fonts.nix`](../../modules/fonts.nix) when `user.enableLocalFonts = true;`.

Expected local files:

- `gtk-3.0-settings.ini`
- `gtk-4.0-settings.ini`
- `fcitx5-classicui.conf`

Recommended workflow:

1. Keep the real files in your private local-config repository.
2. Link or copy them into this directory.
3. Re-apply Home Manager when you want those overrides installed.

The tracked starter lives in [`../../../private_templates/MD4N-private`](../../../private_templates/MD4N-private/README.md), and the management workflow is documented in [`../../../docs/private-repo.md`](../../../docs/private-repo.md).

These files are local because they usually depend on fonts, themes, and UI preferences that are not safe to assume across machines.
