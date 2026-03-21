extends Node
## res://scripts/game_manager.gd — Global game state, room progression, win/lose

signal room_changed(room_index: int)
signal game_over(won: bool)
signal door_opened(room_index: int)

var current_room: int = 0
var run_gold: int = 0
var enemies_per_room: Array[int] = [0, 0, 0]
var is_game_over: bool = false
var player_ref: CharacterBody2D = null

# Endless mode
var endless_mode: bool = false
var dungeon_depth: int = 0
var _endless_enemy_count: int = 0
var _endless_rooms: Array[Node2D] = []  # keep max 2 rooms
var _endless_current_offset_x: float = 0.0
var _endless_blocker: StaticBody2D = null

const ROOM_W := 1280
const RoomGenerator = preload("res://scripts/room_generator.gd")

func _ready() -> void:
	door_opened.connect(_on_door_opened)

func register_enemy(room_index: int) -> void:
	if room_index >= 0 and room_index < 3:
		enemies_per_room[room_index] += 1

func register_enemy_endless() -> void:
	_endless_enemy_count += 1

func _on_enemy_died(enemy: CharacterBody2D) -> void:
	if is_game_over:
		return

	if endless_mode:
		_on_enemy_died_endless(enemy)
		return

	var room_idx: int = _get_room_from_pos(enemy.global_position.x)
	if room_idx >= 0 and room_idx < 3:
		enemies_per_room[room_idx] -= 1
		if enemies_per_room[room_idx] < 0:
			enemies_per_room[room_idx] = 0
	if enemy and "gold_value" in enemy:
		run_gold += enemy.gold_value
	if room_idx >= 0 and room_idx < 3 and enemies_per_room[room_idx] <= 0:
		door_opened.emit(room_idx)

func _on_enemy_died_endless(enemy: CharacterBody2D) -> void:
	if enemy and "gold_value" in enemy:
		run_gold += enemy.gold_value
	_endless_enemy_count -= 1
	if _endless_enemy_count < 0:
		_endless_enemy_count = 0
	if _endless_enemy_count <= 0:
		_open_endless_door()

func _on_boss_died() -> void:
	if is_game_over:
		return

	if endless_mode:
		run_gold += 100
		_endless_enemy_count -= 1
		if _endless_enemy_count <= 0:
			_open_endless_door()
		return

	run_gold += 100
	enemies_per_room[2] = 0
	door_opened.emit(2)
	# Enter endless mode instead of game over
	is_game_over = false
	get_tree().create_timer(1.5).timeout.connect(_enter_endless_mode)

func _enter_endless_mode() -> void:
	endless_mode = true
	dungeon_depth = 3
	_endless_current_offset_x = 3 * ROOM_W  # start after the 3 fixed rooms

	# Remove fixed room door blockers
	var main = get_tree().current_scene
	if main == null:
		return

	# Generate first endless room
	_generate_next_endless_room()

func _generate_next_endless_room() -> void:
	var main = get_tree().current_scene
	if main == null:
		return

	var is_boss: bool = dungeon_depth > 0 and dungeon_depth % 5 == 0
	var room := RoomGenerator.generate_room(dungeon_depth, _endless_current_offset_x, is_boss)
	main.add_child(room)
	_endless_rooms.append(room)

	# Add lights
	var lights_node := main.get_node_or_null("TorchLights")
	if lights_node == null:
		lights_node = Node2D.new()
		lights_node.name = "TorchLights_Endless"
		main.add_child(lights_node)
	RoomGenerator.add_torch_lights(lights_node, _endless_current_offset_x)

	# Add door blocker at right side of new room
	var blocker_pos := Vector2(
		_endless_current_offset_x + ROOM_W - 32,
		360
	)
	_endless_blocker = RoomGenerator.add_door_blocker(
		main, "DoorBlocker_endless", blocker_pos
	)

	# Spawn enemies
	_endless_enemy_count = 0
	var enemies := RoomGenerator.spawn_enemies_for_room(room, dungeon_depth, is_boss, main)
	for enemy in enemies:
		# Connect death signals
		if enemy.has_signal("died"):
			if enemy.get_script() == load("res://scripts/boss_controller.gd"):
				enemy.died.connect(_on_boss_died)
			else:
				enemy.died.connect(_on_enemy_died)
		_endless_enemy_count += 1

	# Clean up old rooms (keep max 2)
	while _endless_rooms.size() > 2:
		var old_room: Node2D = _endless_rooms.pop_front()
		old_room.queue_free()

	room_changed.emit(dungeon_depth)

func _open_endless_door() -> void:
	if _endless_blocker and is_instance_valid(_endless_blocker):
		var visual = _endless_blocker.get_node_or_null("Visual")
		if visual:
			var tween := create_tween()
			tween.tween_property(visual, ^"modulate", Color(1, 1, 1, 0), 0.5)
			tween.tween_callback(_endless_blocker.queue_free)
		else:
			_endless_blocker.queue_free()
		_endless_blocker = null

	# Generate next room after short delay
	dungeon_depth += 1
	_endless_current_offset_x += ROOM_W
	get_tree().create_timer(0.5).timeout.connect(_generate_next_endless_room)

func player_died() -> void:
	if is_game_over:
		return
	is_game_over = true
	game_over.emit(false)
	get_tree().create_timer(1.5).timeout.connect(_go_to_shop)

func _go_to_shop() -> void:
	SaveManager.add_gold(run_gold)
	SaveManager.save_game()
	run_gold = 0
	get_tree().change_scene_to_file("res://scenes/upgrade_shop.tscn")

func reset_for_new_run() -> void:
	is_game_over = false
	enemies_per_room = [0, 0, 0]
	run_gold = 0
	current_room = 0
	player_ref = null
	endless_mode = false
	dungeon_depth = 0
	_endless_enemy_count = 0
	_endless_rooms.clear()
	_endless_current_offset_x = 0.0
	_endless_blocker = null

func update_current_room() -> void:
	if player_ref == null:
		return
	if endless_mode:
		return  # room tracking handled by dungeon_depth in endless mode
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
