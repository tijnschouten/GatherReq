# GatherReq

`GatherReq` adds profession skill requirements directly to the default tooltip in World of Warcraft: Burning Crusade Classic.

No more walking up to a herb, mining node, corpse, or lockbox just to find out whether you can use it.

## Features

- Shows required `Mining` skill on mining node tooltips
- Shows required `Herbalism` skill on herb tooltips
- Shows required `Skinning` skill on skinnable corpses
- Shows required `Lockpicking` skill on supported lockboxes and locked objects
- Replaces the default simple profession line with a more useful requirement line when possible
- Shows your current skill in the tooltip when you know the profession
- Uses profession-style difficulty colors
- Shows a training reminder when Mining, Herbalism, or Skinning is within 25 points of the current cap
- Takes TBC character level requirements into account before saying the next rank is trainable

## Examples

- `Requires Mining 175`
- `Requires Herbalism 315 (You: 342)`
- `Requires Skinning 225`

## Scope

This addon is built for `WoW TBC Classic 2.5.5`.

It augments Blizzard’s normal tooltip. It does not add a custom range overlay or scan objects that do not already produce a tooltip.

## Notes

- English-only in this version
- Uses curated requirement lookup data for mining, herbalism, and lockpicking
- Computes skinning requirements from unit level
- Unknown or ambiguous tooltip names are skipped instead of guessed

## Installation

Extract the zip so the addon is installed like this:

```text
World of Warcraft/_classic_/Interface/AddOns/GatherReq/
  GatherReq.toc
  Core.lua
  Data.lua
```
