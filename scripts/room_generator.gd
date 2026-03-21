extends RefCounted
## res://scripts/room_generator.gd — Procedural room generation for endless mode

const ROOM_W := 1280
const ROOM_H := 720
const TILE := 32
const WALL_THICKNESS := 2

# --- Theme system ---
const THEMES := {
	"dungeon": {
		"bg_color": Color(0.04, 0.03, 0.02),
		"light_color": Color(1.0, 0.8, 0.4),
		"wall_modulate": Color(1.0, 1.0, 1.0),
		"floor_modulate": Color(1.0, 1.0, 1.0),
	},
	"cave": {
		"bg_color": Color(0.02, 0.04, 0.02),
		"light_color": Color(0.6, 0.9, 0.7),
		"wall_modulate": Color(0.7, 0.9, 0.7),
		"floor_modulate": Color(0.8, 0.9, 0.8),
	},
	"crypt": {
		"bg_color": Color(0.03, 0.02, 0.05),
		"light_color": Color(0.7, 0.5, 1.0),
		"wall_modulate": Color(0.8, 0.7, 0.9),
		"floor_modulate": Color(0.8, 0.75, 0.9),
	},
	"lava": {
		"bg_color": Color(0.06, 0.02, 0.01),
		"light_color": Color(1.0, 0.4, 0.1),
		"wall_modulate": Color(1.0, 0.8, 0.7),
		"floor_modulate": Color(1.0, 0.85, 0.75),
	},
}

static func get_theme_for_depth(depth: int) -> String:
	var themes := THEMES.keys()
	return themes[(depth / 5) % themes.size()]

static func generate_room(depth: int, offset_x: float, is_boss_room: bool) -> Node2D:
	var room := Node2D.new()
	room.name = "Room_depth_%d" % depth
	room.position = Vector2(offset_x, 0)
	room.z_index = -1  # render below player and enemies

	var theme_name := get_theme_for_depth(depth)
	var theme: Dictionary = THEMES[theme_name]

	# Background
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = theme["bg_color"]
	bg.size = Vector2(ROOM_W, ROOM_H)
	room.add_child(bg)

	# Floor
	_build_floor(room, theme["floor_modulate"])
	# Walls (with left and right doorways)
	_build_walls(room, true, true, theme["wall_modulate"])
	# Torches
	_build_torches(room)

	return room

