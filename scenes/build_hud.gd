extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_hud.gd

func _initialize() -> void:
	print("Building HUD scene...")

	var root := Control.new()
	root.name = "HUD"
	root.set_script(load("res://scripts/hud_controller.gd"))
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# --- Top-left: Player info panel ---
	var info_panel := PanelContainer.new()
	info_panel.name = "InfoPanel"
	info_panel.position = Vector2(10, 10)
	info_panel.size = Vector2(220, 70)
	# Dark semi-transparent style
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.1, 0.8)
	panel_style.border_color = Color(0.4, 0.35, 0.25)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.content_margin_left = 10
	panel_style.content_margin_right = 10
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	info_panel.add_theme_stylebox_override("panel", panel_style)
	root.add_child(info_panel)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	info_panel.add_child(vbox)

	# HP label row
	var hp_row := HBoxContainer.new()
	hp_row.name = "HPRow"
	vbox.add_child(hp_row)

	var hp_label := Label.new()
	hp_label.name = "HPLabel"
	hp_label.text = "HP"
	hp_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	hp_label.add_theme_font_size_override("font_size", 14)
	hp_label.custom_minimum_size = Vector2(30, 0)
	hp_row.add_child(hp_label)

	var hp_bar := ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.min_value = 0
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(140, 16)
	hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Red HP bar
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.8, 0.15, 0.1)
	hp_fill.corner_radius_top_left = 2
	hp_fill.corner_radius_top_right = 2
	hp_fill.corner_radius_bottom_left = 2
	hp_fill.corner_radius_bottom_right = 2
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.15, 0.1, 0.1)
	hp_bg.corner_radius_top_left = 2
	hp_bg.corner_radius_top_right = 2
	hp_bg.corner_radius_bottom_left = 2
	hp_bg.corner_radius_bottom_right = 2
	hp_bar.add_theme_stylebox_override("background", hp_bg)
	hp_row.add_child(hp_bar)

	var hp_value := Label.new()
	hp_value.name = "HPValue"
	hp_value.text = "100/100"
	hp_value.add_theme_color_override("font_color", Color(0.9, 0.85, 0.8))
	hp_value.add_theme_font_size_override("font_size", 12)
	hp_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_value.custom_minimum_size = Vector2(55, 0)
	hp_row.add_child(hp_value)

	# Room indicator
	var room_label := Label.new()
	room_label.name = "RoomLabel"
	room_label.text = "Room 1 / 3"
	room_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	room_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(room_label)

	# --- Top-right: Gold counter ---
	var gold_panel := PanelContainer.new()
	gold_panel.name = "GoldPanel"
	gold_panel.anchor_left = 1.0
	gold_panel.anchor_top = 0.0
	gold_panel.anchor_right = 1.0
	gold_panel.anchor_bottom = 0.0
	gold_panel.offset_left = -140
	gold_panel.offset_top = 10
	gold_panel.offset_right = -10
	gold_panel.offset_bottom = 50
	var gold_style := StyleBoxFlat.new()
	gold_style.bg_color = Color(0.05, 0.05, 0.1, 0.8)
	gold_style.border_color = Color(0.6, 0.5, 0.2)
	gold_style.border_width_left = 2
	gold_style.border_width_right = 2
	gold_style.border_width_top = 2
	gold_style.border_width_bottom = 2
	gold_style.corner_radius_top_left = 4
	gold_style.corner_radius_top_right = 4
	gold_style.corner_radius_bottom_left = 4
	gold_style.corner_radius_bottom_right = 4
	gold_style.content_margin_left = 8
	gold_style.content_margin_right = 8
	gold_style.content_margin_top = 4
	gold_style.content_margin_bottom = 4
	gold_panel.add_theme_stylebox_override("panel", gold_style)
	root.add_child(gold_panel)

	var gold_row := HBoxContainer.new()
	gold_row.name = "GoldRow"
	gold_panel.add_child(gold_row)

	var gold_icon := Label.new()
	gold_icon.name = "GoldIcon"
	gold_icon.text = "Gold"
	gold_icon.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
	gold_icon.add_theme_font_size_override("font_size", 14)
	gold_row.add_child(gold_icon)

	var gold_value := Label.new()
	gold_value.name = "GoldValue"
	gold_value.text = "0"
	gold_value.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	gold_value.add_theme_font_size_override("font_size", 14)
	gold_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gold_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gold_row.add_child(gold_value)

	_set_owners(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/hud.tscn")
	print("Saved: res://scenes/hud.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
