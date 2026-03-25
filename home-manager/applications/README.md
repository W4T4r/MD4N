# Applications

This directory contains desktop entry overrides managed by Home Manager.
Files placed here are installed under `~/.local/share/applications` so the desktop environment and launchers pick them up before or alongside upstream entries.

## Typical Use Cases

- Override the command used to launch an application
- Add custom flags such as disabling GPU acceleration for one launcher variant
- Adjust names, categories, icons, or MIME associations
- Provide alternate launchers for tools that need multiple entrypoints

## Current Role In MD4N

MD4N uses this directory for editor and Typora launchers that behave better than the upstream defaults for this setup.
If a desktop entry change is meant to be shared across machines, it belongs here rather than in an ad hoc local directory.

## What Not To Put Here

- Random downloaded `.desktop` files with no clear reason
- One-off experiments that are not meant to be maintained
- Files that depend on machine-specific absolute paths unless those paths are intentionally part of the shared setup
