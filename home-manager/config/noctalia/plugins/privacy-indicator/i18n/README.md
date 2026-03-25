# Translations

This directory contains locale files for the Noctalia privacy indicator plugin.
Each JSON file represents one language and translates the user-facing strings shown by the plugin UI.

## Structure

- One JSON file per locale
- Shared translation keys across all locales
- Values translated for that language only

## Editing Guidance

When adding or updating a translation:

- Keep the same keys in every locale file
- Avoid changing key names unless the plugin code changes with it
- Prefer small, consistent wording changes over locale-specific structural rewrites

If the plugin adds a new visible label or setting, this directory should be updated alongside the QML and settings changes.
