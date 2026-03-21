extends Node
## res://scripts/save_manager.gd — Persistent save/load for gold, upgrades, and skills

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
		if "skills_unlocked" in loaded and loaded["skills_unlocked"] is Array:
			data["skills_unlocked"] = loaded["skills_unlocked"]

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

func has_skill(skill_id: String) -> bool:
	return skill_id in data["skills_unlocked"]

func is_boss_cleared() -> bool:
	return data["boss_cleared"]

func mark_boss_cleared() -> void:
	data["boss_cleared"] = true

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
	}
	save_game()
