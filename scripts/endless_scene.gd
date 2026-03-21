extends Node2D
## res://scripts/endless_scene.gd — Initializes endless mode when scene loads

func _ready() -> void:
	# Tell GameManager to start endless mode
	var gm := _get_game_manager()
	if gm:
		gm.endless_mode = true
		gm.start_endless_run()

func _get_game_manager() -> Node:
	var root_children := get_tree().root.get_children()
	for node in root_children:
		if node.name == "GameManager":
			return node
	return null
