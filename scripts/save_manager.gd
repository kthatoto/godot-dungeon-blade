extends Node
## res://scripts/save_manager.gd — Persistent save/load for gold, upgrades, skills, inventory, equipment

const ItemDatabase = preload("res://scripts/item_database.gd")
const SAVE_PATH := "user://save_data.json"

var data: Dictionary = {
	"persistent_gold": 0,
	"boss_cleared": false,
	"upgrades": {
		"max_hp": 0,
		"attack_damage": 0,
		"speed": 0,
		"regen_rate": 0,
	},
	"skills_unlocked": [],
	"skill_levels": {"dash": 0, "fireball": 0, "heal": 0},
	"inventory": [],
	"equipped_weapon": "",
	"equipped_armor": "",
}

func _ready() -> void:
	load_game()

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		push_warning("SaveManager: corrupted save, using defaults")
		return
	var loaded: Variant = json.data
	if loaded is Dictionary:
		# Merge loaded data, preserving defaults for missing keys
		if "persistent_gold" in loaded:
			data["persistent_gold"] = int(loaded["persistent_gold"])
		if "upgrades" in loaded and loaded["upgrades"] is Dictionary:
			for key in data["upgrades"]:
				if key in loaded["upgrades"]:
					data["upgrades"][key] = int(loaded["upgrades"][key])
		if "boss_cleared" in loaded:
			data["boss_cleared"] = bool(loaded["boss_cleared"])

		# Backward compatibility: convert old skills_unlocked Array to skill_levels
		if "skill_levels" in loaded and loaded["skill_levels"] is Dictionary:
			for key in data["skill_levels"]:
				if key in loaded["skill_levels"]:
					data["skill_levels"][key] = int(loaded["skill_levels"][key])
			# Also keep skills_unlocked in sync
			data["skills_unlocked"] = []
			for skill_id in data["skill_levels"]:
				if data["skill_levels"][skill_id] > 0:
					data["skills_unlocked"].append(skill_id)
		elif "skills_unlocked" in loaded and loaded["skills_unlocked"] is Array:
			data["skills_unlocked"] = loaded["skills_unlocked"]
			# Convert old format: each skill in array = level 1
			for skill_id in loaded["skills_unlocked"]:
				if skill_id in data["skill_levels"]:
					data["skill_levels"][skill_id] = 1

		# Inventory and equipment
		if "inventory" in loaded and loaded["inventory"] is Array:
			data["inventory"] = loaded["inventory"]
		if "equipped_weapon" in loaded and loaded["equipped_weapon"] is String:
			data["equipped_weapon"] = loaded["equipped_weapon"]
		if "equipped_armor" in loaded and loaded["equipped_armor"] is String:
			data["equipped_armor"] = loaded["equipped_armor"]

func add_gold(amount: int) -> void:
	data["persistent_gold"] += amount

func spend_gold(amount: int) -> bool:
	if data["persistent_gold"] >= amount:
		data["persistent_gold"] -= amount
		return true
	return false

func get_gold() -> int:
	return data["persistent_gold"]

func get_upgrade_level(key: String) -> int:
	if key in data["upgrades"]:
		return data["upgrades"][key]
	return 0

func set_upgrade_level(key: String, level: int) -> void:
	data["upgrades"][key] = level

func unlock_skill(skill_id: String) -> void:
	if skill_id not in data["skills_unlocked"]:
		data["skills_unlocked"].append(skill_id)
	# Also set skill_levels to 1 if not already higher
	if data["skill_levels"].get(skill_id, 0) < 1:
		data["skill_levels"][skill_id] = 1

func has_skill(skill_id: String) -> bool:
	return data.get("skill_levels", {}).get(skill_id, 0) > 0

func is_boss_cleared() -> bool:
	return data["boss_cleared"]

func mark_boss_cleared() -> void:
	data["boss_cleared"] = true

## --- Skill levels ---

func get_skill_level(skill_id: String) -> int:
	return data.get("skill_levels", {}).get(skill_id, 0)

func set_skill_level(skill_id: String, level: int) -> void:
	data["skill_levels"][skill_id] = level
	# Keep skills_unlocked in sync
	if level > 0 and skill_id not in data["skills_unlocked"]:
		data["skills_unlocked"].append(skill_id)

## --- Inventory & equipment ---

func add_item(item_id: String) -> void:
	var item_data: Dictionary = ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return
	var item_type: String = item_data.get("type", "")
	if item_type == "weapon":
		# Auto-equip if better
		var current_bonus: int = get_weapon_bonus()
		var new_bonus: int = item_data.get("attack_bonus", 0)
		if new_bonus > current_bonus:
			equip_weapon(item_id)
	elif item_type == "armor":
		# Auto-equip if better
		var current_bonus: int = get_armor_bonus()
		var new_bonus: int = item_data.get("hp_bonus", 0)
		if new_bonus > current_bonus:
			equip_armor(item_id)
	else:
		# Consumable: add to inventory
		data["inventory"].append(item_id)

func remove_item(item_id: String) -> void:
	var idx: int = data["inventory"].find(item_id)
	if idx >= 0:
		data["inventory"].remove_at(idx)

func get_inventory() -> Array:
	return data["inventory"]

func equip_weapon(item_id: String) -> void:
	data["equipped_weapon"] = item_id

func equip_armor(item_id: String) -> void:
	data["equipped_armor"] = item_id

func get_equipped_weapon() -> String:
	return data["equipped_weapon"]

func get_equipped_armor() -> String:
	return data["equipped_armor"]

func get_weapon_bonus() -> int:
	var weapon_id: String = data["equipped_weapon"]
	if weapon_id.is_empty():
		return 0
	var item_data: Dictionary = ItemDatabase.get_item(weapon_id)
	return item_data.get("attack_bonus", 0)

func get_armor_bonus() -> int:
	var armor_id: String = data["equipped_armor"]
	if armor_id.is_empty():
		return 0
	var item_data: Dictionary = ItemDatabase.get_item(armor_id)
	return item_data.get("hp_bonus", 0)

func reset_save() -> void:
	data = {
		"persistent_gold": 0,
		"boss_cleared": false,
		"upgrades": {
			"max_hp": 0,
			"attack_damage": 0,
			"speed": 0,
			"regen_rate": 0,
		},
		"skills_unlocked": [],
		"skill_levels": {"dash": 0, "fireball": 0, "heal": 0},
		"inventory": [],
		"equipped_weapon": "",
		"equipped_armor": "",
	}
	save_game()
