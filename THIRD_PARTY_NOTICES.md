# Third-Party Notices

This repository includes or redistributes a small number of third-party assets alongside the main MD4N configuration.
The entries below are the bundled items that need attribution or license retention.

## Noctalia Plugins

The following plugin directories are bundled under [`home-manager/config/noctalia/plugins`](home-manager/config/noctalia/plugins):

- [`privacy-indicator`](home-manager/config/noctalia/plugins/privacy-indicator)
- [`kaomoji-provider`](home-manager/config/noctalia/plugins/kaomoji-provider)

According to their bundled `manifest.json` files:

- Author: `Noctalia Team`
- License: `MIT`
- Repository: `https://github.com/noctalia-dev/noctalia-plugins`

These plugin files remain attributed to their upstream authors.

## Catppuccin Macchiato Yazi Flavor

The bundled Yazi flavor under [`home-manager/config/yazi/flavors/catppuccin-macchiato.yazi`](home-manager/config/yazi/flavors/catppuccin-macchiato.yazi) includes its upstream license files:

- [`LICENSE`](home-manager/config/yazi/flavors/catppuccin-macchiato.yazi/LICENSE)
- [`LICENSE-tmtheme`](home-manager/config/yazi/flavors/catppuccin-macchiato.yazi/LICENSE-tmtheme)

Included copyright notices:

- Copyright (c) 2023 yazi-rs
- Copyright (c) 2021 Catppuccin

Both bundled license files are MIT licenses and should remain with the flavor assets.

## Catppuccin-Derived Color Assets

The repository also includes Catppuccin-derived theme data such as:

- [`home-manager/config/noctalia/colorschemes/Catppuccin Lavender`](home-manager/config/noctalia/colorschemes/Catppuccin%20Lavender)
- the Catppuccin-flavored Yazi theme assets noted above
- Catppuccin color files used by Alacritty and related config

Where upstream license files are bundled, they should be kept intact.
Where the repository only stores configuration values derived from a theme palette, attribution should remain visible in the surrounding documentation and file naming.

## Project License vs Third-Party Content

MD4N itself is licensed under the MIT License in [`LICENSE`](LICENSE).
That project license does not replace the attribution or license requirements of bundled third-party assets.
