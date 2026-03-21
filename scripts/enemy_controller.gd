extends CharacterBody2D
## res://scripts/enemy_controller.gd — Skeleton enemy with patrol, chase, and contact damage

signal died(enemy: CharacterBody2D)

@export var speed: float = 80.0
@export var max_hp: int = 50
@export var contact_damage: int = 10
@export var chase_range: float = 200.0
@export var gold_value: int = 10

@onready var sprite: Sprite2D = $Sprite2D

var hp: int = 50
var is_dead: bool = false
var _patrol_dir: Vector2 = Vector2.RIGHT
var _patrol_timer: float = 0.0
var _state: String = "patrol"  # patrol, chase
var _player_ref: CharacterBody2D = null

func _ready() -> void:
	hp = max_hp
	_patrol_timer = randf_range(1.0, 3.0)
	add_to_group("enemies")
	# Randomize initial patrol direction
	_patrol_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	# Idle bob
	var tween := create_tween()
	tween.set_loops(0)
	tween.tween_property(sprite, ^"position:y", -1.5, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, ^"position:y", 1.5, 0.5).set_trans(Tween.TRANS_SINE)

	# Connect hurtbox
	$HurtBox.area_entered.connect(_on_hurt)

	# Register with game manager (only for fixed 3 rooms; endless mode handles its own registration)
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

	if _player_ref and not _player_ref.is_dead:
		var dist: float = global_position.distance_to(_player_ref.global_position)
		if dist < chase_range:
			_state = "chase"
		else:
			_state = "patrol"
	else:
		_state = "patrol"

	match _state:
		"patrol":
			_do_patrol(delta)
		"chase":
			_do_chase(delta)

	# Flip sprite
	if velocity.x < -5:
		sprite.flip_h = true
	elif velocity.x > 5:
		sprite.flip_h = false

	move_and_slide()

func _do_patrol(delta: float) -> void:
	_patrol_timer -= delta
	if _patrol_timer <= 0:
		_patrol_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		_patrol_timer = randf_range(2.0, 4.0)
	velocity = _patrol_dir * speed * 0.3

func _do_chase(delta: float) -> void:
	if _player_ref == null:
		return
	var dir := ((_player_ref.global_position - global_position).normalized())
	velocity = dir * speed

func _on_hurt(area: Area2D) -> void:
	# Hit by player's sword
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
	tween.tween_property(sprite, ^"modulate", Color.WHITE, 0.15)

	if hp <= 0:
		hp = 0
		_die()

func _die() -> void:
	is_dead = true
	died.emit(self)
	# Death animation
	var tween := create_tween()
	tween.tween_property(sprite, ^"modulate", Color(1.0, 0.3, 0.3, 0.3), 0.3)
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
	max_hp = int(50 * (1.0 + depth * 0.15))
	hp = max_hp
	contact_damage = int(10 * (1.0 + depth * 0.1))
	gold_value = int(10 * (1.0 + depth * 0.1))
	speed = 80.0 + depth * 5.0

func _get_room_index() -> int:
	var x: float = global_position.x
	if x < 1280:
		return 0
	elif x < 2560:
		return 1
	else:
		return 2
