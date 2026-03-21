extends SceneTree
## Presentation video script — ~30 second cinematic showcase of Dungeon Blade
## Phases: title overview -> room 1 combat -> room 2 combat -> boss fight -> victory

var _frame: int = 0
var _cam: Camera2D
var _scene_root: Node
var _player: CharacterBody2D
var _player_cam: Camera2D
var _gm: Node

# Room dimensions
const ROOM_W := 1280
const ROOM_H := 720

func _initialize() -> void:
	print("Presentation: Dungeon Blade cinematic")

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	_scene_root = main_scene.instantiate()
	root.add_child(_scene_root)

	# Find GameManager
	for child in root.get_children():
		if child.name == "GameManager":
			_gm = child
			break

	# Get player
	_player = _scene_root.get_node_or_null("Player") as CharacterBody2D
	if _player:
		_player_cam = _player.get_node_or_null("Camera2D")
		if _player_cam:
			_player_cam.enabled = false
		# Make player invincible for presentation
		_player.max_hp = 99999
		_player.hp = 99999

	# Create cinematic camera
	_cam = Camera2D.new()
	_cam.name = "CinematicCamera"
	_cam.position_smoothing_enabled = true
	_cam.position_smoothing_speed = 4.0
	_cam.position = Vector2(640, 360)
	_scene_root.add_child(_cam)
	_cam.make_current()

func _process(delta: float) -> bool:
	_frame += 1

	# Override player camera every frame
	if _player_cam:
		_player_cam.enabled = false
	if _cam:
		_cam.make_current()

	# ===== PHASE 1: Title / Room 1 Overview (frames 1-90, 3 sec) =====
	if _frame <= 90:
		_phase_overview()

	# ===== PHASE 2: Player moves through Room 1, kills enemies (frames 91-270, 6 sec) =====
	elif _frame <= 270:
		_phase_room1_combat()

	# ===== PHASE 3: Transition to Room 2 (frames 271-360, 3 sec) =====
	elif _frame <= 360:
		_phase_room_transition(1)

	# ===== PHASE 4: Room 2 combat (frames 361-510, 5 sec) =====
	elif _frame <= 510:
		_phase_room2_combat()

	# ===== PHASE 5: Transition to Room 3 (frames 511-570, 2 sec) =====
	elif _frame <= 570:
		_phase_room_transition(2)

	# ===== PHASE 6: Boss fight showcase (frames 571-780, 7 sec) =====
	elif _frame <= 780:
		_phase_boss_fight()

	# ===== PHASE 7: Victory (frames 781-900, 4 sec) =====
	elif _frame <= 900:
		_phase_victory()

	return false

# ---------------------------------------------------------------------------
# Phase implementations
# ---------------------------------------------------------------------------

func _phase_overview() -> void:
	# Slow zoom out to show the dungeon room atmosphere
	if _frame <= 30:
		# Start zoomed in on the player
		_cam.zoom = Vector2(1.5, 1.5).lerp(Vector2(1.0, 1.0), float(_frame) / 30.0)
		_cam.position = Vector2(640, 360)
	elif _frame <= 60:
		# Pan across Room 1
		var t: float = float(_frame - 30) / 30.0
		_cam.position = Vector2(640, 360).lerp(Vector2(640, 400), t)
		_cam.zoom = Vector2(1.0, 1.0)
	else:
		# Settle and zoom back to normal
		var t: float = float(_frame - 60) / 30.0
		_cam.position = Vector2(640, 360)
		_cam.zoom = Vector2(1.0, 1.0).lerp(Vector2(1.2, 1.2), t)

func _phase_room1_combat() -> void:
	_release_all_movement()
	_follow_player_smooth()

	var phase_frame: int = _frame - 90

	# Move player toward enemies
	if phase_frame == 1:
		Input.action_press("move_right")
	if phase_frame == 20:
		Input.action_release("move_right")
		Input.action_press("move_down")
	if phase_frame == 30:
		Input.action_release("move_down")
	# Move toward enemy positions
	if phase_frame == 35:
		Input.action_press("move_right")
	if phase_frame == 50:
		Input.action_release("move_right")

	# Attack sequence
	if phase_frame >= 55 and phase_frame <= 90:
		if phase_frame % 8 == 0:
			Input.action_press("attack")
		if phase_frame % 8 == 2:
			Input.action_release("attack")

	# Move around to find enemies
	if phase_frame == 95:
		Input.action_press("move_down")
	if phase_frame == 105:
		Input.action_release("move_down")
		Input.action_press("move_right")
	if phase_frame == 120:
		Input.action_release("move_right")

	# More attacks
	if phase_frame >= 125 and phase_frame <= 145:
		if phase_frame % 8 == 0:
			Input.action_press("attack")
		if phase_frame % 8 == 2:
			Input.action_release("attack")

	# Kill remaining room 1 enemies to proceed
	if phase_frame == 155:
		_kill_room_enemies(0)
		_release_all_movement()
		print("Room 1 cleared")

