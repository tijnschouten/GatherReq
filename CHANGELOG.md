# Changelog

## 1.0.6

- Added an in-game `/gatherreq` reference window with Mining, Herbs, Lockpicking, and Skinning sections
- Added aligned rows with item-backed icons and hover tooltips for herbs, ore, and lockboxes
- Added real junkbox and lockbox item IDs so lockpicking entries no longer depend on cache
- Added lockpickable door and gate references with locations, and tooltip support for supported door names
- Fixed lockpicking reference progression for `Worn`, `Sturdy`, `Heavy`, and `Strong` junkboxes

## 1.0.5

- Replaced Blizzard's default profession requirement lines more consistently for unlearned gathering professions
- Replaced the `Skinnable` tooltip line with the full skinning requirement line
- Made training-available warnings more prominent

## 1.0.4

- Reverted CurseForge packaging to use the markdown changelog as the single source of truth
- Removed the duplicate HTML changelog file
- No addon behavior changes

## 1.0.3

- Switched CurseForge automatic packaging to an HTML manual changelog file
- Limited CurseForge release notes to the latest release entry
- No addon behavior changes

## 1.0.2

- Switched CurseForge automatic packaging to use this manual markdown changelog
- Disabled unnecessary `-nolib` package generation
- No addon behavior changes

## 1.0.1

- Added addon-list icon support with bundled TGA icon texture
- Fixed duplicate requirement lines after profession skill-ups while the tooltip stayed open
- Added GitHub-to-CurseForge automatic packaging files

## 1.0.0

- Initial release of `GatherReq`
- Added mining, herbalism, skinning, and lockpicking tooltip requirements
- Added profession difficulty-style coloring
- Added current-skill display when the player knows the profession
- Replaced the default profession line in supported tooltips with richer requirement text
- Added training hints near profession caps for mining, herbalism, and skinning
- Added CurseForge-ready packaging and branding asset
