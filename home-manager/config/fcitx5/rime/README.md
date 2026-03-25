# Rime

User-level Rime configuration for Fcitx5.

This directory is linked to `~/.local/share/fcitx5/rime`, which is the user data
directory that `fcitx5-rime` reads and writes.

The shared setup keeps Rime focused on Simplified Chinese:

- `rime_ice` for a rich full-pinyin experience
- `double_pinyin` for Ziranma-style shuangpin
- `double_pinyin_flypy` for Xiaohe shuangpin
- `double_pinyin_mspy` for Microsoft shuangpin

If you want to tune behavior further, extend the files here instead of editing
generated runtime state under the deployed user directory.