static func spawn_enemies_for_room(room: Node2D, depth: int, is_boss_room: bool, parent: Node2D) -> Array[CharacterBody2D]:
	var enemies: Array[CharacterBody2D] = []
	var enemy_scene: PackedScene = load("res://scenes/enemy.tscn")
	var boss_scene: PackedScene = load("res://scenes/boss.tscn")
	var offset_x: float = room.position.x

	# Check for optional enemy scenes
	var has_archer: bool = ResourceLoader.exists("res://scenes/archer.tscn")
	var has_bat: bool = ResourceLoader.exists("res://scenes/bat.tscn")
	var has_necro: bool = ResourceLoader.exists("res://scenes/necromancer.tscn")

	if is_boss_room:
		# Boss type depends on depth
		var boss: CharacterBody2D
		if depth % 10 == 0 and has_necro:
			var necro_scene: PackedScene = load("res://scenes/necromancer.tscn")
			boss = necro_scene.instantiate() as CharacterBody2D
			boss.name = "Necromancer_d%d" % depth
			boss.position = Vector2(offset_x + ROOM_W * 0.7, ROOM_H * 0.5)
			boss.apply_depth_scaling(depth)
			parent.add_child(boss)
			enemies.append(boss)
		else:
			boss = boss_scene.instantiate() as CharacterBody2D
			boss.name = "Boss_d%d" % depth
			boss.position = Vector2(offset_x + ROOM_W * 0.7, ROOM_H * 0.5)
			boss.apply_depth_scaling(depth)
			parent.add_child(boss)
			enemies.append(boss)

		# Add minions (1-2 for boss rooms)
		var add_count := clampi(depth / 5, 1, 2)
		for i in range(add_count):
			var enemy := enemy_scene.instantiate() as CharacterBody2D
			enemy.name = "Enemy_d%d_%d" % [depth, i]
			enemy.position = Vector2(
				offset_x + randf_range(200, ROOM_W - 200),
				randf_range(150, ROOM_H - 150)
			)
			enemy.apply_depth_scaling(depth)
			parent.add_child(enemy)
			enemies.append(enemy)
	else:
		# Normal room: variety based on depth
		var count := clampi(3 + depth / 2, 3, 8)
		for i in range(count):
			var enemy: CharacterBody2D
			if depth <= 2:
				# Early depths: mostly normal skeletons + 1 bat
				if i == 0 and has_bat:
					var bat_scene: PackedScene = load("res://scenes/bat.tscn")
					enemy = bat_scene.instantiate() as CharacterBody2D
					enemy.name = "Bat_d%d_%d" % [depth, i]
					enemy.apply_depth_scaling(depth)
				else:
					enemy = enemy_scene.instantiate() as CharacterBody2D
					enemy.name = "Enemy_d%d_%d" % [depth, i]
					enemy.apply_depth_scaling(depth)
			else:
				# Depth 3+: weighted random variety
				var roll := randf()
				if roll < 0.3:
					# 30% strong skeleton
					enemy = enemy_scene.instantiate() as CharacterBody2D
					enemy.name = "StrongEnemy_d%d_%d" % [depth, i]
					enemy.apply_depth_scaling(depth)
					enemy.configure_variant("strong")
				elif roll < 0.5 and has_archer:
					# 20% archer
					var archer_scene: PackedScene = load("res://scenes/archer.tscn")
					enemy = archer_scene.instantiate() as CharacterBody2D
					enemy.name = "Archer_d%d_%d" % [depth, i]
					enemy.apply_depth_scaling(depth)
				elif roll < 0.7 and has_bat:
					# 20% bat
					var bat_scene: PackedScene = load("res://scenes/bat.tscn")
					enemy = bat_scene.instantiate() as CharacterBody2D
					enemy.name = "Bat_d%d_%d" % [depth, i]
					enemy.apply_depth_scaling(depth)
				else:
					# 30% normal (or fallback if scenes missing)
					enemy = enemy_scene.instantiate() as CharacterBody2D
					enemy.name = "Enemy_d%d_%d" % [depth, i]
					enemy.apply_depth_scaling(depth)

			enemy.position = Vector2(
				offset_x + randf_range(200, ROOM_W - 200),
				randf_range(150, ROOM_H - 150)
			)
			parent.add_child(enemy)
			enemies.append(enemy)

	return enemies

static func _build_floor(room: Node2D, modulate_color: Color = Color.WHITE) -> void:
	var floor_tex: Texture2D = load("res://assets/img/floor_tile.png")
	var floor_node := Node2D.new()
	floor_node.name = "Floor"
	room.add_child(floor_node)

	var start_x: int = WALL_THICKNESS * TILE
	var start_y: int = WALL_THICKNESS * TILE
	var end_x: int = ROOM_W - WALL_THICKNESS * TILE
	var end_y: int = ROOM_H - WALL_THICKNESS * TILE

	var x: int = start_x
	while x < end_x:
		var y: int = start_y
		while y < end_y:
			var s := Sprite2D.new()
			s.texture = floor_tex
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.position = Vector2(x + TILE / 2, y + TILE / 2)
			s.modulate = modulate_color
			floor_node.add_child(s)
			y += TILE
		x += TILE

