extends Control
## res://scripts/hud_controller.gd — HUD showing HP, room, and gold

@onready var hp_bar: ProgressBar = $InfoPanel/VBox/HPRow/HPBar
@onready var hp_value: Label = $InfoPanel/VBox/HPRow/HPValue
@onready var room_label: Label = $InfoPanel/VBox/RoomLabel
@onready var gold_value: Label = $GoldPanel/GoldRow/GoldValue

func _ready() -> void:
	_update_hp(100, 100)
	_update_room(0)
	_update_gold(0)

func _process(delta: float) -> void:
	# Poll player HP from scene
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("get") and "hp" in player and "max_hp" in player:
		_update_hp(player.hp, player.max_hp)

	# Poll game manager
	var gm_nodes := get_tree().root.get_children()
	for node in gm_nodes:
		if node.name == "GameManager":
			if "current_room" in node:
				_update_room(node.current_room)
			if "gold" in node:
				_update_gold(node.gold)
			break

func _update_hp(current: int, maximum: int) -> void:
	if hp_bar:
		hp_bar.max_value = maximum
		hp_bar.value = current
	if hp_value:
		hp_value.text = "%d/%d" % [current, maximum]

func _update_room(room_index: int) -> void:
	if room_label:
		room_label.text = "Room %d / 3" % (room_index + 1)

func _update_gold(amount: int) -> void:
	if gold_value:
		gold_value.text = str(amount)

func _on_room_changed(room_index: int) -> void:
	_update_room(room_index)
