extends Area2D
## res://scripts/item_pickup.gd — Dropped item on the ground

const ItemDatabase = preload("res://scripts/item_database.gd")

var item_id: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Set visual from item database
	var item_data: Dictionary = ItemDatabase.get_item(item_id)
	if not item_data.is_empty():
		var visual := get_node_or_null("Visual") as ColorRect
		if visual:
			visual.color = item_data.get("icon_color", Color.WHITE)
		var label := get_node_or_null("NameLabel") as Label
		if label:
			label.text = item_data.get("name", item_id)
	# Bounce animation
	_start_bounce()

func _start_bounce() -> void:
	var tween := create_tween()
	tween.set_loops(0)  # infinite
	tween.tween_property(self, ^"position:y", position.y - 6.0, 0.4).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, ^"position:y", position.y + 2.0, 0.4).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	# Add item to run inventory via GameManager
	var gm := _get_game_manager()
	if gm and gm.has_method("add_item_to_run"):
		gm.add_item_to_run(item_id)
	# If equipment, auto-save to SaveManager
	var item_data: Dictionary = ItemDatabase.get_item(item_id)
	var item_type: String = item_data.get("type", "")
	if item_type == "weapon" or item_type == "armor":
		SaveManager.add_item(item_id)
		SaveManager.save_game()
	queue_free()

func _get_game_manager() -> Node:
	var root_children := get_tree().root.get_children()
	for node in root_children:
		if node.name == "GameManager":
			return node
	return null
