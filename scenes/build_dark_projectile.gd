extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_dark_projectile.gd

func _initialize() -> void:
	print("Building dark projectile scene...")

	var root := Area2D.new()
	root.name = "DarkProjectile"
	root.set_script(load("res://scripts/dark_projectile.gd"))
	root.collision_layer = 0
	root.collision_mask = 1 + 4  # player + walls
	root.monitoring = true
	root.monitorable = false

	# Collision shape
	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	col.shape = circle
	root.add_child(col)

	# Visual: dark purple circle
	var sprite := ColorRect.new()
	sprite.name = "Sprite"
	sprite.size = Vector2(12, 12)
	sprite.position = Vector2(-6, -6)
	sprite.color = Color(0.4, 0.1, 0.6, 0.9)
	root.add_child(sprite)

	# Purple glow effect (larger, semi-transparent)
	var glow := ColorRect.new()
	glow.name = "Glow"
	glow.size = Vector2(20, 20)
	glow.position = Vector2(-10, -10)
	glow.color = Color(0.5, 0.1, 0.8, 0.3)
	root.add_child(glow)

	# Light
	var light := PointLight2D.new()
	light.name = "Light"
	light.color = Color(0.5, 0.1, 0.8)
	light.energy = 1.0
	light.texture = _create_light_texture()
	light.texture_scale = 1.5
	root.add_child(light)

	_set_owners(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Pack failed: " + str(err))
		quit(1)
		return

	err = ResourceSaver.save(packed, "res://scenes/dark_projectile.tscn")
	if err != OK:
		push_error("Save failed: " + str(err))
		quit(1)
		return

	print("Saved: res://scenes/dark_projectile.tscn")
	quit(0)

func _create_light_texture() -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var center := Vector2(32, 32)
	for y in range(64):
		for x in range(64):
			var dist: float = Vector2(x, y).distance_to(center) / 32.0
			var alpha: float = clampf(1.0 - dist, 0.0, 1.0)
			alpha = alpha * alpha
			img.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(img)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
