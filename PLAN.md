# Game Plan: Dungeon Blade

## Game Description

トップダウンの2Dアクションゲーム。剣で敵を倒してダンジョンを進む。3つの部屋があり、最後にボス戦。

## 1. Visual Architecture
- **Depends on:** (none)
- **Status:** done
- **Targets:** scenes/main.tscn, scenes/player.tscn, scenes/enemy.tscn, scenes/boss.tscn, scenes/hud.tscn, scripts/player_controller.gd, scripts/enemy_controller.gd, scripts/boss_controller.gd, project.godot
- **Goal:** Build the complete visual foundation — dungeon rooms, player character, enemies, and boss all rendered at correct scale with animations, in the dark fantasy pixel art style from reference.png.
- **Requirements:**
  - Three distinct dungeon rooms connected by doorways, each room filling roughly one screen
  - Stone tile floors and walls with torchlight atmosphere
  - Player character with idle, walk, and sword attack animations
  - Skeleton enemies with idle and walk animations
  - Boss character visually larger and more menacing than regular enemies
  - HUD showing HP bar, room indicator, and gold counter
  - All sprites correctly scaled and positioned in the top-down perspective
- **Assets needed:**
  - Dungeon tileset (stone floors, walls, doorways, torch decorations) — 32x32 px tiles
  - Player character sprite sheet (idle, walk 4-dir, sword attack) — 64x64 px per frame
  - Skeleton enemy sprite sheet (idle, walk 4-dir) — 48x48 px per frame
  - Boss sprite sheet (idle, walk, attack) — 96x96 px per frame
  - Dungeon background texture for floor fill
- **Verify:** Screenshot shows a dark dungeon room with stone walls and floor tiles, a hero character standing among skeleton enemies, HUD with HP bar visible. All sprites are correctly scaled and clearly readable in the pixel art style.

## 2. Core Game Loop
- **Depends on:** 1
- **Status:** done
- **Targets:** scripts/player_controller.gd, scripts/enemy_controller.gd, scripts/boss_controller.gd, scripts/game_manager.gd, scripts/hud_controller.gd, scenes/main.tscn
- **Goal:** Implement all gameplay — movement, combat, enemy AI, room transitions, boss fight, win/lose conditions.
- **Requirements:**
  - 8-directional player movement with WASD/arrow keys
  - Sword attack on mouse click or Space — short-range arc in front of player, damages enemies on contact
  - Enemies patrol their room and chase the player when in range
  - Enemies deal contact damage to the player
  - Killing all enemies in a room opens the door to the next room
  - Room 3 contains the boss — larger health pool, telegraphed attack pattern (charge + area slam)
  - Player HP, enemy HP with damage feedback (flash, knockback)
  - Death and victory screens
  - Gold drops from defeated enemies, displayed on HUD
- **Verify:** Gameplay sequence: player walks through room 1, attacks and kills skeleton enemies with sword, door opens, enters room 2 with more enemies, clears them, enters room 3, boss fight with distinct attack patterns, defeating boss shows victory screen.

## 3. Presentation Video
- **Depends on:** 1, 2
- **Status:** done
- **Targets:** test/presentation.gd, screenshots/presentation/gameplay.mp4
- **Goal:** Create a ~30-second cinematic video showcasing the completed game.
- **Requirements:**
  - Write test/presentation.gd — a SceneTree script (extends SceneTree)
  - Showcase representative gameplay via simulated input or scripted animations
  - ~900 frames at 30 FPS (30 seconds)
  - Use Video Capture from godot-capture (AVI via --write-movie, convert to MP4 with ffmpeg)
  - Output: screenshots/presentation/gameplay.mp4
  - Camera pans and smooth scrolling, zoom transitions between overview and close-up, trigger representative gameplay sequences, tight viewport framing
- **Verify:** A smooth MP4 video showing polished gameplay with no visual glitches.
