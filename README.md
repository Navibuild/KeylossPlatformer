# Keyloss

A puzzle platformer about giving things up. Every level has **sacrifice blocks**: stand inside one and press its key to lose that input (left, right or jump) for the rest of the level. The goal flag only opens once every sacrifice has been made, so the puzzle is working out *where* and *in what order* to give your controls away.

Built with Godot 4.7 (GDScript, Compatibility renderer), playable in the browser.

## How to play

| Key | Action |
| --- | --- |
| ← → or A D | Move |
| Space | Jump |
| R | Restart level |
| Esc / P | Pause |
| M | Mute |

Things worth knowing:

- The press that sacrifices an input still happens, so a jump block gives you **one last jump**.
- After you sacrifice a direction while holding it, you keep sliding that way for 0.6 s (or until you let go).
- You can sacrifice in mid-air, and the L/R block takes whichever direction you press first, even one you've already lost.

## Features

- 15 levels across three worlds (Meadow, Sunset, Dusk), each with its own sky, parallax hills, clouds and ambient particles
- Title screen, level select with unlock progression, best times and saved progress
- In-level HUD showing which keys you still have, level-clear banner, pause menu
- Juice: iris scene transitions, screen shake, particles, squash and stretch, sound effects

## Project layout

```
scripts/
  game.gd            Autoload: level list, save data, transitions, screen shake, SFX
  level.gd           Root script on every level: scenery, ambient particles, vignette
  loss_block.gd      Base class for the sacrifice blocks (left/right/jump/L-R extend it)
  player.gd          Platformer controller
  goal_list.gd       HUD + opens the goal when sacrifices reach 0
  finish.gd          Goal flag
  title_screen.gd, level_select.gd, pause_menu.gd, ending.gd
scenes/
  levels/            level_1 ... level_15, game_over (ending)
  ui/                title_screen, level_select, menu_backdrop
  Scene Assets/      player, blocks, flag, platform, slime, HUD, pause menu
assets/
  ui/                keycap buttons, panels, HUD icons, theme.tres, title art
  backgrounds/       parallax hills, clouds, sun/moon per world
```

## Adding a level

1. Duplicate a level scene and save it as `scenes/levels/level_16.tscn`.
2. Add its name to `LEVEL_NAMES` in `scripts/game.gd` and raise `LEVEL_COUNT`.
3. Set `sacrifices` on the `Goal_list` node to the number of blocks the player must use.

The level's world (sky colours and scenery) comes from its number: 1–5 Meadow, 6–10 Sunset, 11–15 Dusk.
