extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_town.gd

const ROOM_W := 1280
const ROOM_H := 720
const TILE := 32
const WALL_THICKNESS := 2

func _initialize() -> void:
	print("Building town scene...")

	var root := Node2D.new()
	root.name = "Town"
	root.set_script(load("res://scripts/town_controller.gd"))

	var floor_tex: Texture2D = load("res://assets/img/floor_tile.png")
	var wall_tex: Texture2D = load("res://assets/img/wall_tile.png")
	var torch_tex: Texture2D = load("res://assets/img/torch.png")

	# Dark background
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.05, 0.04, 0.06)
	bg.size = Vector2(ROOM_W, ROOM_H)
	bg.z_index = -2
	root.add_child(bg)

	# Floor tiles
	_build_floor(root, floor_tex)

	# Walls (no doorways)
	_build_walls(root, wall_tex)

	# --- Buildings ---
	# Blacksmith (top-left)
	_add_building(root, "Blacksmith", Vector2(300, 220), Color(0.45, 0.3, 0.15), "Blacksmith")
	# Potion Shop (top-right)
	_add_building(root, "PotionShop", Vector2(980, 220), Color(0.7, 0.2, 0.2), "Potion Shop")
	# Skill Trainer (bottom-left)
	_add_building(root, "SkillTrainer", Vector2(300, 500), Color(0.2, 0.3, 0.7), "Skill Trainer")
	# Dungeon Entrance (bottom-right)
	_add_building(root, "DungeonEntrance", Vector2(980, 500), Color(0.25, 0.25, 0.25), "Dungeon")

	# --- Player ---
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player = player_scene.instantiate()
	player.name = "Player"
	player.position = Vector2(640, 360)
	root.add_child(player)

	# Camera on player
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)

	# --- HUD (gold display) ---
	var canvas_layer := CanvasLayer.new()
	canvas_layer.name = "CanvasLayer"
	canvas_layer.layer = 10
	root.add_child(canvas_layer)

	var gold_hud := _build_gold_hud()
	canvas_layer.add_child(gold_hud)

	# --- Torches ---
	_build_torches(root, torch_tex)

	# --- Torch lights ---
	_add_torch_lights(root)

	# --- Darkness overlay ---
	var darkness := CanvasModulate.new()
	darkness.name = "Darkness"
	darkness.color = Color(0.5, 0.45, 0.4)
	root.add_child(darkness)

	_set_owners(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Pack failed: " + str(err))
		quit(1)
		return

	err = ResourceSaver.save(packed, "res://scenes/town.tscn")
	if err != OK:
		push_error("Save failed: " + str(err))
		quit(1)
		return

	print("Saved: res://scenes/town.tscn")
	quit(0)

func _add_building(parent: Node2D, bname: String, pos: Vector2, color: Color, display_name: String) -> void:
	var building := StaticBody2D.new()
	building.name = bname
	building.collision_layer = 4  # walls
	building.collision_mask = 0
	building.position = pos

	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(120, 100)
	shape.shape = rect
	building.add_child(shape)

	# Outer border
	var border := ColorRect.new()
	border.name = "Border"
	border.color = Color(color.r * 0.5, color.g * 0.5, color.b * 0.5, 0.9)
	border.size = Vector2(130, 110)
	border.position = Vector2(-65, -55)
	border.z_index = -1
	building.add_child(border)

	# Main wall body using wall texture tiles
	var wall_tex: Texture2D = load("res://assets/img/wall_tile.png")
	for tx in range(4):
		for ty in range(3):
			var s := Sprite2D.new()
			s.texture = wall_tex
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.position = Vector2(-44 + tx * 32, -34 + ty * 32)
			s.modulate = color * 1.3
			building.add_child(s)

	# Color overlay for distinction
	var visual := ColorRect.new()
	visual.name = "Visual"
	visual.color = Color(color.r, color.g, color.b, 0.3)
	visual.size = Vector2(120, 100)
	visual.position = Vector2(-60, -50)
	building.add_child(visual)

	# Roof accent line
	var roof := ColorRect.new()
	roof.name = "Roof"
	roof.color = Color(color.r * 1.5, color.g * 1.5, color.b * 1.5, 0.8)
	roof.size = Vector2(120, 6)
	roof.position = Vector2(-60, -50)
	building.add_child(roof)

	# Icon symbol
	var icon := Label.new()
	icon.name = "Icon"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 28)
	icon.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8, 0.9))
	icon.position = Vector2(-20, -30)
	icon.size = Vector2(40, 40)
	match bname:
		"Blacksmith":
			icon.text = "X"  # anvil symbol
		"PotionShop":
			icon.text = "+"  # potion/heal symbol
		"SkillTrainer":
			icon.text = "*"  # magic symbol
		"DungeonEntrance":
			icon.text = ">"  # entrance arrow
	building.add_child(icon)

	# Name label
	var label := Label.new()
	label.name = "NameLabel"
	label.text = display_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	label.position = Vector2(-60, 55)
	label.size = Vector2(120, 20)
	building.add_child(label)

	parent.add_child(building)

