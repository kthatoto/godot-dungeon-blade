extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_main.gd

const ROOM_W := 1280
const ROOM_H := 720
const TILE := 32
const WALL_THICKNESS := 2  # in tiles

func _initialize() -> void:
	print("Building main scene...")

	var root := Node2D.new()
	root.name = "Main"

	var floor_tex: Texture2D = load("res://assets/img/floor_tile.png")
	var wall_tex: Texture2D = load("res://assets/img/wall_tile.png")
	var torch_tex: Texture2D = load("res://assets/img/torch.png")
	var doorway_tex: Texture2D = load("res://assets/img/doorway.png")
	var floor_deco_tex: Texture2D = load("res://assets/img/floor_deco.png")
	var wall_deco_tex: Texture2D = load("res://assets/img/wall_deco.png")

	# Build 3 rooms
	for room_idx in range(3):
		var room := Node2D.new()
		room.name = "Room%d" % (room_idx + 1)
		room.position = Vector2(room_idx * ROOM_W, 0)
		root.add_child(room)

		# Dark background fill
		var bg := ColorRect.new()
		bg.name = "Background"
		bg.color = Color(0.04, 0.03, 0.02)
		bg.size = Vector2(ROOM_W, ROOM_H)
		room.add_child(bg)

		# Floor tiles (inner area)
		_build_floor(room, floor_tex)

		# Floor decorations (scattered debris, cracks)
		_build_floor_decorations(room, floor_deco_tex)

		# Walls
		_build_walls(room, wall_tex, room_idx)

		# Wall decorations (moss, stains)
		_build_wall_decorations(room, wall_deco_tex)

		# Torches
		_build_torches(room, torch_tex)

		# Doorway between rooms
		if room_idx < 2:
			_build_doorway(room, doorway_tex, true)  # right door
		if room_idx > 0:
			_build_doorway(room, doorway_tex, false)  # left door (entrance)

	# --- Door blockers (cleared when enemies die) ---
	# Door blocker between Room 1 and Room 2 (at right side of Room 1)
	_add_door_blocker(root, 0, Vector2(ROOM_W - WALL_THICKNESS * TILE / 2, 360))
	# Door blocker between Room 2 and Room 3 (at right side of Room 2)
	_add_door_blocker(root, 1, Vector2(ROOM_W * 2 - WALL_THICKNESS * TILE / 2, 360))

	# --- Enemies in Room 1 ---
	var enemy_scene: PackedScene = load("res://scenes/enemy.tscn")
	var enemy_positions_r1 := [
		Vector2(400, 350),
		Vector2(700, 250),
		Vector2(900, 450),
	]
	for i in range(enemy_positions_r1.size()):
		var pos: Vector2 = enemy_positions_r1[i]
		var enemy = enemy_scene.instantiate()
		enemy.name = "Enemy_R1_%d" % i
		enemy.position = pos
		root.add_child(enemy)

	# --- Enemies in Room 2 ---
	var enemy_positions_r2 := [
		Vector2(1580, 300),
		Vector2(1800, 400),
		Vector2(2000, 250),
		Vector2(1700, 500),
	]
	for i in range(enemy_positions_r2.size()):
		var pos: Vector2 = enemy_positions_r2[i]
		var enemy = enemy_scene.instantiate()
		enemy.name = "Enemy_R2_%d" % i
		enemy.position = pos
		root.add_child(enemy)

	# --- Boss in Room 3 ---
	var boss_scene: PackedScene = load("res://scenes/boss.tscn")
	var boss = boss_scene.instantiate()
	boss.name = "Boss"
	boss.position = Vector2(3200, 360)
	root.add_child(boss)

	# --- Player ---
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

	# --- HUD ---
	var canvas_layer := CanvasLayer.new()
	canvas_layer.name = "CanvasLayer"
	canvas_layer.layer = 10
	root.add_child(canvas_layer)

	var hud_scene: PackedScene = load("res://scenes/hud.tscn")
	var hud = hud_scene.instantiate()
	hud.name = "HUD"
	canvas_layer.add_child(hud)

	# --- Torch lights for atmosphere (PointLight2D) ---
	_add_torch_lights(root)

	_set_owners(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Pack failed: " + str(err))
		quit(1)
		return

	err = ResourceSaver.save(packed, "res://scenes/main.tscn")
	if err != OK:
		push_error("Save failed: " + str(err))
		quit(1)
		return

	print("Saved: res://scenes/main.tscn")
	quit(0)

func _add_door_blocker(root: Node2D, room_index: int, pos: Vector2) -> void:
	# A StaticBody2D that blocks the doorway until enemies in this room are cleared.
	# The door_manager script will remove it when the room is cleared.
	var blocker := StaticBody2D.new()
	blocker.name = "DoorBlocker_%d" % room_index
	blocker.collision_layer = 4  # walls
	blocker.collision_mask = 0
	blocker.position = pos
	blocker.add_to_group("door_blocker_%d" % room_index)

	var shape := CollisionShape2D.new()
	shape.name = "Shape"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WALL_THICKNESS * TILE, 160)  # doorway height
	shape.shape = rect
	blocker.add_child(shape)

	# Visual indicator: semi-transparent barrier
	var visual := ColorRect.new()
	visual.name = "Visual"
	visual.color = Color(0.6, 0.3, 0.1, 0.5)
	visual.size = Vector2(WALL_THICKNESS * TILE, 160)
	visual.position = Vector2(-WALL_THICKNESS * TILE / 2, -80)
	blocker.add_child(visual)

	root.add_child(blocker)

