extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_arrow.gd

func _initialize() -> void:
	print("Building arrow scene...")

	var root := Area2D.new()
	root.name = "Arrow"
	root.set_script(load("res://scripts/arrow_projectile.gd"))
	root.collision_layer = 0
	root.collision_mask = 1 + 4  # player + walls
	root.monitoring = true
	root.monitorable = false

	# Collision shape
	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 3)
	col.shape = rect
	root.add_child(col)

	# Visual: thin white rectangle
	var sprite := ColorRect.new()
	sprite.name = "Sprite"
	sprite.size = Vector2(12, 3)
	sprite.position = Vector2(-6, -1.5)
	sprite.color = Color(1.0, 1.0, 1.0, 0.9)
	root.add_child(sprite)

	_set_owners(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Pack failed: " + str(err))
		quit(1)
		return

	err = ResourceSaver.save(packed, "res://scenes/arrow.tscn")
	if err != OK:
		push_error("Save failed: " + str(err))
		quit(1)
		return

	print("Saved: res://scenes/arrow.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
