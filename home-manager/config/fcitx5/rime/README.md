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

`default.custom.yaml` imports the upstream `rime_ice_suggestion.yaml` profile
that ships with `rime-ice`, then overrides a few shared defaults:

- keep the schema list limited to the four shared Chinese layouts above
- show 7 candidates per page
- use `,` and `.` as page-up/page-down while the candidate list is open

If you want to tune behavior further, extend the files here instead of editing
generated runtime state under the deployed user directory.
