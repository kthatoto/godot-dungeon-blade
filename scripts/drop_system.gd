extends RefCounted
## res://scripts/drop_system.gd — Loot drop logic

const ItemDatabase = preload("res://scripts/item_database.gd")

const DROP_TABLE := {
	"health_potion":   { "weight": 30, "min_depth": 0 },
	"escape_scroll":   { "weight": 10, "min_depth": 2 },
	"iron_sword":      { "weight": 8,  "min_depth": 1 },
	"iron_armor":      { "weight": 8,  "min_depth": 1 },
	"steel_sword":     { "weight": 4,  "min_depth": 5 },
	"steel_armor":     { "weight": 4,  "min_depth": 5 },
}

# Base drop chances by enemy type
const DROP_CHANCES := {
	"skeleton": 0.15, "strong_skeleton": 0.25, "archer": 0.20,
	"bat": 0.10, "boss": 0.80, "necromancer": 1.0,
}

static func try_drop(pos: Vector2, enemy_type: String, depth: int, scene: Node) -> void:
	var chance: float = DROP_CHANCES.get(enemy_type, 0.15)
	if randf() > chance:
		return

	# Build weighted list filtered by min_depth
	var valid_items: Array[Dictionary] = []
	var total_weight: int = 0
	for item_id in DROP_TABLE:
		var entry: Dictionary = DROP_TABLE[item_id]
		if depth >= entry["min_depth"]:
			valid_items.append({"id": item_id, "weight": entry["weight"]})
			total_weight += entry["weight"]

	if valid_items.is_empty() or total_weight <= 0:
		return

	# Weighted random pick
	var roll: int = randi() % total_weight
	var cumulative: int = 0
	var chosen_id: String = valid_items[0]["id"]
	for entry in valid_items:
		cumulative += entry["weight"]
		if roll < cumulative:
			chosen_id = entry["id"]
			break

	# Instantiate item pickup
	var pickup_scene := load("res://scenes/item_pickup.tscn") as PackedScene
	if pickup_scene == null:
		return
	var pickup := pickup_scene.instantiate()
	pickup.global_position = pos
	pickup.item_id = chosen_id
	scene.add_child(pickup)
