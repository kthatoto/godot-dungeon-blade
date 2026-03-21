extends RefCounted
## res://scripts/item_database.gd — Static item definitions

const ITEMS := {
	"health_potion": {
		"name": "Health Potion", "type": "consumable",
		"description": "Restore 50% HP", "icon_color": Color(0.9, 0.2, 0.2),
	},
	"escape_scroll": {
		"name": "Escape Scroll", "type": "consumable",
		"description": "End run, keep gold", "icon_color": Color(0.4, 0.8, 1.0),
	},
	"iron_sword": {
		"name": "Iron Sword", "type": "weapon",
		"attack_bonus": 10, "icon_color": Color(0.7, 0.7, 0.7),
	},
	"iron_armor": {
		"name": "Iron Armor", "type": "armor",
		"hp_bonus": 30, "icon_color": Color(0.6, 0.5, 0.3),
	},
	"steel_sword": {
		"name": "Steel Sword", "type": "weapon",
		"attack_bonus": 20, "icon_color": Color(0.8, 0.85, 0.9),
	},
	"steel_armor": {
		"name": "Steel Armor", "type": "armor",
		"hp_bonus": 60, "icon_color": Color(0.5, 0.5, 0.6),
	},
}

static func get_item(id: String) -> Dictionary:
	if id in ITEMS:
		return ITEMS[id]
	return {}
