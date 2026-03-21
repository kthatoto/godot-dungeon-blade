extends Control
## res://scripts/upgrade_shop_controller.gd — Upgrade shop UI logic

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

var _gold_label: Label
var _upgrade_rows: Dictionary = {}  # key -> { "level_label", "cost_label", "button" }
var _skill_rows: Dictionary = {}    # key -> { "button", "status_label" }

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
	var cost: int = SKILLS[skill_id]["cost"]
	if SaveManager.spend_gold(cost):
		SaveManager.unlock_skill(skill_id)
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
		if SaveManager.has_skill(skill_id):
			row["button"].visible = false
			row["status_label"].text = "OWNED"
			row["status_label"].add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		else:
			row["button"].visible = true
			row["button"].disabled = SaveManager.get_gold() < SKILLS[skill_id]["cost"]

func _get_game_manager() -> Node:
	var root_children := get_tree().root.get_children()
	for node in root_children:
		if node.name == "GameManager":
			return node
	return null
