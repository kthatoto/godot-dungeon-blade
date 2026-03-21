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

## Task 2: Core Game Loop

### What worked
- Player `add_to_group("player")` + enemy `add_to_group("enemies")` for runtime entity discovery
- `get_slide_collision_count()` + `get_slide_collision()` for contact damage detection on CharacterBody2D
- Invincibility timer with sprite flicker (`modulate.a` alternating) prevents damage spam on contact
- GameManager autoload with `door_opened` signal + `_on_door_opened()` callback to remove door blockers at runtime
- Door blockers as StaticBody2D with groups (`door_blocker_0`, `door_blocker_1`) for easy lookup via `get_nodes_in_group()`
- Boss state machine: idle -> chase -> telegraph_charge/telegraph_slam -> charge/slam -> cooldown cycle
- Visual telegraphs (color flash before attacks) give player reaction time
- Enemy `_get_room_index()` from `global_position.x` to determine which room they belong to
- HUD game-over overlay with tween fade-in: ColorRect alpha + Label color animation

### What failed / gotchas
- `:=` type inference fails on `(parent.global_position - global_position).normalized()` when `parent` comes from `area.get_parent()` (returns Node, not Node2D). Must cast explicitly: `var body := parent as CharacterBody2D` then use `body.global_position`
- `collider.contact_damage` via "in" check works but is untyped -- cast to the actual type for safety
- Camera2D `make_current()` in `_initialize()` fails with "not in scene tree" error -- must be called in `_process()` or after `add_child()`
- `set_deferred("disabled", ...)` required for collision shape changes inside physics callbacks

### Architecture
- Enemies self-register with GameManager via `register_enemy(room_idx)` and connect `died` signal in `_ready()`
- Player connects `sword_hitbox.area_entered` to `_on_sword_hit` which calls `parent.take_damage()` on the hit entity
- Enemy HurtBox (Area2D, layer 2, mask 8=player_attack) receives SwordHitbox (Area2D, layer 8=player_attack, mask 2=enemies) collisions
- Contact damage: player checks `get_slide_collision()` in `_physics_process()` for enemies in group
- GameManager tracks `enemies_per_room[3]` and emits `door_opened` when a room reaches 0
- Boss uses _attack_cycle counter to alternate between charge and slam attacks

## Task 3: Presentation Video

### What worked
- SceneTree script with frame-based phase system for cinematic sequencing
- `--write-movie output.avi --fixed-fps 30 --quit-after 900` produces clean 30s AVI
- ffmpeg conversion: `-c:v libx264 -pix_fmt yuv420p -crf 28 -preset slow -movflags +faststart` yields ~2.4MB MP4
- Making player invincible (`max_hp = 99999`) prevents accidental death during presentation
- `_kill_room_enemies()` with `take_damage(999)` to force room clears at scripted moments
- `_release_all_movement()` helper that releases all input actions prevents stuck movement between phases
- Camera `position_smoothing_enabled = true` with manual `lerp()` gives smooth follow
- Teleporting player to next room entrance ensures progression even if movement timing is imprecise

### What failed / gotchas
- `make_current()` in `_initialize()` produces error since Camera2D not yet in scene tree — harmless, camera works from frame 1
- `position_smoothing_enabled` must be toggled off during camera pan transitions, re-enabled for follow phases
- On macOS, Godot runs natively with Metal — no GPU detection or xvfb needed
