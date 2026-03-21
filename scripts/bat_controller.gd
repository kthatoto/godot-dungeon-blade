extends CharacterBody2D
## res://scripts/bat_controller.gd — Fast swooping bat enemy that circles and dives at the player

const DropSystem = preload("res://scripts/drop_system.gd")

signal died(enemy: CharacterBody2D)

@export var speed: float = 180.0
@export var max_hp: int = 20
@export var contact_damage: int = 8
@export var gold_value: int = 8
@export var swoop_speed: float = 300.0
@export var swoop_interval: float = 3.0

@onready var sprite: Sprite2D = $Sprite2D

var hp: int = 20
var is_dead: bool = false
var _player_ref: CharacterBody2D = null
var _state: String = "circle"  # circle, swoop, retreat
var _state_timer: float = 0.0
var _orbit_angle: float = 0.0
var _swoop_timer: float = 0.0
var _swoop_target: Vector2 = Vector2.ZERO

const ORBIT_RADIUS := 150.0
const SWOOP_DURATION := 0.4
const RETREAT_DURATION := 0.8

func _ready() -> void:
	hp = max_hp
	_swoop_timer = swoop_interval
	_orbit_angle = randf() * TAU
	add_to_group("enemies")
	sprite.modulate = Color(0.7, 0.4, 1.0)
	sprite.scale = Vector2(1.5, 1.5)

	# Idle bob (faster for bat)
	var tween := create_tween()
	tween.set_loops(0)
	tween.tween_property(sprite, ^"position:y", -2.0, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, ^"position:y", 2.0, 0.3).set_trans(Tween.TRANS_SINE)

	# Connect hurtbox
	$HurtBox.area_entered.connect(_on_hurt)

	# Register with game manager (only for fixed rooms; endless mode handles its own registration)
	var gm = _get_game_manager()
	if gm and not gm.endless_mode:
		var room_idx: int = _get_room_index()
		gm.register_enemy(room_idx)
		died.connect(gm._on_enemy_died)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Find player
	if _player_ref == null or not is_instance_valid(_player_ref):
		_player_ref = _find_player()

	if _player_ref == null or _player_ref.is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_state_timer -= delta

	match _state:
		"circle":
			_do_circle(delta)
		"swoop":
			_do_swoop(delta)
		"retreat":
			_do_retreat(delta)

	# Flip sprite
	if velocity.x < -5:
		sprite.flip_h = true
	elif velocity.x > 5:
		sprite.flip_h = false

	move_and_slide()

func _do_circle(delta: float) -> void:
	if _player_ref == null:
		return
	_orbit_angle += delta * 2.0  # orbit speed
	var target_pos := _player_ref.global_position + Vector2(cos(_orbit_angle), sin(_orbit_angle)) * ORBIT_RADIUS
	var dir := (target_pos - global_position).normalized()
	velocity = dir * speed

	# Check swoop timer
	_swoop_timer -= delta
	if _swoop_timer <= 0:
		_state = "swoop"
		_state_timer = SWOOP_DURATION
		_swoop_target = _player_ref.global_position
		_swoop_timer = swoop_interval

func _do_swoop(delta: float) -> void:
	var dir := (_swoop_target - global_position).normalized()
	velocity = dir * swoop_speed
	if _state_timer <= 0:
		_state = "retreat"
		_state_timer = RETREAT_DURATION

func _do_retreat(delta: float) -> void:
	if _player_ref == null:
		velocity = Vector2.ZERO
		if _state_timer <= 0:
			_state = "circle"
		return
	var dir := (global_position - _player_ref.global_position).normalized()
	velocity = dir * speed
	if _state_timer <= 0:
		_state = "circle"

func _on_hurt(area: Area2D) -> void:
	var parent := area.get_parent()
	if parent and parent.is_in_group("player"):
		if parent.has_method("get") and "attack_damage" in parent:
			take_damage(parent.attack_damage)
		else:
			take_damage(25)

func take_damage(amount: int) -> void:
	if is_dead:
		return
	hp -= amount
	# Flash white
	var tween := create_tween()
	tween.tween_property(sprite, ^"modulate", Color(2.0, 2.0, 2.0), 0.05)
	tween.tween_property(sprite, ^"modulate", Color(0.7, 0.4, 1.0), 0.15)

	if hp <= 0:
		hp = 0
		_die()

func _die() -> void:
	is_dead = true
	died.emit(self)
	var depth: int = 0
	var gm = _get_game_manager()
	if gm:
		depth = gm.dungeon_depth if gm.endless_mode else _get_room_index()
	DropSystem.try_drop(global_position, "bat", depth, get_tree().current_scene)
	# Death animation
	var tween := create_tween()
	tween.tween_property(sprite, ^"modulate", Color(0.5, 0.2, 0.8, 0.3), 0.3)
	tween.tween_property(sprite, ^"scale", Vector2(2.0, 0.3), 0.2)
	tween.tween_callback(queue_free)

func _find_player() -> CharacterBody2D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as CharacterBody2D
	return null

func _get_game_manager() -> Node:
	var root_children := get_tree().root.get_children()
	for node in root_children:
		if node.name == "GameManager":
			return node
	return null

func apply_depth_scaling(depth: int) -> void:
	max_hp = int(20 * (1.0 + depth * 0.15))
	hp = max_hp
	contact_damage = int(8 * (1.0 + depth * 0.1))
	gold_value = int(8 * (1.0 + depth * 0.1))
	speed = 180.0 + depth * 5.0

func _get_room_index() -> int:
	var x: float = global_position.x
	if x < 1280:
		return 0
	elif x < 2560:
		return 1
	else:
		return 2
