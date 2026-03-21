extends Node2D
## res://scripts/town_controller.gd — Town scene: NPC buildings, shop overlays, dungeon entry

var _active_shop: String = ""
var _prompt_labels: Dictionary = {}  # building_name -> Label
var _player_ref: CharacterBody2D = null

const BUILDINGS := {
	"Blacksmith": { "interact": "blacksmith", "label": "Blacksmith", "range": 80.0 },
	"PotionShop": { "interact": "potion", "label": "Potion Shop", "range": 80.0 },
	"SkillTrainer": { "interact": "trainer", "label": "Skill Trainer", "range": 80.0 },
	"DungeonEntrance": { "interact": "dungeon", "label": "Dungeon Entrance", "range": 80.0 },
}

const BLACKSMITH_ITEMS := {
	"iron_sword":  { "name": "Iron Sword",  "cost": 200, "type": "weapon",  "stat": "attack_bonus",  "value": 10 },
	"iron_armor":  { "name": "Iron Armor",  "cost": 200, "type": "armor",   "stat": "hp_bonus",      "value": 30 },
	"steel_sword": { "name": "Steel Sword", "cost": 500, "type": "weapon",  "stat": "attack_bonus",  "value": 20 },
	"steel_armor": { "name": "Steel Armor", "cost": 500, "type": "armor",   "stat": "hp_bonus",      "value": 60 },
}

const POTION_ITEMS := {
	"health_potion":  { "name": "Health Potion",  "cost": 30 },
	"escape_scroll":  { "name": "Escape Scroll",  "cost": 50 },
}

const SKILLS := {
	"dash":     { "cost": 100, "label": "Dash (Q)",     "desc": "Quick dodge, 3s CD" },
	"fireball": { "cost": 200, "label": "Fireball (E)", "desc": "Ranged attack, 5s CD" },
	"heal":     { "cost": 150, "label": "Heal (R)",     "desc": "Restore 30% HP, 10s CD" },
}

func _ready() -> void:
	_setup_prompts()

func _setup_prompts() -> void:
	for building_name in BUILDINGS:
		var building_node := get_node_or_null(building_name)
		if building_node == null:
			continue
		var prompt := Label.new()
		prompt.name = "Prompt_" + building_name
		prompt.text = "[F] " + BUILDINGS[building_name]["label"]
		prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prompt.add_theme_font_size_override("font_size", 14)
		prompt.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
		prompt.position = Vector2(-60, -80)
		prompt.visible = false
		building_node.add_child(prompt)
		_prompt_labels[building_name] = prompt

func _process(_delta: float) -> void:
	if _active_shop != "":
		return
	if _player_ref == null or not is_instance_valid(_player_ref):
		_player_ref = _find_player()
	if _player_ref == null:
		return

	for building_name in BUILDINGS:
		var building_node := get_node_or_null(building_name)
		if building_node == null:
			continue
		var dist: float = _player_ref.global_position.distance_to(building_node.global_position)
		var in_range: bool = dist < BUILDINGS[building_name]["range"]
		if building_name in _prompt_labels:
			_prompt_labels[building_name].visible = in_range

	# Update gold display
	var gold_label := get_node_or_null("CanvasLayer/TownHUD/GoldDisplay")
	if gold_label:
		gold_label.text = "Gold: %d" % SaveManager.get_gold()

func _unhandled_input(event: InputEvent) -> void:
	if _active_shop != "":
		if event.is_action_pressed("ui_cancel"):
			_close_shop_overlay()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact"):
		_try_interact()
		get_viewport().set_input_as_handled()

func _try_interact() -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	for building_name in BUILDINGS:
		var building_node := get_node_or_null(building_name)
		if building_node == null:
			continue
		var dist: float = _player_ref.global_position.distance_to(building_node.global_position)
		if dist < BUILDINGS[building_name]["range"]:
			_interact(BUILDINGS[building_name]["interact"])
			return

