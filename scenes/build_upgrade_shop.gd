extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_upgrade_shop.gd

func _initialize() -> void:
	print("Building upgrade shop scene...")

	var root := Control.new()
	root.name = "UpgradeShop"
	root.set_script(load("res://scripts/upgrade_shop_controller.gd"))
	root.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Dark background
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.03, 0.02, 0.05)
	root.add_child(bg)

	# Main container
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 200)
	margin.add_theme_constant_override("margin_right", 200)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	root.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "MainVBox"
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	# Title
	var title := Label.new()
	title.name = "Title"
	title.text = "UPGRADE SHOP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
	vbox.add_child(title)

	# Gold display
	var gold_row := HBoxContainer.new()
	gold_row.name = "GoldRow"
	gold_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(gold_row)

	var gold_icon := Label.new()
	gold_icon.text = "Gold: "
	gold_icon.add_theme_font_size_override("font_size", 20)
	gold_icon.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
	gold_row.add_child(gold_icon)

	var gold_value := Label.new()
	gold_value.name = "GoldValue"
	gold_value.text = "0"
	gold_value.add_theme_font_size_override("font_size", 20)
	gold_value.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	gold_row.add_child(gold_value)

	# Separator
	var sep1 := HSeparator.new()
	sep1.add_theme_constant_override("separation", 8)
	vbox.add_child(sep1)

	# Upgrades section title
	var upgrades_title := Label.new()
	upgrades_title.text = "STAT UPGRADES"
	upgrades_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrades_title.add_theme_font_size_override("font_size", 18)
	upgrades_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(upgrades_title)

	# Upgrade rows
	var upgrade_keys := ["max_hp", "attack_damage", "speed", "regen_rate"]
	var upgrade_labels := { "max_hp": "Max HP", "attack_damage": "Attack", "speed": "Speed", "regen_rate": "HP Regen" }
	var upgrade_descs := { "max_hp": "+20 HP", "attack_damage": "+5 DMG", "speed": "+20 SPD", "regen_rate": "+2 HP/s" }

	for key in upgrade_keys:
		var row := _create_upgrade_row(key, upgrade_labels[key], upgrade_descs[key])
		vbox.add_child(row)

	# Separator
	var sep2 := HSeparator.new()
	sep2.add_theme_constant_override("separation", 8)
	vbox.add_child(sep2)

	# Skills section title
	var skills_title := Label.new()
	skills_title.text = "SKILLS"
	skills_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skills_title.add_theme_font_size_override("font_size", 18)
	skills_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(skills_title)

	# Skill rows
	var skill_data := {
		"dash":     { "label": "Dash (Q)",     "desc": "Quick dodge, 3s CD",     "cost": 100 },
		"fireball": { "label": "Fireball (E)", "desc": "Ranged attack, 5s CD",   "cost": 200 },
		"heal":     { "label": "Heal (R)",     "desc": "Restore 30% HP, 10s CD", "cost": 150 },
	}
	for skill_id in ["dash", "fireball", "heal"]:
		var sd: Dictionary = skill_data[skill_id]
		var row := _create_skill_row(skill_id, sd["label"], sd["desc"], sd["cost"])
		vbox.add_child(row)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Continue button
	var continue_btn := Button.new()
	continue_btn.name = "ContinueButton"
	continue_btn.text = "CONTINUE"
	continue_btn.custom_minimum_size = Vector2(200, 50)
	continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_btn.add_theme_font_size_override("font_size", 20)
	vbox.add_child(continue_btn)

	_set_owners(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Pack failed: " + str(err))
		quit(1)
		return

	err = ResourceSaver.save(packed, "res://scenes/upgrade_shop.tscn")
	if err != OK:
		push_error("Save failed: " + str(err))
		quit(1)
		return

	print("Saved: res://scenes/upgrade_shop.tscn")
	quit(0)

func _create_upgrade_row(key: String, label_text: String, desc_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Upgrade_%s" % key
	row.add_theme_constant_override("separation", 12)

	# Name
	var name_label := Label.new()
	name_label.text = label_text
	name_label.custom_minimum_size = Vector2(120, 0)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	row.add_child(name_label)

	# Desc
	var desc_label := Label.new()
	desc_label.text = desc_text
	desc_label.custom_minimum_size = Vector2(120, 0)
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	row.add_child(desc_label)

	# Level
	var level_label := Label.new()
	level_label.name = "Level_%s" % key
	level_label.text = "Lv.0"
	level_label.custom_minimum_size = Vector2(60, 0)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	row.add_child(level_label)

	# Cost
	var cost_label := Label.new()
	cost_label.name = "Cost_%s" % key
	cost_label.text = "50G"
	cost_label.custom_minimum_size = Vector2(80, 0)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost_label.add_theme_font_size_override("font_size", 16)
	cost_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
	row.add_child(cost_label)

	# Buy button
	var buy_btn := Button.new()
	buy_btn.name = "Buy_%s" % key
	buy_btn.text = "BUY"
	buy_btn.custom_minimum_size = Vector2(80, 30)
	buy_btn.add_theme_font_size_override("font_size", 14)
	row.add_child(buy_btn)

	return row

func _create_skill_row(skill_id: String, label_text: String, desc_text: String, cost: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Skill_%s" % skill_id
	row.add_theme_constant_override("separation", 12)

	# Name
	var name_label := Label.new()
	name_label.text = label_text
	name_label.custom_minimum_size = Vector2(140, 0)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	row.add_child(name_label)

	# Desc
	var desc_label := Label.new()
	desc_label.text = desc_text
	desc_label.custom_minimum_size = Vector2(200, 0)
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	row.add_child(desc_label)

	# Cost
	var cost_label := Label.new()
	cost_label.text = "%dG" % cost
	cost_label.custom_minimum_size = Vector2(80, 0)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost_label.add_theme_font_size_override("font_size", 16)
	cost_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
	row.add_child(cost_label)

	# Status / Buy button
	var status_label := Label.new()
	status_label.name = "Status_%s" % skill_id
	status_label.text = ""
	status_label.custom_minimum_size = Vector2(80, 0)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 14)
	row.add_child(status_label)

	var buy_btn := Button.new()
	buy_btn.name = "BuySkill_%s" % skill_id
	buy_btn.text = "BUY"
	buy_btn.custom_minimum_size = Vector2(80, 30)
	buy_btn.add_theme_font_size_override("font_size", 14)
	row.add_child(buy_btn)

	return row

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
