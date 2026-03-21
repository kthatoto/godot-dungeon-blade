# Project Memory

## Task 1: Visual Architecture

### What worked
- Procedural pixel art generation via `Image.create()` + `_draw_rect`/`_draw_circle` helpers in a headless GDScript builder
- `_add_outline()` function for dark outlines around sprite silhouettes -- makes characters readable against dark backgrounds
- `_blend_pixel()` for semi-transparent overlay effects (moss, stains, glow)
- Sprite scale 2x on 64x64 player, 48x48 enemy, 96x96 boss at 1280x720 viewport gives good readability
- `CanvasModulate` for global darkness + `PointLight2D` for warm torch pools creates effective dungeon atmosphere
- `CharacterBody2D.MOTION_MODE_FLOATING` required for top-down 2D movement
- Tween-based idle bob animation (`sprite.position:y` oscillation) is simple and effective

### What failed / gotchas
- Camera2D `make_current()` fails if called before node is in scene tree -- must defer to `_process()`
- Test harness camera must be independent node (not child of player) with `_player_cam.enabled = false` to override player camera
- VQA interprets camera panning between rooms as "entities disappearing" -- this is a test artifact, not a real bug
- Light texture for PointLight2D must be created as ImageTexture at build time; procedural 128x128 radial gradient works well
- Floor decoration sprites with low alpha modulate add organic feel to the grid-based tile floor
- Torch placement with `randf_range` offsets prevents mathematically uniform look

### Asset pipeline
- `scenes/generate_assets.gd` creates all PNG sprites procedurally
- Must run `godot --headless --import` after generating PNGs before scene builders can load them
- Assets: floor_tile.png (32x32), wall_tile.png (32x32), torch.png (16x32), player.png (64x64), enemy.png (48x48), boss.png (96x96), doorway.png (32x64), floor_deco.png (32x32), wall_deco.png (32x32)

### Architecture
- Wall collision uses StaticBody2D segments with doorway gaps (split into upper/lower segments where doors are)
- Rooms are offset by 1280px horizontally (viewport width)
- HUD is on CanvasLayer (layer 10) so it doesn't move with camera
- HUD polls player/GameManager state in `_process()` rather than using signals (simpler for visual-only task)
