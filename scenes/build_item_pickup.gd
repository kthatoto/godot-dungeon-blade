extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_item_pickup.gd

func _initialize() -> void:
	print("Building item_pickup scene...")

	var root := Area2D.new()
	root.name = "ItemPickup"
	root.set_script(load("res://scripts/item_pickup.gd"))
	# Detect player body via body_entered
	root.collision_layer = 0
	root.collision_mask = 1  # player layer
	root.monitoring = true
	root.monitorable = false

	# Collision shape
	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	col.shape = circle
	root.add_child(col)

	# Visual: 16x16 colored rect centered
	var visual := ColorRect.new()
	visual.name = "Visual"
	visual.size = Vector2(16, 16)
	visual.position = Vector2(-8, -8)
	visual.color = Color.WHITE  # set at runtime
	root.add_child(visual)

	# Name label above
	var label := Label.new()
	label.name = "NameLabel"
	label.text = ""
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-40, -28)
	label.size = Vector2(80, 20)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	root.add_child(label)

	_set_owners(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Pack failed: " + str(err))
		quit(1)
		return

	err = ResourceSaver.save(packed, "res://scenes/item_pickup.tscn")
	if err != OK:
		push_error("Save failed: " + str(err))
		quit(1)
		return

	print("Saved: res://scenes/item_pickup.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