func _phase_room_transition(room_idx: int) -> void:
	_release_all_movement()

	var base_frame: int
	if room_idx == 1:
		base_frame = 270
	else:
		base_frame = 510
	var phase_frame: int = _frame - base_frame

	# Pan camera toward next room
	var target_x: float = float(room_idx) * ROOM_W + ROOM_W * 0.5
	var start_x: float = float(room_idx - 1) * ROOM_W + ROOM_W * 0.5
	var total_frames: int
	if room_idx == 1:
		total_frames = 90
	else:
		total_frames = 60
	var t: float = clampf(float(phase_frame) / float(total_frames), 0.0, 1.0)
	# Smooth step
	t = t * t * (3.0 - 2.0 * t)
	_cam.position = Vector2(lerpf(start_x, target_x, t), 360.0)
	_cam.position_smoothing_enabled = false

	# Move player to next room
	if phase_frame == 1:
		Input.action_press("move_right")
	if phase_frame == total_frames - 10:
		Input.action_release("move_right")
		# Teleport player to next room entrance if needed
		if _player and _player.global_position.x < float(room_idx) * ROOM_W + 100:
			_player.global_position.x = float(room_idx) * ROOM_W + 150
			_player.global_position.y = 360.0

func _phase_room2_combat() -> void:
	_release_all_movement()
	_cam.position_smoothing_enabled = true
	_follow_player_smooth()

	var phase_frame: int = _frame - 360

	# Move around room 2
	if phase_frame == 1:
		Input.action_press("move_down")
	if phase_frame == 15:
		Input.action_release("move_down")
		Input.action_press("move_right")
	if phase_frame == 35:
		Input.action_release("move_right")

	# Attack enemies
	if phase_frame >= 40 and phase_frame <= 70:
		if phase_frame % 7 == 0:
			Input.action_press("attack")
		if phase_frame % 7 == 2:
			Input.action_release("attack")

	# Move more
	if phase_frame == 75:
		Input.action_press("move_up")
	if phase_frame == 85:
		Input.action_release("move_up")
		Input.action_press("move_right")
	if phase_frame == 100:
		Input.action_release("move_right")

	# More attacks
	if phase_frame >= 105 and phase_frame <= 120:
		if phase_frame % 7 == 0:
			Input.action_press("attack")
		if phase_frame % 7 == 2:
			Input.action_release("attack")

	# Kill remaining enemies
	if phase_frame == 130:
		_kill_room_enemies(1)
		_release_all_movement()
		print("Room 2 cleared")

func _phase_boss_fight() -> void:
	_release_all_movement()
	_cam.position_smoothing_enabled = true

	var phase_frame: int = _frame - 570

	# Show boss room overview first
	if phase_frame <= 30:
		_cam.position = Vector2(ROOM_W * 2 + ROOM_W * 0.5, 360)
		_cam.zoom = Vector2(1.0, 1.0).lerp(Vector2(0.9, 0.9), float(phase_frame) / 30.0)
		return

	# Zoom to normal and follow player
	_cam.zoom = Vector2(1.0, 1.0)
	_follow_player_smooth()

	# Teleport player into room 3 if needed
	if phase_frame == 31:
		if _player and _player.global_position.x < ROOM_W * 2 + 100:
			_player.global_position = Vector2(ROOM_W * 2 + 200, 360)

	# Move toward boss
	if phase_frame == 35:
		Input.action_press("move_right")
	if phase_frame == 55:
		Input.action_release("move_right")

	# Dance around and attack
	if phase_frame == 60:
		Input.action_press("move_up")
	if phase_frame == 70:
		Input.action_release("move_up")
		Input.action_press("move_right")
	if phase_frame == 80:
		Input.action_release("move_right")

	# Attack the boss
	if phase_frame >= 85 and phase_frame <= 110:
		if phase_frame % 6 == 0:
			Input.action_press("attack")
		if phase_frame % 6 == 2:
			Input.action_release("attack")

	# Dodge and move
	if phase_frame == 115:
		Input.action_press("move_left")
	if phase_frame == 125:
		Input.action_release("move_left")
		Input.action_press("move_down")
	if phase_frame == 135:
		Input.action_release("move_down")
		Input.action_press("move_right")
	if phase_frame == 145:
		Input.action_release("move_right")

	# More attacks
	if phase_frame >= 150 and phase_frame <= 170:
		if phase_frame % 6 == 0:
			Input.action_press("attack")
		if phase_frame % 6 == 2:
			Input.action_release("attack")

	# Kill boss at frame 180 for dramatic timing
	if phase_frame == 180:
		var boss = _scene_root.get_node_or_null("Boss")
		if boss and boss.has_method("take_damage") and is_instance_valid(boss):
			boss.take_damage(999)
			print("Boss defeated!")
		_release_all_movement()

func _phase_victory() -> void:
	_release_all_movement()

	var phase_frame: int = _frame - 780

	# Hold on the player/boss area, zoom in on victory
	if _player and is_instance_valid(_player):
		_cam.position = _player.global_position
	else:
		_cam.position = Vector2(ROOM_W * 2 + ROOM_W * 0.5, 360)

	# Slow zoom in for dramatic effect
	var t: float = clampf(float(phase_frame) / 120.0, 0.0, 1.0)
	_cam.zoom = Vector2(1.0, 1.0).lerp(Vector2(1.3, 1.3), t)

	if phase_frame == 30:
		print("Victory screen showing")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _follow_player_smooth() -> void:
	if _player and _cam and is_instance_valid(_player):
		var target: Vector2 = _player.global_position
		_cam.position = _cam.position.lerp(target, 0.15)

func _release_all_movement() -> void:
	Input.action_release("move_up")
	Input.action_release("move_down")
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("attack")

func _kill_room_enemies(room_idx: int) -> void:
	var to_kill: Array = []
	for child in _scene_root.get_children():
		if child.name.begins_with("Enemy_R%d" % (room_idx + 1)):
			to_kill.append(child)
	for enemy in to_kill:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(999)