func _build_floor(room: Node2D, tex: Texture2D) -> void:
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
			s.texture = tex
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.position = Vector2(x + TILE / 2, y + TILE / 2)
			s.name = "F_%d_%d" % [x / TILE, y / TILE]
			floor_node.add_child(s)
			y += TILE
		x += TILE

func _build_walls(room: Node2D, tex: Texture2D, room_idx: int) -> void:
	var walls := Node2D.new()
	walls.name = "Walls"
	room.add_child(walls)

	# Top wall
	var x: int = 0
	while x < ROOM_W:
		var y: int = 0
		while y < WALL_THICKNESS * TILE:
			var s := Sprite2D.new()
			s.texture = tex
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.position = Vector2(x + TILE / 2, y + TILE / 2)
			s.name = "WT_%d_%d" % [x / TILE, y / TILE]
			walls.add_child(s)
			y += TILE
		x += TILE

	# Bottom wall
	x = 0
	while x < ROOM_W:
		var y: int = ROOM_H - WALL_THICKNESS * TILE
		while y < ROOM_H:
			var s := Sprite2D.new()
			s.texture = tex
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.position = Vector2(x + TILE / 2, y + TILE / 2)
			s.name = "WB_%d_%d" % [x / TILE, y / TILE]
			walls.add_child(s)
			y += TILE
		x += TILE

	# Left wall (with doorway gap if not room 0)
	var y: int = WALL_THICKNESS * TILE
	while y < ROOM_H - WALL_THICKNESS * TILE:
		var is_doorway: bool = room_idx > 0 and y >= 280 and y < 440
		if not is_doorway:
			var wall_x: int = 0
			while wall_x < WALL_THICKNESS * TILE:
				var s := Sprite2D.new()
				s.texture = tex
				s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				s.position = Vector2(wall_x + TILE / 2, y + TILE / 2)
				s.name = "WL_%d_%d" % [wall_x / TILE, y / TILE]
				walls.add_child(s)
				wall_x += TILE
		y += TILE

	# Right wall (with doorway gap if not last room)
	y = WALL_THICKNESS * TILE
	while y < ROOM_H - WALL_THICKNESS * TILE:
		var is_doorway: bool = room_idx < 2 and y >= 280 and y < 440
		if not is_doorway:
			var wall_x: int = ROOM_W - WALL_THICKNESS * TILE
			while wall_x < ROOM_W:
				var s := Sprite2D.new()
				s.texture = tex
				s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				s.position = Vector2(wall_x + TILE / 2, y + TILE / 2)
				s.name = "WR_%d_%d" % [wall_x / TILE, y / TILE]
				walls.add_child(s)
				wall_x += TILE
		y += TILE

	# Add StaticBody2D for wall collision
	_add_wall_collision(walls, room_idx)

