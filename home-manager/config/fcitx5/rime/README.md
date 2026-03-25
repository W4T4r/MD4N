# Rime

Repository-owned custom Rime configuration for Fcitx5.

The generated user data directory is `~/.local/share/fcitx5/rime`.
This repository contributes custom files there, while the bundled `rime-ice`
schema and dictionary files are linked in from `nixpkgs`.

The shared setup keeps Rime focused on Simplified Chinese:

- `rime_ice` for a rich full-pinyin experience
- `double_pinyin` for Ziranma-style shuangpin
- `double_pinyin_flypy` for Xiaohe shuangpin
- `double_pinyin_mspy` for Microsoft shuangpin

If you want to tune behavior further, extend the files here instead of editing
generated runtime state under the deployed user directory.
