# GatherReq

`GatherReq` is a lightweight World of Warcraft TBC Classic (`2.5.5`) addon that appends the required `Mining`, `Herbalism`, `Skinning`, or `Lockpicking` skill to the standard Blizzard tooltip.

## What it does

- Shows `Requires Mining <skill>` on ore-node tooltips.
- Shows `Requires Herbalism <skill>` on herb-node tooltips.
- Shows `Requires Skinning <skill>` on skinnable corpse tooltips.
- Shows `Requires Lockpicking <skill>` on supported lockbox and locked-object tooltips.
- Shows a training hint for `Mining`, `Herbalism`, and `Skinning` when you are within 25 points of your current cap.

The addon only augments the normal Blizzard tooltip. It does not create a separate range overlay.

## Install

1. Create a folder named `GatherReq` inside your WoW addons directory.
2. Place these files inside that folder:
   - `GatherReq.toc`
   - `Data.lua`
   - `Core.lua`
   - `assets/gatherreq-icon.tga`
3. Start or reload WoW TBC Classic.

## Notes

- This v1 is English-only and keys data by English tooltip names.
- Unknown or ambiguous tooltip names are ignored rather than guessed.
- There are no slash commands or saved settings in this version.
- Branding assets live in `assets/`.