func _add_wall_collision(walls: Node2D, room_idx: int) -> void:
	# Top wall
	var top := StaticBody2D.new()
	top.name = "TopWall"
	top.collision_layer = 4  # walls
	top.collision_mask = 0
	top.position = Vector2(ROOM_W / 2, WALL_THICKNESS * TILE / 2)
	var top_shape := CollisionShape2D.new()
	top_shape.name = "Shape"
	var top_rect := RectangleShape2D.new()
	top_rect.size = Vector2(ROOM_W, WALL_THICKNESS * TILE)
	top_shape.shape = top_rect
	top.add_child(top_shape)
	walls.add_child(top)

	# Bottom wall
	var bot := StaticBody2D.new()
	bot.name = "BottomWall"
	bot.collision_layer = 4
	bot.collision_mask = 0
	bot.position = Vector2(ROOM_W / 2, ROOM_H - WALL_THICKNESS * TILE / 2)
	var bot_shape := CollisionShape2D.new()
	bot_shape.name = "Shape"
	var bot_rect := RectangleShape2D.new()
	bot_rect.size = Vector2(ROOM_W, WALL_THICKNESS * TILE)
	bot_shape.shape = bot_rect
	bot.add_child(bot_shape)
	walls.add_child(bot)

	# Left wall (2 segments if doorway)
	if room_idx > 0:
		# Upper segment
		var lu := StaticBody2D.new()
		lu.name = "LeftWallUpper"
		lu.collision_layer = 4
		lu.collision_mask = 0
		var lu_h: float = 280.0 - WALL_THICKNESS * TILE
		lu.position = Vector2(WALL_THICKNESS * TILE / 2, WALL_THICKNESS * TILE + lu_h / 2)
		var lu_shape := CollisionShape2D.new()
		lu_shape.name = "Shape"
		var lu_rect := RectangleShape2D.new()
		lu_rect.size = Vector2(WALL_THICKNESS * TILE, lu_h)
		lu_shape.shape = lu_rect
		lu.add_child(lu_shape)
		walls.add_child(lu)
		# Lower segment
		var ll := StaticBody2D.new()
		ll.name = "LeftWallLower"
		ll.collision_layer = 4
		ll.collision_mask = 0
		var ll_h: float = ROOM_H - WALL_THICKNESS * TILE - 440.0
		ll.position = Vector2(WALL_THICKNESS * TILE / 2, 440.0 + ll_h / 2)
		var ll_shape := CollisionShape2D.new()
		ll_shape.name = "Shape"
		var ll_rect := RectangleShape2D.new()
		ll_rect.size = Vector2(WALL_THICKNESS * TILE, ll_h)
		ll_shape.shape = ll_rect
		ll.add_child(ll_shape)
		walls.add_child(ll)
	else:
		var lw := StaticBody2D.new()
		lw.name = "LeftWall"
		lw.collision_layer = 4
		lw.collision_mask = 0
		lw.position = Vector2(WALL_THICKNESS * TILE / 2, ROOM_H / 2)
		var lw_shape := CollisionShape2D.new()
		lw_shape.name = "Shape"
		var lw_rect := RectangleShape2D.new()
		lw_rect.size = Vector2(WALL_THICKNESS * TILE, ROOM_H)
		lw_shape.shape = lw_rect
		lw.add_child(lw_shape)
		walls.add_child(lw)

	# Right wall (2 segments if doorway)
	if room_idx < 2:
		var ru := StaticBody2D.new()
		ru.name = "RightWallUpper"
		ru.collision_layer = 4
		ru.collision_mask = 0
		var ru_h: float = 280.0 - WALL_THICKNESS * TILE
		ru.position = Vector2(ROOM_W - WALL_THICKNESS * TILE / 2, WALL_THICKNESS * TILE + ru_h / 2)
		var ru_shape := CollisionShape2D.new()
		ru_shape.name = "Shape"
		var ru_rect := RectangleShape2D.new()
		ru_rect.size = Vector2(WALL_THICKNESS * TILE, ru_h)
		ru_shape.shape = ru_rect
		ru.add_child(ru_shape)
		walls.add_child(ru)
		var rl := StaticBody2D.new()
		rl.name = "RightWallLower"
		rl.collision_layer = 4
		rl.collision_mask = 0
		var rl_h: float = ROOM_H - WALL_THICKNESS * TILE - 440.0
		rl.position = Vector2(ROOM_W - WALL_THICKNESS * TILE / 2, 440.0 + rl_h / 2)
		var rl_shape := CollisionShape2D.new()
		rl_shape.name = "Shape"
		var rl_rect := RectangleShape2D.new()
		rl_rect.size = Vector2(WALL_THICKNESS * TILE, rl_h)
		rl_shape.shape = rl_rect
		rl.add_child(rl_shape)
		walls.add_child(rl)
	else:
		var rw := StaticBody2D.new()
		rw.name = "RightWall"
		rw.collision_layer = 4
		rw.collision_mask = 0
		rw.position = Vector2(ROOM_W - WALL_THICKNESS * TILE / 2, ROOM_H / 2)
		var rw_shape := CollisionShape2D.new()
		rw_shape.name = "Shape"
		var rw_rect := RectangleShape2D.new()
		rw_rect.size = Vector2(WALL_THICKNESS * TILE, ROOM_H)
		rw_shape.shape = rw_rect
		rw.add_child(rw_shape)
		walls.add_child(rw)

