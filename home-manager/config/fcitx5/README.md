# Fcitx5

Input method configuration for Fcitx5.
Component-specific settings live under `conf/`.

The shared profile keeps the `Hazkey` group and includes both Japanese-oriented
input through Hazkey and Chinese input through Rime.

Rime-specific files live under [`rime/`](rime/README.md). They are deployed to
`~/.local/share/fcitx5/rime`, which is where `fcitx5-rime` stores schemas,
compiled data, and user dictionaries.
