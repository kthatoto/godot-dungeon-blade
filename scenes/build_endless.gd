extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_endless.gd
## Builds a minimal endless mode scene (rooms generated at runtime by GameManager)

func _initialize() -> void:
	print("Building endless scene...")

	var root := Node2D.new()
	root.name = "Endless"
	root.set_script(load("res://scripts/endless_scene.gd"))

	# Player
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player = player_scene.instantiate()
	player.name = "Player"
	player.position = Vector2(200, 360)
	root.add_child(player)

	# Camera on player
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)

	# HUD
	var canvas_layer := CanvasLayer.new()
	canvas_layer.name = "CanvasLayer"
	canvas_layer.layer = 10
	root.add_child(canvas_layer)

	var hud_scene: PackedScene = load("res://scenes/hud.tscn")
	var hud = hud_scene.instantiate()
	hud.name = "HUD"
	canvas_layer.add_child(hud)

	_set_owners(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Pack failed: " + str(err))
		quit(1)
		return

	err = ResourceSaver.save(packed, "res://scenes/endless.tscn")
	if err != OK:
		push_error("Save failed: " + str(err))
		quit(1)
		return

	print("Saved: res://scenes/endless.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
