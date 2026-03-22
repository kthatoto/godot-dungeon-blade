extends Control
## res://scripts/hud_controller.gd — Unified HUD for town and dungeon

const ItemDatabase = preload("res://scripts/item_database.gd")

@onready var hp_bar: ProgressBar = $InfoPanel/VBox/HPRow/HPBar
@onready var hp_value: Label = $InfoPanel/VBox/HPRow/HPValue
@onready var gold_value: Label = $InfoPanel/VBox/GoldRow/GoldValue
@onready var equip_label: Label = $InfoPanel/VBox/EquipLabel
@onready var stats_label: Label = $InfoPanel/VBox/StatsLabel
@onready var room_label: Label = $RoomPanel/RoomLabel

var _overlay: ColorRect = null
var _message_label: Label = null
var _game_ended: bool = false
var _skill_slots: Array[Dictionary] = []
var _item_slots: Array[Dictionary] = []
var _skill_bar_created: bool = false
var _item_bar_created: bool = false

func _ready() -> void:
	_update_hp(100, 100)
	_update_gold(0)
	_update_equip()
	_update_room_label()
	_create_overlay()

func _create_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.name = "GameOverOverlay"
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
	_message_label.anchor_right = 1.0
	_message_label.anchor_bottom = 1.0
	_message_label.add_theme_font_size_override("font_size", 48)
	_message_label.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	_overlay.add_child(_message_label)

func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and "hp" in player and "max_hp" in player:
		_update_hp(player.hp, player.max_hp)

	var gm = _get_game_manager()
	if gm:
		if "run_gold" in gm:
			_update_gold(SaveManager.get_gold() + gm.run_gold)
		else:
			_update_gold(SaveManager.get_gold())

		if not _game_ended and "is_game_over" in gm and gm.is_game_over:
			_game_ended = true
			if player and "is_dead" in player and player.is_dead:
				_show_game_over(false)
			else:
				_show_game_over(true)

		_update_item_hotbar(gm)

	_update_equip()
	_update_room_label()

	if player:
		var skill_sys := player.get_node_or_null("SkillSystem")
		if skill_sys:
			_update_skill_hud(skill_sys)

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

func _update_gold(amount: int) -> void:
	if gold_value:
		gold_value.text = str(amount)

func _update_equip() -> void:
	if equip_label == null or stats_label == null:
		return
	var parts: Array[String] = []
	var weapon := SaveManager.get_equipped_weapon()
	if weapon != "":
		parts.append("%s(+%dATK)" % [weapon.replace("_", " ").capitalize(), SaveManager.get_weapon_bonus()])
	var armor := SaveManager.get_equipped_armor()
	if armor != "":
		parts.append("%s(+%dHP)" % [armor.replace("_", " ").capitalize(), SaveManager.get_armor_bonus()])
	equip_label.text = " | ".join(parts) if parts.size() > 0 else ""

	var atk := 25 + SaveManager.get_upgrade_level("attack_damage") * 5 + SaveManager.get_weapon_bonus()
	var max_hp := 100 + SaveManager.get_upgrade_level("max_hp") * 20 + SaveManager.get_armor_bonus()
	stats_label.text = "ATK: %d  MaxHP: %d" % [atk, max_hp]

func _update_room_label() -> void:
	if room_label == null:
		return
	var gm = _get_game_manager()
	if gm == null:
		room_label.text = "Town"
		return
	if gm.endless_mode:
		var depth: int = gm.dungeon_depth
		var is_boss: bool = depth > 0 and depth % 5 == 0
		room_label.text = "Depth %d%s" % [depth, " (BOSS)" if is_boss else ""]
	elif "current_room" in gm and gm.current_room >= 0:
		var scene_name := ""
		if get_tree().current_scene:
			scene_name = get_tree().current_scene.name
		if scene_name == "Town":
			room_label.text = "Town"
		else:
			room_label.text = "Room %d / 3" % (gm.current_room + 1)
	else:
		room_label.text = "Town"

func _on_room_changed(room_index: int) -> void:
	_update_room_label()

# ===== Skill HUD (lazy creation) =====