static func _build_walls(room: Node2D, has_left_door: bool, has_right_door: bool, modulate_color: Color = Color.WHITE) -> void:
	var wall_tex: Texture2D = load("res://assets/img/wall_tile.png")
	var walls := Node2D.new()
	walls.name = "Walls"
	room.add_child(walls)

	# Top wall
	var x: int = 0
	while x < ROOM_W:
		var y: int = 0
		while y < WALL_THICKNESS * TILE:
			var s := Sprite2D.new()
			s.texture = wall_tex
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.position = Vector2(x + TILE / 2, y + TILE / 2)
			s.modulate = modulate_color
			walls.add_child(s)
			y += TILE
		x += TILE

	# Bottom wall
	x = 0
	while x < ROOM_W:
		var y: int = ROOM_H - WALL_THICKNESS * TILE
		while y < ROOM_H:
			var s := Sprite2D.new()
			s.texture = wall_tex
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.position = Vector2(x + TILE / 2, y + TILE / 2)
			s.modulate = modulate_color
			walls.add_child(s)
			y += TILE
		x += TILE

	# Left wall
	var y: int = WALL_THICKNESS * TILE
	while y < ROOM_H - WALL_THICKNESS * TILE:
		var is_doorway: bool = has_left_door and y >= 280 and y < 440
		if not is_doorway:
			var wall_x: int = 0
			while wall_x < WALL_THICKNESS * TILE:
				var s := Sprite2D.new()
				s.texture = wall_tex
				s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				s.position = Vector2(wall_x + TILE / 2, y + TILE / 2)
				s.modulate = modulate_color
				walls.add_child(s)
				wall_x += TILE
		y += TILE

	# Right wall
	y = WALL_THICKNESS * TILE
	while y < ROOM_H - WALL_THICKNESS * TILE:
		var is_doorway: bool = has_right_door and y >= 280 and y < 440
		if not is_doorway:
			var wall_x: int = ROOM_W - WALL_THICKNESS * TILE
			while wall_x < ROOM_W:
				var s := Sprite2D.new()
				s.texture = wall_tex
				s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				s.position = Vector2(wall_x + TILE / 2, y + TILE / 2)
				s.modulate = modulate_color
				walls.add_child(s)
				wall_x += TILE
		y += TILE

	# Wall collisions
	_add_wall_collision(walls, has_left_door, has_right_door)

static func _add_wall_collision(walls: Node2D, has_left_door: bool, has_right_door: bool) -> void:
	# Top
	var top := StaticBody2D.new()
	top.collision_layer = 4
	top.collision_mask = 0
	top.position = Vector2(ROOM_W / 2, WALL_THICKNESS * TILE / 2)
	var top_shape := CollisionShape2D.new()
	var top_rect := RectangleShape2D.new()
	top_rect.size = Vector2(ROOM_W, WALL_THICKNESS * TILE)
	top_shape.shape = top_rect
	top.add_child(top_shape)
	walls.add_child(top)

	# Bottom
	var bot := StaticBody2D.new()
	bot.collision_layer = 4
	bot.collision_mask = 0
	bot.position = Vector2(ROOM_W / 2, ROOM_H - WALL_THICKNESS * TILE / 2)
	var bot_shape := CollisionShape2D.new()
	var bot_rect := RectangleShape2D.new()
	bot_rect.size = Vector2(ROOM_W, WALL_THICKNESS * TILE)
	bot_shape.shape = bot_rect
	bot.add_child(bot_shape)
	walls.add_child(bot)

	# Left wall (split for doorway)
	if has_left_door:
		_add_split_wall(walls, true, true)
	else:
		var lw := StaticBody2D.new()
		lw.collision_layer = 4
		lw.collision_mask = 0
		lw.position = Vector2(WALL_THICKNESS * TILE / 2, ROOM_H / 2)
		var lw_shape := CollisionShape2D.new()
		var lw_rect := RectangleShape2D.new()
		lw_rect.size = Vector2(WALL_THICKNESS * TILE, ROOM_H)
		lw_shape.shape = lw_rect
		lw.add_child(lw_shape)
		walls.add_child(lw)

	# Right wall (split for doorway)
	if has_right_door:
		_add_split_wall(walls, false, true)
	else:
		var rw := StaticBody2D.new()
		rw.collision_layer = 4
		rw.collision_mask = 0
		rw.position = Vector2(ROOM_W - WALL_THICKNESS * TILE / 2, ROOM_H / 2)
		var rw_shape := CollisionShape2D.new()
		var rw_rect := RectangleShape2D.new()
		rw_rect.size = Vector2(WALL_THICKNESS * TILE, ROOM_H)
		rw_shape.shape = rw_rect
		rw.add_child(rw_shape)
		walls.add_child(rw)

