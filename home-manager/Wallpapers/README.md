# Wallpapers

This directory contains wallpaper assets that MD4N installs for the user.
It is meant for shared, reusable images that should travel with the configuration rather than for personal scratch files.

## Use In MD4N

The Home Manager core module links selected wallpaper assets into the user's home directory so they are available immediately after apply.
Keeping them here makes the visual baseline reproducible across machines.

## Good Candidates

- Default wallpapers used by the desktop configuration
- Repository-owned artwork that should ship with the setup
- Static assets referenced by documentation or theme modules

## Poor Candidates

- Large personal photo collections
- Temporary downloads
- Machine-local generated images