func _create_skill_hud() -> void:
	var skill_keys := ["Q", "E", "R"]
	var skill_names := ["Dash", "Fire", "Heal"]
	var skill_colors := [
		Color(0.4, 0.6, 1.0),
		Color(1.0, 0.5, 0.1),
		Color(0.3, 0.9, 0.3),
	]

	var container := HBoxContainer.new()
	container.name = "SkillBar"
	container.anchor_top = 1.0
	container.anchor_bottom = 1.0
	container.offset_left = 10
	container.offset_top = -66
	container.offset_bottom = -10
	container.add_theme_constant_override("separation", 8)
	add_child(container)

	for i in range(3):
		var panel := PanelContainer.new()
		panel.name = "SkillSlot_%d" % i
		panel.custom_minimum_size = Vector2(56, 56)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.05, 0.05, 0.1, 0.8)
		style.border_color = skill_colors[i].darkened(0.3)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		panel.add_theme_stylebox_override("panel", style)
		container.add_child(panel)

		var vbox2 := VBoxContainer.new()
		vbox2.alignment = BoxContainer.ALIGNMENT_CENTER
		panel.add_child(vbox2)

		var key_label := Label.new()
		key_label.text = skill_keys[i]
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_label.add_theme_font_size_override("font_size", 16)
		key_label.add_theme_color_override("font_color", skill_colors[i])
		vbox2.add_child(key_label)

		var name_label := Label.new()
		name_label.text = skill_names[i]
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		vbox2.add_child(name_label)

		var cd_overlay := ColorRect.new()
		cd_overlay.name = "CDOverlay"
		cd_overlay.color = Color(0, 0, 0, 0.6)
		cd_overlay.size = Vector2(56, 0)
		cd_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(cd_overlay)

		var cd_label := Label.new()
		cd_label.name = "CDLabel"
		cd_label.text = ""
		cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cd_label.anchor_right = 1.0
		cd_label.anchor_bottom = 1.0
		cd_label.add_theme_font_size_override("font_size", 14)
		cd_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
		cd_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(cd_label)

		_skill_slots.append({
			"panel": panel,
			"key_label": key_label,
			"cd_overlay": cd_overlay,
			"cd_label": cd_label,
		})

func _update_skill_hud(skill_sys: Node) -> void:
	var any_unlocked: bool = false
	for i in range(3):
		if skill_sys.is_unlocked(i):
			any_unlocked = true
			break

	if not any_unlocked:
		return

	if not _skill_bar_created:
		_create_skill_hud()
		_skill_bar_created = true

	for i in range(_skill_slots.size()):
		var slot: Dictionary = _skill_slots[i]
		var unlocked: bool = skill_sys.is_unlocked(i)
		slot["panel"].visible = unlocked
		if not unlocked:
			continue
		var ratio: float = skill_sys.get_cooldown_ratio(i)
		if ratio > 0:
			slot["cd_overlay"].size.y = 56.0 * ratio
			slot["cd_overlay"].color = Color(0, 0, 0, 0.5)
			slot["cd_label"].text = "%0.1f" % skill_sys.slots[i]["cooldown_current"]
		else:
			slot["cd_overlay"].size.y = 0
			slot["cd_label"].text = ""

# ===== Item Hotbar (lazy creation) =====

func _create_item_hotbar() -> void:
	var container := HBoxContainer.new()
	container.name = "ItemBar"
	container.anchor_left = 1.0
	container.anchor_top = 1.0
	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	container.offset_left = -240
	container.offset_top = -66
	container.offset_bottom = -10
	container.visible = false
	container.add_theme_constant_override("separation", 6)
	add_child(container)

	for i in range(4):
		var panel := PanelContainer.new()
		panel.name = "ItemSlot_%d" % i
		panel.custom_minimum_size = Vector2(52, 52)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.06, 0.04, 0.8)
		style.border_color = Color(0.5, 0.4, 0.3, 0.6)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 3
		panel.add_theme_stylebox_override("panel", style)
		container.add_child(panel)

		var vbox2 := VBoxContainer.new()
		vbox2.alignment = BoxContainer.ALIGNMENT_CENTER
		panel.add_child(vbox2)

		var key_label := Label.new()
		key_label.text = str(i + 1)
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_label.add_theme_font_size_override("font_size", 14)
		key_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
		vbox2.add_child(key_label)

		var name_label := Label.new()
		name_label.text = ""
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 8)
		name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		vbox2.add_child(name_label)

		_item_slots.append({
			"panel": panel,
			"key_label": key_label,
			"name_label": name_label,
		})

func _update_item_hotbar(gm: Node) -> void:
	if not "run_inventory" in gm:
		return
	var inv: Array = gm.run_inventory
	if inv.size() == 0:
		if _item_bar_created:
			var item_bar := get_node_or_null("ItemBar")
			if item_bar:
				item_bar.visible = false
		return

	if not _item_bar_created:
		_create_item_hotbar()
		_item_bar_created = true

	var item_bar := get_node_or_null("ItemBar")
	if item_bar:
		item_bar.visible = true

	for i in range(_item_slots.size()):
		var slot: Dictionary = _item_slots[i]
		if i < inv.size():
			slot["panel"].visible = true
			var item_id: String = inv[i]
			var item_data: Dictionary = ItemDatabase.get_item(item_id)
			slot["name_label"].text = item_data.get("name", item_id)
			slot["key_label"].add_theme_color_override("font_color", item_data.get("icon_color", Color.WHITE))
		else:
			slot["panel"].visible = false

func _get_game_manager() -> Node:
	var root_children := get_tree().root.get_children()
	for node in root_children:
		if node.name == "GameManager":
			return node
	return null
