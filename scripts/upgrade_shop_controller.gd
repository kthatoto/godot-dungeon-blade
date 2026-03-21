extends Control
## res://scripts/upgrade_shop_controller.gd — Upgrade shop UI logic

const ItemDatabase = preload("res://scripts/item_database.gd")

const UPGRADES := {
	"max_hp":        { "base_cost": 50,  "per_level": 20,   "label": "Max HP",   "desc": "+20 HP per level" },
	"attack_damage": { "base_cost": 50,  "per_level": 5,    "label": "Attack",   "desc": "+5 damage per level" },
	"speed":         { "base_cost": 50,  "per_level": 20.0, "label": "Speed",    "desc": "+20 speed per level" },
	"regen_rate":    { "base_cost": 50,  "per_level": 2.0,  "label": "HP Regen", "desc": "+2 HP/s per level" },
}

const SKILLS := {
	"dash":     { "cost": 100, "label": "Dash (Q)",     "desc": "Quick dodge, 3s cooldown" },
	"fireball": { "cost": 200, "label": "Fireball (E)", "desc": "Ranged attack, 5s cooldown" },
	"heal":     { "cost": 150, "label": "Heal (R)",     "desc": "Restore 30% HP, 10s cooldown" },
}

const SKILL_UPGRADE_COSTS := {1: 300, 2: 500}  # level -> cost to upgrade FROM this level

var _gold_label: Label
var _upgrade_rows: Dictionary = {}  # key -> { "level_label", "cost_label", "button" }
var _skill_rows: Dictionary = {}    # key -> { "button", "status_label" }
var _equip_weapon_label: Label = null
var _equip_armor_label: Label = null
var _inventory_label: Label = null

func _ready() -> void:
	_bind_ui()
	_refresh_ui()

func _bind_ui() -> void:
	var vbox := $Margin/MainVBox
	# Gold label
	_gold_label = vbox.get_node("GoldRow/GoldValue")
	# Upgrade rows
	for key in UPGRADES:
		var row_node := vbox.get_node_or_null("Upgrade_%s" % key)
		if row_node == null:
			continue
		var level_label := row_node.get_node("Level_%s" % key) as Label
		var cost_label := row_node.get_node("Cost_%s" % key) as Label
		var button := row_node.get_node("Buy_%s" % key) as Button
		_upgrade_rows[key] = {
			"level_label": level_label,
			"cost_label": cost_label,
			"button": button,
		}
		button.pressed.connect(_buy_upgrade.bind(key))
	# Skill rows
	for skill_id in SKILLS:
		var row_node := vbox.get_node_or_null("Skill_%s" % skill_id)
		if row_node == null:
			continue
		var status_label := row_node.get_node("Status_%s" % skill_id) as Label
		var button := row_node.get_node("BuySkill_%s" % skill_id) as Button
		_skill_rows[skill_id] = {
			"status_label": status_label,
			"button": button,
		}
		button.pressed.connect(_buy_skill.bind(skill_id))
	# Continue button
	var continue_btn := vbox.get_node("ContinueButton") as Button
	continue_btn.pressed.connect(_continue_game)

	# Equipment display (add dynamically if not in scene)
	var equip_section := vbox.get_node_or_null("EquipmentSection")
	if equip_section == null:
		equip_section = VBoxContainer.new()
		equip_section.name = "EquipmentSection"
		# Insert before ContinueButton
		var continue_idx := continue_btn.get_index()
		vbox.add_child(equip_section)
		vbox.move_child(equip_section, continue_idx)

		var equip_title := Label.new()
		equip_title.text = "--- Equipment ---"
		equip_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		equip_title.add_theme_font_size_override("font_size", 16)
		equip_title.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
		equip_section.add_child(equip_title)

		_equip_weapon_label = Label.new()
		_equip_weapon_label.name = "WeaponLabel"
		_equip_weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_equip_weapon_label.add_theme_font_size_override("font_size", 14)
		equip_section.add_child(_equip_weapon_label)

		_equip_armor_label = Label.new()
		_equip_armor_label.name = "ArmorLabel"
		_equip_armor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_equip_armor_label.add_theme_font_size_override("font_size", 14)
		equip_section.add_child(_equip_armor_label)

		_inventory_label = Label.new()
		_inventory_label.name = "InventoryLabel"
		_inventory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_inventory_label.add_theme_font_size_override("font_size", 14)
		_inventory_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		equip_section.add_child(_inventory_label)

func _get_upgrade_cost(key: String) -> int:
	var base: int = UPGRADES[key]["base_cost"]
	var level: int = SaveManager.get_upgrade_level(key)
	return base * int(pow(2, level))

