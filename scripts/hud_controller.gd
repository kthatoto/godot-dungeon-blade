extends Control
## res://scripts/hud_controller.gd — HUD showing HP, room, gold, and death/victory screens

@onready var hp_bar: ProgressBar = $InfoPanel/VBox/HPRow/HPBar
@onready var hp_value: Label = $InfoPanel/VBox/HPRow/HPValue
@onready var room_label: Label = $InfoPanel/VBox/RoomLabel
@onready var gold_value: Label = $GoldPanel/GoldRow/GoldValue

var _overlay: ColorRect = null
var _message_label: Label = null
var _game_ended: bool = false

func _ready() -> void:
	_update_hp(100, 100)
	_update_room(0)
	_update_gold(0)
	# Create overlay for death/victory (hidden initially)
	_create_overlay()

func _create_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.name = "GameOverOverlay"
	_overlay.anchors_preset = 15  # full rect
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	add_child(_overlay)

	_message_label = Label.new()
	_message_label.name = "MessageLabel"
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message_label.anchors_preset = 15
	_message_label.anchor_right = 1.0
	_message_label.anchor_bottom = 1.0
	_message_label.add_theme_font_size_override("font_size", 48)
	_message_label.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	_overlay.add_child(_message_label)

func _process(_delta: float) -> void:
	# Poll player HP from scene
	var player := get_tree().get_first_node_in_group("player")
	if player and "hp" in player and "max_hp" in player:
		_update_hp(player.hp, player.max_hp)

	# Poll game manager
	var gm = _get_game_manager()
	if gm:
		if "current_room" in gm:
			_update_room(gm.current_room)
		if "gold" in gm:
			_update_gold(gm.gold)
		# Check game over
		if not _game_ended and "is_game_over" in gm and gm.is_game_over:
			_game_ended = true
			# Determine win or lose
			if player and "is_dead" in player and player.is_dead:
				_show_game_over(false)
			else:
				_show_game_over(true)

func _show_game_over(won: bool) -> void:
	if _overlay == null or _message_label == null:
		return
	_overlay.visible = true
	if won:
		_message_label.text = "VICTORY!"
		_message_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 0))
		var tween := create_tween()
		tween.tween_property(_overlay, ^"color", Color(0, 0.05, 0.1, 0.7), 1.0)
		tween.parallel().tween_property(_message_label, ^"theme_override_colors/font_color", Color(1, 0.85, 0.2, 1), 1.0)
	else:
		_message_label.text = "YOU DIED"
		_message_label.add_theme_color_override("font_color", Color(0.8, 0.1, 0.1, 0))
		var tween := create_tween()
		tween.tween_property(_overlay, ^"color", Color(0.15, 0, 0, 0.8), 1.5)
		tween.parallel().tween_property(_message_label, ^"theme_override_colors/font_color", Color(0.8, 0.1, 0.1, 1), 1.5)

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

func _get_game_manager() -> Node:
	var root_children := get_tree().root.get_children()
	for node in root_children:
		if node.name == "GameManager":
			return node
	return null