func _interact(npc_type: String) -> void:
	match npc_type:
		"blacksmith":
			_open_shop_overlay("blacksmith")
		"potion":
			_open_shop_overlay("potion")
		"trainer":
			_open_shop_overlay("trainer")
		"dungeon":
			_start_dungeon()

func _start_dungeon() -> void:
	var gm := _get_game_manager()
	if gm:
		gm.reset_for_new_run()
	if SaveManager.is_boss_cleared():
		get_tree().change_scene_to_file("res://scenes/endless.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _open_shop_overlay(shop_type: String) -> void:
	if _active_shop != "":
		return
	_active_shop = shop_type

	var canvas := CanvasLayer.new()
	canvas.name = "ShopOverlay"
	canvas.layer = 20
	add_child(canvas)

	# Dark background
	var bg := ColorRect.new()
	bg.name = "ShopBG"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.7)
	canvas.add_child(bg)

	# Panel
	var panel := PanelContainer.new()
	panel.name = "ShopPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(500, 400)
	panel.position = Vector2(390, 160)
	canvas.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "ShopVBox"
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Close button
	var close_row := HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(close_row)
	var close_btn := Button.new()
	close_btn.name = "CloseBtn"
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(30, 30)
	close_btn.pressed.connect(_close_shop_overlay)
	close_row.add_child(close_btn)

	# Gold display
	var gold_label := Label.new()
	gold_label.name = "ShopGold"
	gold_label.text = "Gold: %d" % SaveManager.get_gold()
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 18)
	gold_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
	vbox.add_child(gold_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	match shop_type:
		"blacksmith":
			_build_blacksmith_shop(vbox)
		"potion":
			_build_potion_shop(vbox)
		"trainer":
			_build_trainer_shop(vbox)

func _build_blacksmith_shop(vbox: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "BLACKSMITH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
	vbox.add_child(title)

	for item_id in BLACKSMITH_ITEMS:
		var item: Dictionary = BLACKSMITH_ITEMS[item_id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		vbox.add_child(row)

		var name_label := Label.new()
		name_label.text = item["name"]
		name_label.custom_minimum_size = Vector2(140, 0)
		name_label.add_theme_font_size_override("font_size", 16)
		row.add_child(name_label)

		var cost_label := Label.new()
		cost_label.text = "%dG" % item["cost"]
		cost_label.custom_minimum_size = Vector2(80, 0)
		cost_label.add_theme_font_size_override("font_size", 16)
		cost_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
		row.add_child(cost_label)

		var owned: bool = _has_item(item_id)
		if owned:
			var owned_label := Label.new()
			owned_label.text = "OWNED"
			owned_label.add_theme_font_size_override("font_size", 14)
			owned_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
			row.add_child(owned_label)
		else:
			var buy_btn := Button.new()
			buy_btn.text = "BUY"
			buy_btn.custom_minimum_size = Vector2(70, 28)
			buy_btn.disabled = SaveManager.get_gold() < item["cost"]
			buy_btn.pressed.connect(_buy_blacksmith_item.bind(item_id))
			row.add_child(buy_btn)

func _build_potion_shop(vbox: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "POTION SHOP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	vbox.add_child(title)

	for item_id in POTION_ITEMS:
		var item: Dictionary = POTION_ITEMS[item_id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		vbox.add_child(row)

		var name_label := Label.new()
		name_label.text = item["name"]
		name_label.custom_minimum_size = Vector2(140, 0)
		name_label.add_theme_font_size_override("font_size", 16)
		row.add_child(name_label)

		var cost_label := Label.new()
		cost_label.text = "%dG" % item["cost"]
		cost_label.custom_minimum_size = Vector2(80, 0)
		cost_label.add_theme_font_size_override("font_size", 16)
		cost_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
		row.add_child(cost_label)

		var count_label := Label.new()
		count_label.name = "Count_" + item_id
		count_label.text = "x%d" % _get_inventory_count(item_id)
		count_label.custom_minimum_size = Vector2(40, 0)
		count_label.add_theme_font_size_override("font_size", 14)
		row.add_child(count_label)

		var buy_btn := Button.new()
		buy_btn.text = "BUY"
		buy_btn.custom_minimum_size = Vector2(70, 28)
		buy_btn.disabled = SaveManager.get_gold() < item["cost"]
		buy_btn.pressed.connect(_buy_potion_item.bind(item_id))
		row.add_child(buy_btn)

func _build_trainer_shop(vbox: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "SKILL TRAINER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.4, 0.6, 1.0))
	vbox.add_child(title)

	for skill_id in SKILLS:
		var skill: Dictionary = SKILLS[skill_id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		vbox.add_child(row)

		var name_label := Label.new()
		name_label.text = skill["label"]
		name_label.custom_minimum_size = Vector2(140, 0)
		name_label.add_theme_font_size_override("font_size", 16)
		row.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = skill["desc"]
		desc_label.custom_minimum_size = Vector2(160, 0)
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		row.add_child(desc_label)

		if SaveManager.has_skill(skill_id):
			var owned_label := Label.new()
			owned_label.text = "OWNED"
			owned_label.add_theme_font_size_override("font_size", 14)
			owned_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
			row.add_child(owned_label)
		else:
			var cost_label := Label.new()
			cost_label.text = "%dG" % skill["cost"]
			cost_label.custom_minimum_size = Vector2(60, 0)
			cost_label.add_theme_font_size_override("font_size", 16)
			cost_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
			row.add_child(cost_label)

			var buy_btn := Button.new()
			buy_btn.text = "BUY"
			buy_btn.custom_minimum_size = Vector2(70, 28)
			buy_btn.disabled = SaveManager.get_gold() < skill["cost"]
			buy_btn.pressed.connect(_buy_skill.bind(skill_id))
			row.add_child(buy_btn)

func _close_shop_overlay() -> void:
	_active_shop = ""
	var overlay := get_node_or_null("ShopOverlay")
	if overlay:
		overlay.queue_free()

func _buy_blacksmith_item(item_id: String) -> void:
	var item: Dictionary = BLACKSMITH_ITEMS[item_id]
	if SaveManager.spend_gold(item["cost"]):
		_add_item_to_inventory(item_id)
		SaveManager.save_game()
		# Rebuild overlay
		_close_shop_overlay()
		_open_shop_overlay("blacksmith")

func _buy_potion_item(item_id: String) -> void:
	var item: Dictionary = POTION_ITEMS[item_id]
	if SaveManager.spend_gold(item["cost"]):
		_add_item_to_inventory(item_id)
		SaveManager.save_game()
		# Rebuild overlay
		_close_shop_overlay()
		_open_shop_overlay("potion")

func _buy_skill(skill_id: String) -> void:
	var cost: int = SKILLS[skill_id]["cost"]
	if SaveManager.spend_gold(cost):
		SaveManager.unlock_skill(skill_id)
		SaveManager.save_game()
		# Rebuild overlay
		_close_shop_overlay()
		_open_shop_overlay("trainer")

# --- Inventory helpers ---
# Uses SaveManager API for persistence

func _has_item(item_id: String) -> bool:
	# For equipment: check equipped slots
	if item_id in BLACKSMITH_ITEMS:
		var item: Dictionary = BLACKSMITH_ITEMS[item_id]
		if item["type"] == "weapon":
			return SaveManager.get_equipped_weapon() == item_id
		elif item["type"] == "armor":
			return SaveManager.get_equipped_armor() == item_id
	# For consumables: check inventory array
	return item_id in SaveManager.get_inventory()

func _get_inventory_count(item_id: String) -> int:
	var count: int = 0
	for inv_item in SaveManager.get_inventory():
		if inv_item == item_id:
			count += 1
	return count

func _add_item_to_inventory(item_id: String) -> void:
	SaveManager.add_item(item_id)

func _find_player() -> CharacterBody2D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as CharacterBody2D
	return null

func _get_game_manager() -> Node:
	var root_children := get_tree().root.get_children()
	for node in root_children:
		if node.name == "GameManager":
			return node
	return null