static func _add_split_wall(walls: Node2D, is_left: bool, _has_door: bool) -> void:
	var x_pos: float = WALL_THICKNESS * TILE / 2 if is_left else ROOM_W - WALL_THICKNESS * TILE / 2
	# Upper segment
	var upper_h: float = 280.0 - WALL_THICKNESS * TILE
	var upper := StaticBody2D.new()
	upper.collision_layer = 4
	upper.collision_mask = 0
	upper.position = Vector2(x_pos, WALL_THICKNESS * TILE + upper_h / 2)
	var us := CollisionShape2D.new()
	var ur := RectangleShape2D.new()
	ur.size = Vector2(WALL_THICKNESS * TILE, upper_h)
	us.shape = ur
	upper.add_child(us)
	walls.add_child(upper)
	# Lower segment
	var lower_h: float = ROOM_H - WALL_THICKNESS * TILE - 440.0
	var lower := StaticBody2D.new()
	lower.collision_layer = 4
	lower.collision_mask = 0
	lower.position = Vector2(x_pos, 440.0 + lower_h / 2)
	var ls := CollisionShape2D.new()
	var lr := RectangleShape2D.new()
	lr.size = Vector2(WALL_THICKNESS * TILE, lower_h)
	ls.shape = lr
	lower.add_child(ls)
	walls.add_child(lower)

static func _build_torches(room: Node2D) -> void:
	var torch_tex: Texture2D = load("res://assets/img/torch.png")
	var torches := Node2D.new()
	torches.name = "Torches"
	room.add_child(torches)

	var positions := [
		Vector2(80, 76), Vector2(400, 80), Vector2(860, 78), Vector2(1190, 82),
		Vector2(90, 636), Vector2(420, 640), Vector2(850, 638), Vector2(1180, 642),
		Vector2(76, 260), Vector2(76, 480), Vector2(1204, 260), Vector2(1204, 500),
	]
	for i in range(positions.size()):
		var s := Sprite2D.new()
		s.texture = torch_tex
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = positions[i]
		s.scale = Vector2(2, 2)
		torches.add_child(s)

static func add_door_blocker(parent: Node2D, blocker_name: String, pos: Vector2) -> StaticBody2D:
	var blocker := StaticBody2D.new()
	blocker.name = blocker_name
	blocker.collision_layer = 4
	blocker.collision_mask = 0
	blocker.position = pos

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WALL_THICKNESS * TILE, 160)
	shape.shape = rect
	blocker.add_child(shape)

	var visual := ColorRect.new()
	visual.name = "Visual"
	visual.color = Color(0.6, 0.3, 0.1, 0.5)
	visual.size = Vector2(WALL_THICKNESS * TILE, 160)
	visual.position = Vector2(-WALL_THICKNESS * TILE / 2, -80)
	blocker.add_child(visual)

	parent.add_child(blocker)
	return blocker

static func add_torch_lights(parent: Node2D, offset_x: float, light_color: Color = Color(1.0, 0.8, 0.4)) -> void:
	var positions := [
		Vector2(80, 80), Vector2(400, 80), Vector2(880, 80), Vector2(1200, 80),
		Vector2(80, 640), Vector2(400, 640), Vector2(880, 640), Vector2(1200, 640),
		Vector2(76, 260), Vector2(76, 480), Vector2(1204, 260), Vector2(1204, 500),
		Vector2(640, 360),
	]
	for i in range(positions.size()):
		var light := PointLight2D.new()
		light.position = Vector2(positions[i].x + offset_x, positions[i].y)
		light.color = light_color
		var is_center: bool = i == positions.size() - 1
		light.energy = 1.5 if is_center else 0.9
		light.texture = _create_light_texture()
		light.texture_scale = 6.0 if is_center else 3.5
		parent.add_child(light)

static func _create_light_texture() -> Texture2D:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var center := Vector2(64, 64)
	for y in range(128):
		for x in range(128):
			var dist: float = Vector2(x, y).distance_to(center) / 64.0
			var alpha: float = clampf(1.0 - dist, 0.0, 1.0)
			alpha = alpha * alpha
			img.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(img)
