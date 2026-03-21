extends Node
## res://scripts/skill_system.gd — Manages active skills with cooldowns

signal skill_used(slot_index: int, skill_id: String)
signal cooldown_updated(slot_index: int, ratio: float)

const SKILL_DEFS := {
	"dash":     { "cooldown": 3.0,  "slot": 0 },
	"fireball": { "cooldown": 5.0,  "slot": 1 },
	"heal":     { "cooldown": 10.0, "slot": 2 },
}

const SLOT_ACTIONS := ["skill_1", "skill_2", "skill_3"]
const SLOT_IDS := ["dash", "fireball", "heal"]

var slots: Array[Dictionary] = []  # { "id", "cooldown_max", "cooldown_current", "unlocked" }

func _ready() -> void:
	for i in range(3):
		var skill_id: String = SLOT_IDS[i]
		var def: Dictionary = SKILL_DEFS[skill_id]
		slots.append({
			"id": skill_id,
			"cooldown_max": def["cooldown"],
			"cooldown_current": 0.0,
			"unlocked": SaveManager.has_skill(skill_id),
		})

func _process(delta: float) -> void:
	for i in range(slots.size()):
		if slots[i]["cooldown_current"] > 0:
			slots[i]["cooldown_current"] -= delta
			if slots[i]["cooldown_current"] < 0:
				slots[i]["cooldown_current"] = 0.0

	# Check input
	for i in range(slots.size()):
		if slots[i]["unlocked"] and Input.is_action_just_pressed(SLOT_ACTIONS[i]):
			try_use_skill(i)

func try_use_skill(slot_index: int) -> void:
	var slot: Dictionary = slots[slot_index]
	if not slot["unlocked"]:
		return
	if slot["cooldown_current"] > 0:
		return
	# Start cooldown
	slot["cooldown_current"] = slot["cooldown_max"]
	# Execute skill on player
	var player := get_parent()
	if player == null:
		return
	match slot["id"]:
		"dash":
			if player.has_method("perform_dash"):
				player.perform_dash()
		"fireball":
			if player.has_method("perform_fireball"):
				player.perform_fireball()
		"heal":
			if player.has_method("perform_heal"):
				player.perform_heal()
	skill_used.emit(slot_index, slot["id"])

func get_cooldown_ratio(slot_index: int) -> float:
	if slot_index < 0 or slot_index >= slots.size():
		return 0.0
	var slot: Dictionary = slots[slot_index]
	if slot["cooldown_max"] <= 0:
		return 0.0
	return slot["cooldown_current"] / slot["cooldown_max"]

func is_unlocked(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	return slots[slot_index]["unlocked"]