func _build_torches(room: Node2D, tex: Texture2D) -> void:
	var torches := Node2D.new()
	torches.name = "Torches"
	room.add_child(torches)

	# Place torches along walls with slight randomness for organic feel
	var base_positions := [
		Vector2(80, 76),
		Vector2(380 + randf_range(-20, 20), 80),
		Vector2(860 + randf_range(-30, 30), 78),
		Vector2(1190 + randf_range(-10, 10), 82),
		Vector2(90, 636),
		Vector2(420 + randf_range(-25, 25), 640),
		Vector2(850 + randf_range(-20, 20), 638),
		Vector2(1180 + randf_range(-15, 15), 642),
		# Side wall torches
		Vector2(76, 240 + randf_range(-20, 20)),
		Vector2(76, 480 + randf_range(-20, 20)),
		Vector2(1204, 260 + randf_range(-20, 20)),
		Vector2(1204, 500 + randf_range(-20, 20)),
	]
	var positions: Array = []
	for p in base_positions:
		positions.append(p)
	for i in range(positions.size()):
		var pos: Vector2 = positions[i]
		var s := Sprite2D.new()
		s.name = "Torch_%d" % i
		s.texture = tex
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = pos
		s.scale = Vector2(2, 2)
		torches.add_child(s)

func _build_doorway(room: Node2D, tex: Texture2D, is_right: bool) -> void:
	var door := Sprite2D.new()
	door.name = "DoorRight" if is_right else "DoorLeft"
	door.texture = tex
	door.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var x_pos: float = ROOM_W - 16.0 if is_right else 16.0
	door.position = Vector2(x_pos, 360)
	door.scale = Vector2(2, 2.5)
	room.add_child(door)

func _build_floor_decorations(room: Node2D, tex: Texture2D) -> void:
	var decos := Node2D.new()
	decos.name = "FloorDecos"
	room.add_child(decos)
	# Scatter random decorations on the floor
	for i in range(12):
		var s := Sprite2D.new()
		s.name = "FDeco_%d" % i
		s.texture = tex
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = Vector2(
			randf_range(100, ROOM_W - 100),
			randf_range(100, ROOM_H - 100)
		)
		s.modulate = Color(1, 1, 1, randf_range(0.3, 0.7))
		decos.add_child(s)

func _build_wall_decorations(room: Node2D, tex: Texture2D) -> void:
	var decos := Node2D.new()
	decos.name = "WallDecos"
	room.add_child(decos)
	# Place along wall edges
	for i in range(8):
		var s := Sprite2D.new()
		s.name = "WDeco_%d" % i
		s.texture = tex
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# Alternate between top and bottom walls
		var wall_y: float = 48.0 if i % 2 == 0 else float(ROOM_H - 48)
		s.position = Vector2(randf_range(80, ROOM_W - 80), wall_y)
		s.modulate = Color(1, 1, 1, randf_range(0.4, 0.8))
		decos.add_child(s)

func _add_torch_lights(root: Node2D) -> void:
	var lights := Node2D.new()
	lights.name = "TorchLights"
	root.add_child(lights)

	# Create ambient darkness overlay
	var darkness := CanvasModulate.new()
	darkness.name = "Darkness"
	darkness.color = Color(0.4, 0.35, 0.3)
	root.add_child(darkness)

	# Add point lights at torch positions for each room
	for room_idx in range(3):
		var offset_x: float = room_idx * ROOM_W
		var torch_positions := [
			Vector2(80, 80),
			Vector2(400, 80),
			Vector2(880, 80),
			Vector2(1200, 80),
			Vector2(80, 640),
			Vector2(400, 640),
			Vector2(880, 640),
			Vector2(1200, 640),
			Vector2(76, 260),
			Vector2(76, 480),
			Vector2(1204, 260),
			Vector2(1204, 500),
			Vector2(640, 360),  # room center ambient
		]
		for i in range(torch_positions.size()):
			var pos: Vector2 = torch_positions[i]
			var light := PointLight2D.new()
			light.name = "Light_R%d_%d" % [room_idx, i]
			light.position = Vector2(pos.x + offset_x, pos.y)
			light.color = Color(1.0, 0.8, 0.4)
			var is_center: bool = i == torch_positions.size() - 1
			light.energy = 1.5 if is_center else 0.9
			light.texture = _create_light_texture()
			light.texture_scale = 6.0 if is_center else 3.5
			lights.add_child(light)

func _create_light_texture() -> Texture2D:
	# Create a simple radial gradient for light
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var center := Vector2(64, 64)
	for y in range(128):
		for x in range(128):
			var dist: float = Vector2(x, y).distance_to(center) / 64.0
			var alpha: float = clampf(1.0 - dist, 0.0, 1.0)
			alpha = alpha * alpha  # quadratic falloff
			img.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(img)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