func _buy_upgrade(key: String) -> void:
	var cost := _get_upgrade_cost(key)
	if SaveManager.spend_gold(cost):
		SaveManager.set_upgrade_level(key, SaveManager.get_upgrade_level(key) + 1)
		SaveManager.save_game()
		_refresh_ui()

func _buy_skill(skill_id: String) -> void:
	var level: int = SaveManager.get_skill_level(skill_id)
	if level == 0:
		# First purchase: original cost
		var cost: int = SKILLS[skill_id]["cost"]
		if SaveManager.spend_gold(cost):
			SaveManager.set_skill_level(skill_id, 1)
			SaveManager.save_game()
			_refresh_ui()
	elif level in SKILL_UPGRADE_COSTS:
		# Upgrade to next level
		var cost: int = SKILL_UPGRADE_COSTS[level]
		if SaveManager.spend_gold(cost):
			SaveManager.set_skill_level(skill_id, level + 1)
			SaveManager.save_game()
			_refresh_ui()

func _continue_game() -> void:
	var gm := _get_game_manager()
	if gm:
		gm.reset_for_new_run()
	if SaveManager.is_boss_cleared():
		get_tree().change_scene_to_file("res://scenes/endless.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _refresh_ui() -> void:
	if _gold_label:
		_gold_label.text = str(SaveManager.get_gold())
	for key in _upgrade_rows:
		var row: Dictionary = _upgrade_rows[key]
		var level: int = SaveManager.get_upgrade_level(key)
		var cost: int = _get_upgrade_cost(key)
		row["level_label"].text = "Lv.%d" % level
		row["cost_label"].text = "%dG" % cost
		row["button"].disabled = SaveManager.get_gold() < cost
	for skill_id in _skill_rows:
		var row: Dictionary = _skill_rows[skill_id]
		var level: int = SaveManager.get_skill_level(skill_id)
		if level >= 3:
			row["button"].visible = false
			row["status_label"].text = "Lv.3 MAX"
			row["status_label"].add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		elif level > 0:
			var upgrade_cost: int = SKILL_UPGRADE_COSTS.get(level, 0)
			row["button"].visible = true
			row["button"].text = "Upgrade %dG" % upgrade_cost
			row["button"].disabled = SaveManager.get_gold() < upgrade_cost
			row["status_label"].text = "Lv.%d" % level
			row["status_label"].add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		else:
			row["button"].visible = true
			row["button"].text = "Buy %dG" % SKILLS[skill_id]["cost"]
			row["button"].disabled = SaveManager.get_gold() < SKILLS[skill_id]["cost"]
			row["status_label"].text = ""

	# Equipment display
	if _equip_weapon_label:
		var weapon_id: String = SaveManager.get_equipped_weapon()
		if weapon_id.is_empty():
			_equip_weapon_label.text = "Weapon: None"
			_equip_weapon_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		else:
			var item_data: Dictionary = ItemDatabase.get_item(weapon_id)
			_equip_weapon_label.text = "Weapon: %s (+%d ATK)" % [item_data.get("name", weapon_id), item_data.get("attack_bonus", 0)]
			_equip_weapon_label.add_theme_color_override("font_color", item_data.get("icon_color", Color.WHITE))

	if _equip_armor_label:
		var armor_id: String = SaveManager.get_equipped_armor()
		if armor_id.is_empty():
			_equip_armor_label.text = "Armor: None"
			_equip_armor_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		else:
			var item_data: Dictionary = ItemDatabase.get_item(armor_id)
			_equip_armor_label.text = "Armor: %s (+%d HP)" % [item_data.get("name", armor_id), item_data.get("hp_bonus", 0)]
			_equip_armor_label.add_theme_color_override("font_color", item_data.get("icon_color", Color.WHITE))

	if _inventory_label:
		var inv: Array = SaveManager.get_inventory()
		if inv.is_empty():
			_inventory_label.text = "Consumables: None"
		else:
			# Count items
			var counts: Dictionary = {}
			for item_id in inv:
				counts[item_id] = counts.get(item_id, 0) + 1
			var parts: Array[String] = []
			for item_id in counts:
				var item_data: Dictionary = ItemDatabase.get_item(item_id)
				parts.append("%s x%d" % [item_data.get("name", item_id), counts[item_id]])
			_inventory_label.text = "Consumables: %s" % ", ".join(parts)

func _get_game_manager() -> Node:
	var root_children := get_tree().root.get_children()
	for node in root_children:
		if node.name == "GameManager":
			return node
	return null
