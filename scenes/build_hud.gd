extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_hud.gd

func _initialize() -> void:
	print("Building HUD scene...")

	var root := Control.new()
	root.name = "HUD"
	root.set_script(load("res://scripts/hud_controller.gd"))
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# ===== Top-left: Info panel (HP, Gold, Equipment, ATK) =====
	var info_panel := PanelContainer.new()
	info_panel.name = "InfoPanel"
	info_panel.position = Vector2(10, 10)
	info_panel.size = Vector2(260, 110)
	info_panel.add_theme_stylebox_override("panel", _make_panel_style(
		Color(0.05, 0.05, 0.1, 0.8), Color(0.4, 0.35, 0.25)))
	root.add_child(info_panel)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 2)
	info_panel.add_child(vbox)

	# HP row
	var hp_row := HBoxContainer.new()
	hp_row.name = "HPRow"
	vbox.add_child(hp_row)

	var hp_label := Label.new()
	hp_label.name = "HPLabel"
	hp_label.text = "HP"
	hp_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	hp_label.add_theme_font_size_override("font_size", 13)
	hp_label.custom_minimum_size = Vector2(26, 0)
	hp_row.add_child(hp_label)

	var hp_bar := ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.min_value = 0
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(130, 14)
	hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hp_bar.add_theme_stylebox_override("fill", _make_bar_style(Color(0.8, 0.15, 0.1)))
	hp_bar.add_theme_stylebox_override("background", _make_bar_style(Color(0.15, 0.1, 0.1)))
	hp_row.add_child(hp_bar)

	var hp_value := Label.new()
	hp_value.name = "HPValue"
	hp_value.text = "100/100"
	hp_value.add_theme_color_override("font_color", Color(0.9, 0.85, 0.8))
	hp_value.add_theme_font_size_override("font_size", 11)
	hp_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_value.custom_minimum_size = Vector2(55, 0)
	hp_row.add_child(hp_value)

	# Gold row
	var gold_row := HBoxContainer.new()
	gold_row.name = "GoldRow"
	vbox.add_child(gold_row)
	var gold_icon := Label.new()
	gold_icon.text = "Gold"
	gold_icon.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
	gold_icon.add_theme_font_size_override("font_size", 13)
	gold_icon.custom_minimum_size = Vector2(40, 0)
	gold_row.add_child(gold_icon)
	var gold_value := Label.new()
	gold_value.name = "GoldValue"
	gold_value.text = "0"
	gold_value.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	gold_value.add_theme_font_size_override("font_size", 13)
	gold_row.add_child(gold_value)

	# Equipment + ATK row
	var equip_label := Label.new()
	equip_label.name = "EquipLabel"
	equip_label.text = ""
	equip_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.65))
	equip_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(equip_label)

	# Stats row (ATK, etc)
	var stats_label := Label.new()
	stats_label.name = "StatsLabel"
	stats_label.text = "ATK: 25"
	stats_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
	stats_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(stats_label)

	# ===== Top-right: Room label =====
	var room_panel := PanelContainer.new()
	room_panel.name = "RoomPanel"
	room_panel.anchor_left = 1.0
	room_panel.anchor_right = 1.0
	room_panel.offset_left = -160
	room_panel.offset_top = 10
	room_panel.offset_right = -10
	room_panel.offset_bottom = 40
	room_panel.add_theme_stylebox_override("panel", _make_panel_style(
		Color(0.05, 0.05, 0.1, 0.8), Color(0.3, 0.3, 0.4)))
	root.add_child(room_panel)

	var room_label := Label.new()
	room_label.name = "RoomLabel"
	room_label.text = "Room 1 / 3"
	room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	room_label.add_theme_font_size_override("font_size", 14)
	room_panel.add_child(room_label)

	_set_owners(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/hud.tscn")
	print("Saved: res://scenes/hud.tscn")
	quit(0)

func _make_panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s

func _make_bar_style(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = 2
	s.corner_radius_top_right = 2
	s.corner_radius_bottom_left = 2
	s.corner_radius_bottom_right = 2
	return s

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
