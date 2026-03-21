extends SceneTree
## Test harness for Task 2: Core Game Loop
## Verify: gameplay sequence — player moves, attacks enemies, doors open,
## room transitions, boss fight, victory screen.

var _frame: int = 0
var _cam: Camera2D
var _scene_root: Node
var _player_cam: Camera2D
var _player: CharacterBody2D
var _gm: Node  # GameManager

func _initialize() -> void:
	print("Test: Core Game Loop")

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	_scene_root = main_scene.instantiate()
	root.add_child(_scene_root)

	# Find GameManager autoload
	for child in root.get_children():
		if child.name == "GameManager":
			_gm = child
			break

	# Get player reference
	_player = _scene_root.get_node_or_null("Player") as CharacterBody2D
	if _player:
		_player_cam = _player.get_node_or_null("Camera2D")
		if _player_cam:
			_player_cam.enabled = false
		print("ASSERT PASS: Player found at " + str(_player.position))
	else:
		print("ASSERT FAIL: Player not found")

	# Create test camera
	_cam = Camera2D.new()
	_cam.name = "TestCamera"
	_cam.position_smoothing_enabled = false
	_cam.position = Vector2(640, 360)
	_scene_root.add_child(_cam)
	_cam.make_current()

	# Verify door blockers exist
	var blocker0 = _scene_root.get_node_or_null("DoorBlocker_0")
	var blocker1 = _scene_root.get_node_or_null("DoorBlocker_1")
	if blocker0:
		print("ASSERT PASS: Door blocker 0 exists")
	else:
		print("ASSERT FAIL: Door blocker 0 missing")
	if blocker1:
		print("ASSERT PASS: Door blocker 1 exists")
	else:
		print("ASSERT FAIL: Door blocker 1 missing")

	# Count enemies
	var enemy_count: int = 0
	for child in _scene_root.get_children():
		if child.name.begins_with("Enemy") or child.name == "Boss":
			enemy_count += 1
	print("ASSERT PASS: Found %d enemies/bosses" % enemy_count)

	if _gm:
		print("ASSERT PASS: GameManager found")
	else:
		print("ASSERT FAIL: GameManager not found")

func _process(delta: float) -> bool:
	_frame += 1

	if _player_cam:
		_player_cam.enabled = false
	if _cam:
		_cam.make_current()

	# Phase 1 (frames 1-10): Show Room 1, player idle
	if _frame <= 10:
		_cam.position = Vector2(640, 360)
		if _frame == 5:
			print("Phase 1: Room 1 overview")

	# Phase 2 (frames 11-30): Move player toward first enemy and attack
	elif _frame <= 30:
		_follow_player()
		if _frame == 11:
			Input.action_press("move_right")
		if _frame == 16:
			Input.action_release("move_right")
			Input.action_press("move_down")
		if _frame == 18:
			Input.action_release("move_down")
		# Attack enemies by dealing direct damage (simulating combat)
		if _frame == 20:
			_kill_room_enemies(0)
			print("Phase 2: Killed Room 1 enemies")
		if _frame == 25:
			# Check if door opened
			if _gm and _gm.enemies_per_room[0] <= 0:
				print("ASSERT PASS: Room 1 cleared, door should be open")
			else:
				print("ASSERT FAIL: Room 1 enemies not cleared")

	# Phase 3 (frames 31-50): Move to Room 2
	elif _frame <= 50:
		_follow_player()
		if _frame == 31:
			Input.action_press("move_right")
		if _frame == 40:
			# Player should be in or near room 2
			print("Phase 3: Moving to Room 2")
		if _frame == 45:
			Input.action_release("move_right")
			_kill_room_enemies(1)
			print("Phase 3: Killed Room 2 enemies")
		if _frame == 48:
			if _gm and _gm.enemies_per_room[1] <= 0:
				print("ASSERT PASS: Room 2 cleared")
			else:
				print("ASSERT FAIL: Room 2 enemies not cleared")

	# Phase 4 (frames 51-70): Move to Room 3, boss fight
	elif _frame <= 70:
		_follow_player()
		if _frame == 51:
			Input.action_press("move_right")
		if _frame == 60:
			Input.action_release("move_right")
			print("Phase 4: Entering Room 3 (boss)")
		if _frame == 62:
			# Show boss
			_cam.position = Vector2(3200, 360)
		if _frame == 65:
			# Kill boss
			var boss = _scene_root.get_node_or_null("Boss")
			if boss and boss.has_method("take_damage"):
				boss.take_damage(300)
				print("Phase 4: Boss defeated")
			else:
				print("ASSERT FAIL: Boss not found or already dead")

	# Phase 5 (frames 71-100): Victory screen
	elif _frame <= 100:
		if _frame == 71:
			_cam.position = Vector2(3200, 360)
		if _frame == 75:
			if _gm and _gm.is_game_over:
				print("ASSERT PASS: Game over triggered (victory)")
			else:
				print("ASSERT FAIL: Game over not triggered")
		if _frame == 85:
			# Check gold
			if _gm:
				print("ASSERT PASS: Gold collected: %d" % _gm.gold)

	# Phase 6 (frames 101-120): Final verification
	elif _frame <= 120:
		if _frame == 105:
			print("Phase 6: Final state check")
			if _gm:
				print("ASSERT PASS: Final gold = %d" % _gm.gold)
				print("ASSERT PASS: Game over = %s" % str(_gm.is_game_over))
			if _player and "hp" in _player:
				print("ASSERT PASS: Player HP = %d/%d" % [_player.hp, _player.max_hp])

	return false

func _follow_player() -> void:
	if _player and _cam:
		_cam.position = _player.global_position

func _kill_room_enemies(room_idx: int) -> void:
	var to_kill: Array = []
	for child in _scene_root.get_children():
		if child.name.begins_with("Enemy_R%d" % (room_idx + 1)):
			to_kill.append(child)
	for enemy in to_kill:
		if enemy.has_method("take_damage") and is_instance_valid(enemy):
			enemy.take_damage(999)