func _build_floor(parent: Node2D, tex: Texture2D) -> void:
	var floor_node := Node2D.new()
	floor_node.name = "Floor"
	floor_node.z_index = -1
	parent.add_child(floor_node)

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
			floor_node.add_child(s)
			y += TILE
		x += TILE

func _build_walls(parent: Node2D, tex: Texture2D) -> void:
	var walls := Node2D.new()
	walls.name = "Walls"
	parent.add_child(walls)

	# Top wall
	var x: int = 0
	while x < ROOM_W:
		var y: int = 0
		while y < WALL_THICKNESS * TILE:
			var s := Sprite2D.new()
			s.texture = tex
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.position = Vector2(x + TILE / 2, y + TILE / 2)
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
			walls.add_child(s)
			y += TILE
		x += TILE

	# Left wall (no doorway)
	var y: int = WALL_THICKNESS * TILE
	while y < ROOM_H - WALL_THICKNESS * TILE:
		var wall_x: int = 0
		while wall_x < WALL_THICKNESS * TILE:
			var s := Sprite2D.new()
			s.texture = tex
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.position = Vector2(wall_x + TILE / 2, y + TILE / 2)
			walls.add_child(s)
			wall_x += TILE
		y += TILE

	# Right wall (no doorway)
	y = WALL_THICKNESS * TILE
	while y < ROOM_H - WALL_THICKNESS * TILE:
		var wall_x: int = ROOM_W - WALL_THICKNESS * TILE
		while wall_x < ROOM_W:
			var s := Sprite2D.new()
			s.texture = tex
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.position = Vector2(wall_x + TILE / 2, y + TILE / 2)
			walls.add_child(s)
			wall_x += TILE
		y += TILE

	# Wall collisions (solid, no doorways)
	# Top
	var top := StaticBody2D.new()
	top.name = "TopWall"
	top.collision_layer = 4
	top.collision_mask = 0
	top.position = Vector2(ROOM_W / 2, WALL_THICKNESS * TILE / 2)
	var top_shape := CollisionShape2D.new()
	top_shape.name = "Shape"
	var top_rect := RectangleShape2D.new()
	top_rect.size = Vector2(ROOM_W, WALL_THICKNESS * TILE)
	top_shape.shape = top_rect
	top.add_child(top_shape)
	walls.add_child(top)

	# Bottom
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

	# Left
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

	# Right
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

func _build_torches(parent: Node2D, tex: Texture2D) -> void:
	var torches := Node2D.new()
	torches.name = "Torches"
	parent.add_child(torches)

	var positions := [
		Vector2(80, 76), Vector2(400, 80), Vector2(860, 78), Vector2(1190, 82),
		Vector2(90, 636), Vector2(420, 640), Vector2(850, 638), Vector2(1180, 642),
		Vector2(76, 260), Vector2(76, 480), Vector2(1204, 260), Vector2(1204, 500),
	]
	for i in range(positions.size()):
		var s := Sprite2D.new()
		s.name = "Torch_%d" % i
		s.texture = tex
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = positions[i]
		s.scale = Vector2(2, 2)
		torches.add_child(s)

func _add_torch_lights(root: Node2D) -> void:
	var lights := Node2D.new()
	lights.name = "TorchLights"
	root.add_child(lights)

	var torch_positions := [
		Vector2(80, 80), Vector2(400, 80), Vector2(880, 80), Vector2(1200, 80),
		Vector2(80, 640), Vector2(400, 640), Vector2(880, 640), Vector2(1200, 640),
		Vector2(76, 260), Vector2(76, 480), Vector2(1204, 260), Vector2(1204, 500),
		Vector2(640, 360),  # center ambient
	]
	for i in range(torch_positions.size()):
		var pos: Vector2 = torch_positions[i]
		var light := PointLight2D.new()
		light.name = "Light_%d" % i
		light.position = pos
		light.color = Color(1.0, 0.85, 0.5)  # warmer town light
		var is_center: bool = i == torch_positions.size() - 1
		light.energy = 1.8 if is_center else 1.0
		light.texture = _create_light_texture()
		light.texture_scale = 7.0 if is_center else 4.0
		lights.add_child(light)

func _build_gold_hud() -> Control:
	var hud := Control.new()
	hud.name = "TownHUD"

	var bg := ColorRect.new()
	bg.name = "HUDBg"
	bg.color = Color(0.0, 0.0, 0.0, 0.4)
	bg.size = Vector2(160, 36)
	bg.position = Vector2(10, 10)
	hud.add_child(bg)

	var gold_label := Label.new()
	gold_label.name = "GoldDisplay"
	gold_label.text = "Gold: 0"
	gold_label.position = Vector2(20, 16)
	gold_label.add_theme_font_size_override("font_size", 18)
	gold_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
	hud.add_child(gold_label)

	return hud

func _create_light_texture() -> Texture2D:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var center := Vector2(64, 64)
	for y in range(128):
		for x in range(128):
			var dist: float = Vector2(x, y).distance_to(center) / 64.0
			var alpha: float = clampf(1.0 - dist, 0.0, 1.0)
			alpha = alpha * alpha
			img.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(img)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
