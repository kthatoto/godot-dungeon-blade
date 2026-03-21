# Dungeon Blade

## Dimension: 2D

## Input Actions

| Action | Keys |
|--------|------|
| move_up | W, Up |
| move_down | S, Down |
| move_left | A, Left |
| move_right | D, Right |
| attack | Space, Mouse Left |

## Scenes

### Main
- **File:** res://scenes/main.tscn
- **Root type:** Node2D
- **Children:** Room1 (Node2D), Room2 (Node2D), Room3 (Node2D), Player, CanvasLayer (HUD)

### Player
- **File:** res://scenes/player.tscn
- **Root type:** CharacterBody2D
- **Children:** Sprite2D, CollisionShape2D, SwordHitbox (Area2D with CollisionShape2D), AnimationPlayer

### Enemy
- **File:** res://scenes/enemy.tscn
- **Root type:** CharacterBody2D
- **Children:** Sprite2D, CollisionShape2D, HurtBox (Area2D), AnimationPlayer

### Boss
- **File:** res://scenes/boss.tscn
- **Root type:** CharacterBody2D
- **Children:** Sprite2D, CollisionShape2D, HurtBox (Area2D), AttackArea (Area2D), AnimationPlayer

## Scripts

### PlayerController
- **File:** res://scripts/player_controller.gd
- **Extends:** CharacterBody2D
- **Attaches to:** Player:Player
- **Signals emitted:** died, attacked
- **Signals received:** SwordHitbox.area_entered -> _on_sword_hit

### EnemyController
- **File:** res://scripts/enemy_controller.gd
- **Extends:** CharacterBody2D
- **Attaches to:** Enemy:Enemy
- **Signals emitted:** died(enemy)
- **Signals received:** HurtBox.area_entered -> _on_hurt

### BossController
- **File:** res://scripts/boss_controller.gd
- **Extends:** CharacterBody2D
- **Attaches to:** Boss:Boss
- **Signals emitted:** died
- **Signals received:** HurtBox.area_entered -> _on_hurt

### GameManager (Autoload)
- **File:** res://scripts/game_manager.gd
- **Extends:** Node
- **Signals emitted:** room_changed(room_index), game_over(won)

### HUDController
- **File:** res://scripts/hud_controller.gd
- **Extends:** Control
- **Attaches to:** Main:CanvasLayer:HUD
- **Signals received:** GameManager.room_changed, PlayerController.died

## Signal Map

- Player:SwordHitbox.area_entered -> PlayerController._on_sword_hit
- Enemy:HurtBox.area_entered -> EnemyController._on_hurt
- Boss:HurtBox.area_entered -> BossController._on_hurt
- EnemyController.died -> GameManager._on_enemy_died
- BossController.died -> GameManager._on_boss_died
- GameManager.room_changed -> HUDController._on_room_changed

## Asset Hints

- Dungeon tileset (32x32 px stone floor, wall, doorway tiles for TileMap)
- Player character sprite sheet (64x64 px, idle/walk/attack, 4 directions)
- Skeleton enemy sprite sheet (48x48 px, idle/walk, 4 directions)
- Boss sprite sheet (96x96 px, idle/walk/attack)
- Dungeon floor texture (dark stone, tileable)
