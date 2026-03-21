extends SceneTree
## Asset generator — creates pixel art PNGs procedurally
## Run: timeout 60 godot --headless --script scenes/generate_assets.gd

func _initialize() -> void:
	print("Generating pixel art assets...")

	_generate_dungeon_floor()
	_generate_dungeon_wall()
	_generate_torch()
	_generate_player_sprite()
	_generate_enemy_sprite()
	_generate_boss_sprite()
	_generate_doorway()
	_generate_floor_decoration()
	_generate_wall_decoration()

	print("All assets generated.")
	quit(0)

func _save_image(img: Image, path: String) -> void:
	var dir := DirAccess.open("res://")
	if not dir.dir_exists("assets/img"):
		dir.make_dir_recursive("assets/img")
	img.save_png(path)
	print("  Saved: " + path)

# Helper: draw a filled circle on an image
func _draw_circle(img: Image, cx: int, cy: int, radius: int, color: Color) -> void:
	for y in range(cy - radius, cy + radius + 1):
		for x in range(cx - radius, cx + radius + 1):
			if x < 0 or x >= img.get_width() or y < 0 or y >= img.get_height():
				continue
			var dx: float = x - cx
			var dy: float = y - cy
			if dx * dx + dy * dy <= radius * radius:
				img.set_pixel(x, y, color)

# Helper: draw a filled rect
func _draw_rect(img: Image, x1: int, y1: int, x2: int, y2: int, color: Color) -> void:
	for y in range(maxi(0, y1), mini(img.get_height(), y2)):
		for x in range(maxi(0, x1), mini(img.get_width(), x2)):
			img.set_pixel(x, y, color)

