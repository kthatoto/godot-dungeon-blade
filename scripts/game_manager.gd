extends Node
## res://scripts/game_manager.gd — Global game state, room progression, win/lose

signal room_changed(room_index: int)
signal game_over(won: bool)
signal door_opened(room_index: int)

var current_room: int = 0
var gold: int = 0
var enemies_per_room: Array[int] = [0, 0, 0]
var is_game_over: bool = false
var player_ref: CharacterBody2D = null

const ROOM_W := 1280

func _ready() -> void:
	door_opened.connect(_on_door_opened)

func register_enemy(room_index: int) -> void:
	if room_index >= 0 and room_index < 3:
		enemies_per_room[room_index] += 1

func _on_enemy_died(enemy: CharacterBody2D) -> void:
	if is_game_over:
		return
	# Determine room from position
	var room_idx: int = _get_room_from_pos(enemy.global_position.x)
	if room_idx >= 0 and room_idx < 3:
		enemies_per_room[room_idx] -= 1
		if enemies_per_room[room_idx] < 0:
			enemies_per_room[room_idx] = 0
	if enemy and "gold_value" in enemy:
		gold += enemy.gold_value
	# Check if room is cleared
	if room_idx >= 0 and room_idx < 3 and enemies_per_room[room_idx] <= 0:
		door_opened.emit(room_idx)

func _on_boss_died() -> void:
	if is_game_over:
		return
	gold += 100
	enemies_per_room[2] = 0
	door_opened.emit(2)
	is_game_over = true
	game_over.emit(true)

func player_died() -> void:
	if is_game_over:
		return
	is_game_over = true
	game_over.emit(false)
	# Retry after 1 second
	get_tree().create_timer(1.0).timeout.connect(_retry)

func _retry() -> void:
	is_game_over = false
	enemies_per_room = [0, 0, 0]
	gold = 0
	current_room = 0
	player_ref = null
	get_tree().reload_current_scene()

func update_current_room() -> void:
	if player_ref == null:
		return
	var new_room: int = _get_room_from_pos(player_ref.global_position.x)
	if new_room != current_room and new_room >= 0 and new_room < 3:
		current_room = new_room
		room_changed.emit(current_room)

func _get_room_from_pos(x: float) -> int:
	if x < ROOM_W:
		return 0
	elif x < ROOM_W * 2:
		return 1
	else:
		return 2

func _on_door_opened(room_index: int) -> void:
	# Remove door blocker for this room (find by node name, not group)
	var main = get_tree().current_scene
	if main == null:
		return
	var blocker = main.get_node_or_null("DoorBlocker_%d" % room_index)
	if blocker:
		var visual = blocker.get_node_or_null("Visual")
		if visual:
			var tween := create_tween()
			tween.tween_property(visual, ^"modulate", Color(1, 1, 1, 0), 0.5)
			tween.tween_callback(blocker.queue_free)
		else:
			blocker.queue_free()

func _process(_delta: float) -> void:
	update_current_room()
