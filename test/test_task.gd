extends SceneTree
## Test harness for Task 1: Visual Architecture
## Verify: dark dungeon room, stone walls, floor tiles, hero among skeletons, HUD

var _frame: int = 0
var _cam: Camera2D
var _scene_root: Node
var _player_cam: Camera2D

func _initialize() -> void:
	print("Test: Visual Architecture")

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	_scene_root = main_scene.instantiate()
	root.add_child(_scene_root)

	# Disable player's camera
	var player = _scene_root.get_node_or_null("Player")
	if player:
		_player_cam = player.get_node_or_null("Camera2D")
		if _player_cam:
			_player_cam.enabled = false

	# Create our own independent camera
	_cam = Camera2D.new()
	_cam.name = "TestCamera"
	_cam.position_smoothing_enabled = false
	_cam.position = Vector2(640, 360)  # Room 1 center
	_scene_root.add_child(_cam)
	_cam.make_current()

	# Assertions
	if player:
		print("ASSERT PASS: Player exists at position " + str(player.position))
		var player_sprite = player.get_node_or_null("Sprite2D")
		if player_sprite and player_sprite.texture:
			print("ASSERT PASS: Player has texture")
		else:
			print("ASSERT FAIL: Player missing texture")
	else:
		print("ASSERT FAIL: Player not found")

	var enemy_count: int = 0
	for child in _scene_root.get_children():
		if child.name.begins_with("Enemy"):
			enemy_count += 1
	if enemy_count >= 3:
		print("ASSERT PASS: Found %d enemies" % enemy_count)
	else:
		print("ASSERT FAIL: Expected at least 3 enemies, found %d" % enemy_count)

	var boss = _scene_root.get_node_or_null("Boss")
	if boss:
		print("ASSERT PASS: Boss exists at position " + str(boss.position))
	else:
		print("ASSERT FAIL: Boss not found")

	var room1 = _scene_root.get_node_or_null("Room1")
	var room2 = _scene_root.get_node_or_null("Room2")
	var room3 = _scene_root.get_node_or_null("Room3")
	if room1 and room2 and room3:
		print("ASSERT PASS: All 3 rooms exist")
	else:
		print("ASSERT FAIL: Missing rooms")

	var hud = _scene_root.get_node_or_null("CanvasLayer/HUD")
	if hud:
		print("ASSERT PASS: HUD exists")
		var hp_bar = hud.get_node_or_null("InfoPanel/VBox/HPRow/HPBar")
		if hp_bar:
			print("ASSERT PASS: HP bar found")
		else:
			print("ASSERT FAIL: HP bar missing")
	else:
		print("ASSERT FAIL: HUD not found")

func _process(delta: float) -> bool:
	_frame += 1

	if not _cam:
		return false

	# Disable player camera every frame (quirk: chase camera re-assertion)
	if _player_cam:
		_player_cam.enabled = false

	# Frame 1-4: Room 1 — player among skeleton enemies
	if _frame <= 4:
		_cam.position = Vector2(640, 360)

	# Frame 5-7: Room 2 — more enemies
	elif _frame <= 7:
		_cam.position = Vector2(1920, 360)

	# Frame 8-10: Room 3 — boss
	elif _frame <= 10:
		_cam.position = Vector2(3200, 360)

	_cam.make_current()
	return false