# Helper: blend a pixel with alpha
func _blend_pixel(img: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or x >= img.get_width() or y < 0 or y >= img.get_height():
		return
	var existing: Color = img.get_pixel(x, y)
	var a: float = color.a
	var blended := Color(
		existing.r * (1.0 - a) + color.r * a,
		existing.g * (1.0 - a) + color.g * a,
		existing.b * (1.0 - a) + color.b * a,
		1.0
	)
	img.set_pixel(x, y, blended)

# --- Dungeon floor tile 32x32 with organic stone look ---
func _generate_dungeon_floor() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	# Base stone colors - slightly varied per quadrant
	var base_colors := [
		Color(0.18, 0.16, 0.14),
		Color(0.20, 0.17, 0.14),
		Color(0.17, 0.15, 0.13),
		Color(0.19, 0.16, 0.13),
	]

	# Fill with varied stone
	for y in range(32):
		for x in range(32):
			var quad: int = (y / 16) * 2 + (x / 16)
			var base: Color = base_colors[quad]
			var noise: float = randf() * 0.06 - 0.03
			var c := Color(base.r + noise, base.g + noise, base.b + noise)
			img.set_pixel(x, y, c)

	# Grout lines with slight irregularity
	var grout := Color(0.1, 0.08, 0.06)
	var grout_light := Color(0.14, 0.12, 0.1)
	for i in range(32):
		# Bottom and right edges (dark grout)
		img.set_pixel(i, 31, grout)
		img.set_pixel(31, i, grout)
		# Top and left highlight
		if randf() > 0.3:
			_blend_pixel(img, i, 0, Color(0.28, 0.25, 0.22, 0.5))
			_blend_pixel(img, 0, i, Color(0.28, 0.25, 0.22, 0.5))

	# Cracks and imperfections
	for _i in range(5):
		var cx: int = randi_range(3, 28)
		var cy: int = randi_range(3, 28)
		var crack_c := Color(0.11, 0.09, 0.07)
		var length: int = randi_range(2, 6)
		for j in range(length):
			var dx: int = randi_range(-1, 1)
			var dy: int = randi_range(-1, 1)
			cx = clampi(cx + dx, 1, 30)
			cy = clampi(cy + dy, 1, 30)
			img.set_pixel(cx, cy, crack_c)

	# Occasional lighter stone chips
	for _i in range(3):
		var cx: int = randi_range(4, 27)
		var cy: int = randi_range(4, 27)
		_blend_pixel(img, cx, cy, Color(0.3, 0.27, 0.22, 0.4))
		_blend_pixel(img, cx + 1, cy, Color(0.28, 0.25, 0.2, 0.3))

	_save_image(img, "res://assets/img/floor_tile.png")

# --- Dungeon wall tile 32x32 with detailed brickwork ---
func _generate_dungeon_wall() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var base := Color(0.28, 0.24, 0.2)
	img.fill(base)

	# Detailed brick pattern with 3 rows
	var mortar := Color(0.12, 0.1, 0.08)
	var row_heights := [10, 10, 12]
	var y_start := 0

	for row in range(3):
		var h: int = row_heights[row]
		var offset: int = 8 if row % 2 == 1 else 0

		# Draw bricks in this row
		var brick_width := 16
		for bx in range(-1, 3):
			var x_start: int = bx * brick_width + offset
			# Each brick has slight color variation
			var brick_shade: float = randf() * 0.06 - 0.03
			var brick_color := Color(base.r + brick_shade, base.g + brick_shade, base.b + brick_shade)

			for y in range(y_start, mini(y_start + h, 32)):
				for x in range(maxi(0, x_start), mini(x_start + brick_width, 32)):
					img.set_pixel(x, y, brick_color)

			# Brick highlight (top edge)
			for x in range(maxi(0, x_start + 1), mini(x_start + brick_width - 1, 32)):
				if y_start + 1 < 32:
					var c: Color = img.get_pixel(x, y_start + 1)
					img.set_pixel(x, y_start + 1, Color(c.r + 0.06, c.g + 0.05, c.b + 0.04))

			# Brick shadow (bottom edge)
			var bottom_y: int = mini(y_start + h - 1, 31)
			for x in range(maxi(0, x_start + 1), mini(x_start + brick_width - 1, 32)):
				var c: Color = img.get_pixel(x, bottom_y)
				img.set_pixel(x, bottom_y, Color(c.r - 0.04, c.g - 0.04, c.b - 0.03))

			# Vertical mortar line
			if x_start >= 0 and x_start < 32:
				for y in range(y_start, mini(y_start + h, 32)):
					img.set_pixel(x_start, y, mortar)

		# Horizontal mortar line
		if y_start > 0:
			for x in range(32):
				img.set_pixel(x, y_start, mortar)

		y_start += h

	# Add noise for aged stone look
	for y in range(32):
		for x in range(32):
			if randf() < 0.15:
				var c: Color = img.get_pixel(x, y)
				var n: float = randf() * 0.04 - 0.02
				img.set_pixel(x, y, Color(c.r + n, c.g + n, c.b + n))

	# Moss/lichen patches
	for _i in range(2):
		var mx: int = randi_range(4, 27)
		var my: int = randi_range(4, 27)
		var moss := Color(0.15, 0.22, 0.12)
		for j in range(randi_range(2, 4)):
			_blend_pixel(img, mx + randi_range(-1, 1), my + randi_range(-1, 1), Color(moss.r, moss.g, moss.b, 0.3))

	_save_image(img, "res://assets/img/wall_tile.png")

# --- Torch decoration 16x32 with animated flame look ---
func _generate_torch() -> void:
	var img := Image.create(16, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Wall bracket (metal)
	var metal := Color(0.45, 0.4, 0.35)
	var metal_dark := Color(0.3, 0.25, 0.2)
	_draw_rect(img, 4, 18, 12, 20, metal)
	_draw_rect(img, 5, 16, 11, 18, metal_dark)

	# Torch handle (dark wood)
	var wood := Color(0.35, 0.22, 0.08)
	var wood_light := Color(0.45, 0.3, 0.12)
	_draw_rect(img, 6, 12, 10, 28, wood)
	img.set_pixel(6, 13, wood_light)
	img.set_pixel(6, 15, wood_light)
	img.set_pixel(9, 14, wood_light)

	# Flame core (bright white-yellow)
	_draw_circle(img, 8, 8, 3, Color(1.0, 0.95, 0.6))
	# Middle flame (yellow-orange)
	_draw_circle(img, 8, 7, 4, Color(1.0, 0.75, 0.2))
	# Outer flame (orange)
	_draw_circle(img, 7, 6, 3, Color(1.0, 0.55, 0.1))
	_draw_circle(img, 9, 6, 3, Color(1.0, 0.5, 0.08))
	# Core overwrite (brightest)
	_draw_circle(img, 8, 9, 2, Color(1.0, 0.98, 0.8))
	# Flame tip (pointed)
	img.set_pixel(8, 2, Color(1.0, 0.4, 0.05, 0.8))
	img.set_pixel(7, 3, Color(1.0, 0.5, 0.1, 0.9))
	img.set_pixel(9, 3, Color(1.0, 0.45, 0.08, 0.85))
	img.set_pixel(8, 3, Color(1.0, 0.6, 0.15))
	# Sparks
	img.set_pixel(5, 4, Color(1.0, 0.8, 0.3, 0.5))
	img.set_pixel(11, 5, Color(1.0, 0.7, 0.2, 0.4))
	img.set_pixel(4, 6, Color(1.0, 0.6, 0.1, 0.3))

	_save_image(img, "res://assets/img/torch.png")

# --- Player sprite 64x64 (hero with sword, shield, armor) ---
func _generate_player_sprite() -> void:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var skin := Color(0.82, 0.68, 0.52)
	var skin_shadow := Color(0.65, 0.5, 0.38)
	var hair := Color(0.35, 0.2, 0.08)
	var tunic := Color(0.12, 0.18, 0.42)
	var tunic_light := Color(0.18, 0.25, 0.52)
	var armor := Color(0.5, 0.5, 0.55)
	var armor_light := Color(0.65, 0.65, 0.7)

	# Cape (behind body)
	var cape := Color(0.35, 0.1, 0.1)
	var cape_light := Color(0.45, 0.15, 0.12)
	_draw_rect(img, 22, 26, 42, 52, cape)
	_draw_rect(img, 23, 28, 28, 50, cape_light)

	# Body (tunic)
	_draw_rect(img, 24, 24, 40, 48, tunic)
	_draw_rect(img, 25, 25, 39, 47, tunic_light)
	# Armor chest plate
	_draw_rect(img, 27, 26, 37, 38, armor)
	_draw_rect(img, 28, 27, 36, 37, armor_light)
	# Armor detail lines
	for y in range(30, 36, 2):
		for x in range(29, 35):
			_blend_pixel(img, x, y, Color(0.4, 0.4, 0.45, 0.3))

	# Head
	_draw_rect(img, 26, 10, 38, 24, skin)
	_draw_rect(img, 27, 11, 37, 23, skin)
	# Face shadow
	_draw_rect(img, 26, 20, 38, 24, skin_shadow)

	# Hair
	_draw_rect(img, 25, 8, 39, 16, hair)
	_draw_rect(img, 24, 10, 26, 20, hair)  # Left sideburn
	_draw_rect(img, 38, 10, 40, 20, hair)  # Right sideburn
	# Hair highlight
	_blend_pixel(img, 30, 9, Color(0.5, 0.35, 0.18, 0.4))
	_blend_pixel(img, 31, 9, Color(0.5, 0.35, 0.18, 0.4))

	# Eyes (detailed)
	# Left eye
	img.set_pixel(29, 17, Color(1.0, 1.0, 1.0))  # white
	img.set_pixel(30, 17, Color(0.15, 0.3, 0.6))  # iris
	img.set_pixel(30, 18, Color(0.05, 0.05, 0.1))  # pupil
	img.set_pixel(29, 18, Color(0.15, 0.3, 0.6))  # iris
	# Right eye
	img.set_pixel(34, 17, Color(1.0, 1.0, 1.0))
	img.set_pixel(35, 17, Color(0.15, 0.3, 0.6))
	img.set_pixel(35, 18, Color(0.05, 0.05, 0.1))
	img.set_pixel(34, 18, Color(0.15, 0.3, 0.6))
	# Eyebrows
	_draw_rect(img, 28, 15, 32, 16, Color(0.25, 0.15, 0.05))
	_draw_rect(img, 33, 15, 37, 16, Color(0.25, 0.15, 0.05))
	# Mouth
	img.set_pixel(31, 21, Color(0.55, 0.35, 0.25))
	img.set_pixel(32, 21, Color(0.55, 0.35, 0.25))
	img.set_pixel(33, 21, Color(0.55, 0.35, 0.25))

	# Shield (left side)
	var shield := Color(0.2, 0.3, 0.65)
	var shield_light := Color(0.3, 0.4, 0.75)
	var shield_border := Color(0.6, 0.55, 0.4)
	_draw_rect(img, 14, 26, 24, 44, shield)
	_draw_rect(img, 15, 27, 23, 43, shield_light)
	# Shield border
	for y in range(26, 44):
		img.set_pixel(14, y, shield_border)
		img.set_pixel(23, y, shield_border)
	for x in range(14, 24):
		img.set_pixel(x, 26, shield_border)
		img.set_pixel(x, 43, shield_border)
	# Shield emblem (golden cross)
	var gold := Color(0.85, 0.7, 0.2)
	_draw_rect(img, 18, 30, 20, 40, gold)
	_draw_rect(img, 16, 34, 22, 36, gold)
	# Shield highlight
	_blend_pixel(img, 16, 28, Color(1.0, 1.0, 1.0, 0.3))
	_blend_pixel(img, 17, 28, Color(1.0, 1.0, 1.0, 0.2))

	# Sword (right side)
	var blade := Color(0.78, 0.8, 0.85)
	var blade_edge := Color(0.9, 0.92, 0.95)
	# Blade
	_draw_rect(img, 42, 10, 44, 36, blade)
	for y in range(10, 36):
		img.set_pixel(42, y, blade_edge)
	# Sword tip
	img.set_pixel(42, 9, blade_edge)
	img.set_pixel(43, 9, blade)
	img.set_pixel(42, 8, Color(0.85, 0.87, 0.9))
	# Cross guard (gold)
	_draw_rect(img, 39, 36, 47, 38, gold)
	# Grip (leather)
	_draw_rect(img, 42, 38, 44, 44, Color(0.35, 0.22, 0.1))
	for y in range(38, 44, 2):
		_blend_pixel(img, 42, y, Color(0.45, 0.3, 0.15, 0.5))
	# Pommel
	_draw_rect(img, 41, 44, 45, 46, gold)

	# Arms
	_draw_rect(img, 22, 26, 24, 34, skin)
	_draw_rect(img, 40, 26, 42, 34, skin)
	# Armor on arms
	_draw_rect(img, 22, 26, 24, 30, armor)
	_draw_rect(img, 40, 26, 42, 30, armor)

	# Belt
	var belt := Color(0.4, 0.28, 0.12)
	_draw_rect(img, 24, 46, 40, 48, belt)
	# Belt buckle
	_draw_rect(img, 30, 46, 34, 48, gold)

	# Legs
	var pants := Color(0.15, 0.12, 0.08)
	_draw_rect(img, 26, 48, 32, 58, pants)
	_draw_rect(img, 34, 48, 40, 58, pants)

	# Boots
	var boot := Color(0.22, 0.16, 0.08)
	var boot_light := Color(0.3, 0.22, 0.12)
	_draw_rect(img, 25, 56, 33, 62, boot)
	_draw_rect(img, 33, 56, 41, 62, boot)
	_draw_rect(img, 26, 57, 32, 61, boot_light)
	_draw_rect(img, 34, 57, 40, 61, boot_light)

	# Outline (1px dark border around character)
	_add_outline(img, Color(0.05, 0.03, 0.02, 0.8))

	_save_image(img, "res://assets/img/player.png")

# --- Skeleton enemy sprite 48x48 (detailed) ---
func _generate_enemy_sprite() -> void:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var bone := Color(0.88, 0.84, 0.76)
	var bone_shadow := Color(0.65, 0.6, 0.52)
	var bone_dark := Color(0.5, 0.45, 0.38)

	# Skull
	_draw_rect(img, 18, 4, 30, 16, bone)
	_draw_rect(img, 19, 3, 29, 5, bone)  # top roundness
	_draw_rect(img, 21, 2, 27, 4, bone)
	# Skull shadow
	_draw_rect(img, 18, 13, 30, 16, bone_shadow)

	# Eye sockets
	var socket := Color(0.08, 0.02, 0.02)
	_draw_rect(img, 20, 7, 23, 11, socket)
	_draw_rect(img, 25, 7, 28, 11, socket)
	# Glowing red eyes
	img.set_pixel(21, 8, Color(0.9, 0.15, 0.1))
	img.set_pixel(21, 9, Color(0.7, 0.1, 0.05))
	img.set_pixel(26, 8, Color(0.9, 0.15, 0.1))
	img.set_pixel(26, 9, Color(0.7, 0.1, 0.05))

	# Nose cavity
	_draw_rect(img, 23, 10, 25, 12, socket)

	# Jaw with teeth
	_draw_rect(img, 19, 13, 29, 16, bone_shadow)
	for x in range(20, 28):
		if x % 2 == 0:
			img.set_pixel(x, 13, bone)
			img.set_pixel(x, 14, bone_shadow)

	# Spine/neck
	_draw_rect(img, 23, 16, 25, 18, bone_shadow)

	# Ribcage
	for row in range(4):
		var ry: int = 18 + row * 3
		if ry >= 30:
			break
		_draw_rect(img, 18, ry, 30, ry + 2, bone_shadow)
		# Rib gaps
		img.set_pixel(24, ry, Color(0, 0, 0, 0))
		img.set_pixel(24, ry + 1, Color(0, 0, 0, 0))

	# Arms (bone segments)
	# Upper arms
	_draw_rect(img, 15, 18, 18, 24, bone)
	_draw_rect(img, 30, 18, 33, 24, bone)
	# Elbows
	_draw_circle(img, 16, 24, 1, bone_shadow)
	_draw_circle(img, 31, 24, 1, bone_shadow)
	# Forearms
	_draw_rect(img, 13, 24, 16, 32, bone)
	_draw_rect(img, 32, 24, 35, 32, bone)
	# Hands
	_draw_circle(img, 14, 32, 1, bone_shadow)
	_draw_circle(img, 33, 32, 1, bone_shadow)

	# Shield (left hand)
	var shield := Color(0.32, 0.28, 0.22)
	var shield_rim := Color(0.48, 0.42, 0.32)
	_draw_rect(img, 6, 22, 14, 34, shield)
	for y in range(22, 34):
		img.set_pixel(6, y, shield_rim)
		img.set_pixel(13, y, shield_rim)
	for x in range(6, 14):
		img.set_pixel(x, 22, shield_rim)
		img.set_pixel(x, 33, shield_rim)
	# Shield dent
	_blend_pixel(img, 9, 27, Color(0.2, 0.18, 0.14, 0.5))
	_blend_pixel(img, 10, 28, Color(0.2, 0.18, 0.14, 0.4))

	# Sword (right hand)
	var blade := Color(0.6, 0.6, 0.65)
	var blade_edge := Color(0.75, 0.75, 0.8)
	_draw_rect(img, 34, 10, 36, 32, blade)
	for y in range(10, 32):
		img.set_pixel(34, y, blade_edge)
	# Sword tip
	img.set_pixel(34, 9, blade_edge)
	img.set_pixel(35, 9, blade)
	# Hilt
	_draw_rect(img, 33, 32, 38, 33, Color(0.4, 0.3, 0.15))

	# Pelvis
	_draw_rect(img, 20, 30, 28, 32, bone_dark)

	# Legs
	_draw_rect(img, 21, 32, 23, 42, bone)
	_draw_rect(img, 25, 32, 27, 42, bone)
	# Knee joints
	_draw_circle(img, 22, 37, 1, bone_shadow)
	_draw_circle(img, 26, 37, 1, bone_shadow)

	# Feet
	_draw_rect(img, 19, 42, 24, 44, bone_dark)
	_draw_rect(img, 24, 42, 29, 44, bone_dark)

	# Tattered cloth scraps
	var cloth := Color(0.25, 0.2, 0.15, 0.7)
	_blend_pixel(img, 19, 20, cloth)
	_blend_pixel(img, 20, 21, cloth)
	_blend_pixel(img, 28, 22, cloth)
	_blend_pixel(img, 29, 23, cloth)
	_blend_pixel(img, 22, 30, cloth)
	_blend_pixel(img, 26, 31, cloth)

	_add_outline(img, Color(0.03, 0.02, 0.01, 0.7))

	_save_image(img, "res://assets/img/enemy.png")

# --- Boss sprite 96x96 (large dark knight / demon lord) ---
func _generate_boss_sprite() -> void:
	var img := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var armor := Color(0.18, 0.12, 0.18)
	var armor_mid := Color(0.25, 0.18, 0.25)
	var armor_light := Color(0.35, 0.28, 0.35)
	var red := Color(0.85, 0.12, 0.08)
	var red_dim := Color(0.6, 0.08, 0.05)
	var dark := Color(0.08, 0.05, 0.08)

	# Cape (behind body, tattered)
	var cape := Color(0.4, 0.06, 0.06)
	var cape_dark := Color(0.25, 0.04, 0.04)
	for y in range(28, 82):
		for x in range(12, 22):
			var edge_fade: float = 1.0 - absf(x - 17.0) / 6.0
			if randf() < edge_fade * 0.85:
				img.set_pixel(x, y, cape if randf() > 0.3 else cape_dark)
		for x in range(74, 84):
			var edge_fade: float = 1.0 - absf(x - 79.0) / 6.0
			if randf() < edge_fade * 0.85:
				img.set_pixel(x, y, cape if randf() > 0.3 else cape_dark)

	# Helmet
	_draw_rect(img, 34, 10, 62, 30, armor)
	_draw_rect(img, 36, 8, 60, 12, armor_mid)
	# Helmet crest
	_draw_rect(img, 44, 6, 52, 10, armor_light)

	# Horns (curved)
	for i in range(12):
		var horn_y: int = 10 - i
		var horn_spread: int = i / 2
		# Left horn
		_draw_rect(img, 30 - horn_spread, horn_y, 34 - horn_spread, horn_y + 2, armor_mid)
		# Right horn
		_draw_rect(img, 62 + horn_spread, horn_y, 66 + horn_spread, horn_y + 2, armor_mid)
	# Horn tips glow
	_draw_circle(img, 24, 0, 2, red)
	_draw_circle(img, 72, 0, 2, red)

	# Visor slit
	_draw_rect(img, 38, 20, 58, 24, dark)
	# Glowing eyes
	_draw_rect(img, 40, 20, 45, 24, red)
	_draw_rect(img, 51, 20, 56, 24, red)
	# Eye glow effect
	_blend_pixel(img, 39, 21, Color(1.0, 0.3, 0.1, 0.4))
	_blend_pixel(img, 45, 21, Color(1.0, 0.3, 0.1, 0.4))
	_blend_pixel(img, 50, 21, Color(1.0, 0.3, 0.1, 0.4))
	_blend_pixel(img, 56, 21, Color(1.0, 0.3, 0.1, 0.4))

	# Neck guard
	_draw_rect(img, 36, 28, 60, 32, armor_mid)

	# Shoulder pauldrons (large, spiked)
	_draw_rect(img, 16, 28, 32, 40, armor_mid)
	_draw_rect(img, 64, 28, 80, 40, armor_mid)
	_draw_rect(img, 18, 30, 30, 38, armor_light)
	_draw_rect(img, 66, 30, 78, 38, armor_light)
	# Spikes on pauldrons
	_draw_rect(img, 20, 24, 23, 28, armor_light)
	_draw_rect(img, 26, 25, 29, 28, armor_light)
	_draw_rect(img, 67, 24, 70, 28, armor_light)
	_draw_rect(img, 73, 25, 76, 28, armor_light)
	# Spike tips
	_draw_circle(img, 21, 23, 1, red)
	_draw_circle(img, 27, 24, 1, red)
	_draw_circle(img, 68, 23, 1, red)
	_draw_circle(img, 74, 24, 1, red)

	# Torso (large armored body)
	_draw_rect(img, 26, 32, 70, 62, armor)
	_draw_rect(img, 28, 34, 68, 60, armor_mid)
	# Chest plate
	_draw_rect(img, 36, 36, 60, 56, armor_light)
	# Chest skull emblem
	_draw_rect(img, 42, 40, 54, 52, Color(0.45, 0.4, 0.35))
	# Skull eyes
	_draw_rect(img, 44, 43, 47, 46, red_dim)
	_draw_rect(img, 49, 43, 52, 46, red_dim)
	# Skull teeth
	for x in range(44, 52):
		if x % 2 == 0:
			img.set_pixel(x, 49, Color(0.6, 0.55, 0.5))

	# Arms
	_draw_rect(img, 16, 40, 26, 58, armor)
	_draw_rect(img, 70, 40, 80, 58, armor)
	# Gauntlets
	_draw_rect(img, 16, 52, 26, 58, armor_light)
	_draw_rect(img, 70, 52, 80, 58, armor_light)

	# Giant sword (right hand)
	var blade := Color(0.45, 0.45, 0.5)
	var blade_edge := Color(0.65, 0.65, 0.7)
	_draw_rect(img, 80, 8, 86, 62, blade)
	for y in range(8, 62):
		img.set_pixel(80, y, blade_edge)
	# Sword tip
	_draw_rect(img, 81, 5, 85, 8, blade)
	img.set_pixel(82, 4, blade_edge)
	img.set_pixel(83, 4, blade_edge)
	# Runes on blade (red glowing)
	for y in range(15, 55):
		if y % 8 < 3:
			_blend_pixel(img, 83, y, Color(1.0, 0.2, 0.1, 0.6))
	# Cross guard
	_draw_rect(img, 76, 62, 90, 65, Color(0.5, 0.35, 0.15))
	# Grip
	_draw_rect(img, 82, 65, 84, 74, Color(0.3, 0.18, 0.08))
	# Pommel
	_draw_rect(img, 81, 74, 85, 76, red_dim)

	# Belt with skull buckle
	_draw_rect(img, 26, 60, 70, 63, Color(0.45, 0.3, 0.12))
	_draw_rect(img, 44, 60, 52, 63, red)

	# Legs (armored)
	_draw_rect(img, 30, 63, 44, 82, armor)
	_draw_rect(img, 52, 63, 66, 82, armor)
	# Knee guards
	_draw_rect(img, 32, 70, 42, 74, armor_light)
	_draw_rect(img, 54, 70, 64, 74, armor_light)

	# Boots (heavy, spiked)
	_draw_rect(img, 28, 80, 46, 90, dark)
	_draw_rect(img, 50, 80, 68, 90, dark)
	_draw_rect(img, 30, 82, 44, 88, armor)
	_draw_rect(img, 52, 82, 66, 88, armor)
	# Boot spikes
	_draw_rect(img, 28, 84, 30, 88, armor_light)
	_draw_rect(img, 50, 84, 52, 88, armor_light)

	_add_outline(img, Color(0.02, 0.01, 0.02, 0.8))

	_save_image(img, "res://assets/img/boss.png")

# --- Doorway 32x64 ---
func _generate_doorway() -> void:
	var img := Image.create(32, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var stone := Color(0.3, 0.27, 0.24)
	var stone_light := Color(0.38, 0.34, 0.3)
	var dark := Color(0.03, 0.02, 0.02)

	# Doorframe (stone arch)
	_draw_rect(img, 0, 0, 7, 64, stone)
	_draw_rect(img, 25, 0, 32, 64, stone)
	# Arch top
	_draw_rect(img, 0, 0, 32, 10, stone)
	# Inner dark area
	_draw_rect(img, 7, 10, 25, 64, dark)

	# Stone detail on frame
	_draw_rect(img, 1, 1, 6, 9, stone_light)
	_draw_rect(img, 26, 1, 31, 9, stone_light)

	# Keystone
	_draw_rect(img, 12, 0, 20, 8, Color(0.42, 0.38, 0.32))
	_draw_rect(img, 13, 1, 19, 7, Color(0.48, 0.42, 0.36))

	# Brick detail on pillars
	for y in range(12, 60, 8):
		img.set_pixel(3, y, Color(0.2, 0.18, 0.15))
		img.set_pixel(28, y, Color(0.2, 0.18, 0.15))

	_save_image(img, "res://assets/img/doorway.png")

# --- Floor decoration (debris, cracks) 32x32 ---
func _generate_floor_decoration() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Scattered pebbles
	var pebble := Color(0.25, 0.22, 0.18, 0.6)
	for _i in range(5):
		var px: int = randi_range(4, 27)
		var py: int = randi_range(4, 27)
		_blend_pixel(img, px, py, pebble)
		if randf() > 0.5:
			_blend_pixel(img, px + 1, py, Color(pebble.r - 0.03, pebble.g - 0.03, pebble.b - 0.03, 0.4))

	# Crack
	var crack := Color(0.08, 0.06, 0.05, 0.5)
	var cx: int = randi_range(8, 24)
	var cy: int = randi_range(8, 24)
	for _j in range(8):
		_blend_pixel(img, cx, cy, crack)
		cx += randi_range(-1, 1)
		cy += randi_range(-1, 1)
		cx = clampi(cx, 1, 30)
		cy = clampi(cy, 1, 30)

	# Dark stain
	var stain := Color(0.1, 0.08, 0.06, 0.2)
	var sx: int = randi_range(10, 22)
	var sy: int = randi_range(10, 22)
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			if randf() > 0.4:
				_blend_pixel(img, sx + dx, sy + dy, stain)

	_save_image(img, "res://assets/img/floor_deco.png")

# --- Wall decoration (cracks, moss) 32x32 ---
func _generate_wall_decoration() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Moss
	var moss := Color(0.12, 0.2, 0.08, 0.5)
	for _i in range(8):
		var mx: int = randi_range(2, 29)
		var my: int = randi_range(20, 30)
		_blend_pixel(img, mx, my, moss)
		_blend_pixel(img, mx + 1, my, Color(moss.r + 0.03, moss.g + 0.03, moss.b, 0.3))

	# Drip stain
	var drip := Color(0.08, 0.12, 0.06, 0.3)
	var dx: int = randi_range(8, 24)
	for dy in range(10):
		_blend_pixel(img, dx, 2 + dy, drip)
		if randf() > 0.6:
			dx += randi_range(-1, 1)
			dx = clampi(dx, 2, 29)

	_save_image(img, "res://assets/img/wall_deco.png")

# --- Add dark outline around non-transparent pixels ---
func _add_outline(img: Image, outline_color: Color) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var outline_pixels: Array = []

	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a < 0.1:
				# Check if adjacent to a non-transparent pixel
				var has_neighbor := false
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
						var nx: int = x + dx
						var ny: int = y + dy
						if nx >= 0 and nx < w and ny >= 0 and ny < h:
							if img.get_pixel(nx, ny).a > 0.3:
								has_neighbor = true
								break
					if has_neighbor:
						break
				if has_neighbor:
					outline_pixels.append(Vector2i(x, y))

	for pos in outline_pixels:
		img.set_pixel(pos.x, pos.y, outline_color)
