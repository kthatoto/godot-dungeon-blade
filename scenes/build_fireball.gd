extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_fireball.gd

func _initialize() -> void:
	print("Building fireball scene...")

	var root := Area2D.new()
	root.name = "Fireball"
	root.set_script(load("res://scripts/fireball_projectile.gd"))
	# Fireball collision: detect enemies (layer 2) and walls (layer 3)
	root.collision_layer = 0   # fireball itself has no layer
	root.collision_mask = 4 | 2  # walls (layer 3 = bit 4-wait no)
	# Layer 2 = enemies = bit 2, Layer 3 = walls = bit 4
	# Actually: layer 1 = bit 1, layer 2 = bit 2, layer 3 = bit 4
	root.collision_layer = 0
	root.collision_mask = 0b110  # bit 1 (layer 2: enemies) + bit 2 (layer 3: walls)
	# Correct: Godot layers are 1-indexed. mask for layer 2 = 2, layer 3 = 4
	root.collision_mask = 2 + 4  # enemies + walls
	root.monitoring = true
	root.monitorable = false

	# Collision shape
	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	col.shape = circle
	root.add_child(col)

	# Visual: orange glowing circle
	var sprite := ColorRect.new()
	sprite.name = "Sprite"
	sprite.size = Vector2(16, 16)
	sprite.position = Vector2(-8, -8)
	sprite.color = Color(1.0, 0.5, 0.1, 0.9)
	root.add_child(sprite)

	# Glow effect (larger, semi-transparent)
	var glow := ColorRect.new()
	glow.name = "Glow"
	glow.size = Vector2(24, 24)
	glow.position = Vector2(-12, -12)
	glow.color = Color(1.0, 0.3, 0.0, 0.3)
	root.add_child(glow)

	# Light
	var light := PointLight2D.new()
	light.name = "Light"
	light.color = Color(1.0, 0.5, 0.1)
	light.energy = 1.5
	light.texture = _create_light_texture()
	light.texture_scale = 2.0
	root.add_child(light)

	_set_owners(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Pack failed: " + str(err))
		quit(1)
		return

	err = ResourceSaver.save(packed, "res://scenes/fireball.tscn")
	if err != OK:
		push_error("Save failed: " + str(err))
		quit(1)
		return

	print("Saved: res://scenes/fireball.tscn")
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
