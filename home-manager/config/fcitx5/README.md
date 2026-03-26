# Fcitx5

Input method configuration for Fcitx5.
Component-specific settings live under `conf/`.

The shared profile keeps the `Hazkey` group and includes both Japanese-oriented
input through Hazkey and Chinese input through the built-in Pinyin engine from
`fcitx5-chinese-addons`.

This keeps the shared setup simpler than the previous Rime-based layout:

- no shared deployment into `~/.local/share/fcitx5/rime`
- no extra schema synchronization step
- one shared Chinese input entry in the Fcitx5 profile: `pinyin`
