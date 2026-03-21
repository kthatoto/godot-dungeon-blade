extends CharacterBody2D
## res://scripts/archer_controller.gd — Ranged archer enemy that keeps distance and shoots arrows

const DropSystem = preload("res://scripts/drop_system.gd")

signal died(enemy: CharacterBody2D)

@export var speed: float = 60.0
@export var max_hp: int = 30
@export var contact_damage: int = 5
@export var chase_range: float = 300.0
@export var gold_value: int = 15
@export var shoot_interval: float = 2.0
@export var preferred_range: float = 250.0
@export var flee_range: float = 100.0

@onready var sprite: Sprite2D = $Sprite2D

var hp: int = 30
var is_dead: bool = false
var _player_ref: CharacterBody2D = null
var _state: String = "idle"  # idle, reposition, shoot
var _shoot_timer: float = 0.0

func _ready() -> void:
	hp = max_hp
	_shoot_timer = shoot_interval
	add_to_group("enemies")
	sprite.modulate = Color(0.5, 0.7, 1.2)

	# Idle bob
	var tween := create_tween()
	tween.set_loops(0)
	tween.tween_property(sprite, ^"position:y", -1.5, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, ^"position:y", 1.5, 0.5).set_trans(Tween.TRANS_SINE)

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
		_state = "idle"
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dist: float = global_position.distance_to(_player_ref.global_position)

	if dist > chase_range:
		_state = "idle"
		velocity = Vector2.ZERO
	else:
		# Maintain preferred range
		if dist < flee_range:
			# Too close — flee away
			_state = "reposition"
			var dir := (global_position - _player_ref.global_position).normalized()
			velocity = dir * speed * 1.5
		elif dist > preferred_range:
			# Too far — move closer
			_state = "reposition"
			var dir := (_player_ref.global_position - global_position).normalized()
			velocity = dir * speed
		else:
			# Good range — strafe slightly
			_state = "shoot"
			velocity = velocity.lerp(Vector2.ZERO, 0.1)

		# Shoot timer
		_shoot_timer -= delta
		if _shoot_timer <= 0 and dist <= chase_range:
			_shoot()
			_shoot_timer = shoot_interval

	# Flip sprite
	if _player_ref:
		if _player_ref.global_position.x < global_position.x:
			sprite.flip_h = true
		else:
			sprite.flip_h = false

	move_and_slide()

func _shoot() -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	var arrow_scene: PackedScene = load("res://scenes/arrow.tscn")
	var arrow := arrow_scene.instantiate()
	arrow.global_position = global_position
	arrow.direction = (_player_ref.global_position - global_position).normalized()
	get_tree().current_scene.add_child(arrow)

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
	tween.tween_property(sprite, ^"modulate", Color(0.5, 0.7, 1.2), 0.15)

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
	DropSystem.try_drop(global_position, "archer", depth, get_tree().current_scene)
	# Death animation
	var tween := create_tween()
	tween.tween_property(sprite, ^"modulate", Color(0.3, 0.5, 1.0, 0.3), 0.3)
	tween.tween_property(sprite, ^"scale", Vector2(2.5, 0.5), 0.2)
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
	max_hp = int(30 * (1.0 + depth * 0.15))
	hp = max_hp
	contact_damage = int(5 * (1.0 + depth * 0.1))
	gold_value = int(15 * (1.0 + depth * 0.1))
	speed = 60.0 + depth * 5.0

func _get_room_index() -> int:
	var x: float = global_position.x
	if x < 1280:
		return 0
	elif x < 2560:
		return 1
	else:
		return 2
