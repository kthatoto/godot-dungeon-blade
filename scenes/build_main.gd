extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_main.gd

func _initialize() -> void:
	var root := Node2D.new()
	root.name = "Main"

	# Room containers
	var room1 := Node2D.new()
	room1.name = "Room1"
	root.add_child(room1)

	var room2 := Node2D.new()
	room2.name = "Room2"
	room2.position = Vector2(1280, 0)
	root.add_child(room2)

	var room3 := Node2D.new()
	room3.name = "Room3"
	room3.position = Vector2(2560, 0)
	root.add_child(room3)

	# Player
	var player = load("res://scenes/player.tscn").instantiate()
	player.position = Vector2(640, 400)
	root.add_child(player)

	# Camera following player
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)

	# HUD
	var canvas_layer := CanvasLayer.new()
	canvas_layer.name = "CanvasLayer"
	canvas_layer.layer = 1
	root.add_child(canvas_layer)

	var hud := Control.new()
	hud.name = "HUD"
	hud.set_script(load("res://scripts/hud_controller.gd"))
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(hud)

	_set_owners(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/main.tscn")
	print("Saved: res://scenes/main.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
