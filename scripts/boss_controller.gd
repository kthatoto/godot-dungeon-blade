extends CharacterBody2D
## res://scripts/boss_controller.gd — Boss with chase, charge attack, and area slam

signal died

@export var speed: float = 100.0
@export var max_hp: int = 300
@export var contact_damage: int = 20
@export var slam_damage: int = 40
@export var gold_value: int = 100
@export var chase_range: float = 400.0
@export var charge_speed: float = 350.0

@onready var sprite: Sprite2D = $Sprite2D

var hp: int = 300
var is_dead: bool = false
var _player_ref: CharacterBody2D = null
var _state: String = "idle"  # idle, chase, telegraph_charge, charge, telegraph_slam, slam, cooldown
var _state_timer: float = 0.0
var _charge_dir: Vector2 = Vector2.ZERO
var _attack_cycle: int = 0  # alternates between charge and slam
var _cooldown_time: float = 1.5

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	# Menacing bob (slower, larger)
	var tween := create_tween()
	tween.set_loops(0)
	tween.tween_property(sprite, ^"position:y", -3.0, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, ^"position:y", 3.0, 0.8).set_trans(Tween.TRANS_SINE)

	# Connect hurtbox
	$HurtBox.area_entered.connect(_on_hurt)

	# Register with game manager
	var gm = _get_game_manager()
	if gm:
		gm.register_enemy(2)  # Boss is always in room 3
		died.connect(gm._on_boss_died)

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Find player
	if _player_ref == null or not is_instance_valid(_player_ref):
		_player_ref = _find_player()

	_state_timer -= delta

	match _state:
		"idle":
			_do_idle(delta)
		"chase":
			_do_chase(delta)
		"telegraph_charge":
			_do_telegraph_charge(delta)
		"charge":
			_do_charge(delta)
		"telegraph_slam":
			_do_telegraph_slam(delta)
		"slam":
			_do_slam(delta)
		"cooldown":
			_do_cooldown(delta)

	# Flip sprite toward player
	if _player_ref and is_instance_valid(_player_ref):
		if _player_ref.global_position.x < global_position.x:
			sprite.flip_h = true
		else:
			sprite.flip_h = false

	move_and_slide()

func _do_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	if _player_ref and is_instance_valid(_player_ref) and not _player_ref.is_dead:
		var dist: float = global_position.distance_to(_player_ref.global_position)
		if dist < chase_range:
			_state = "chase"

func _do_chase(delta: float) -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		_state = "idle"
		return
	var dir := (_player_ref.global_position - global_position).normalized()
	velocity = dir * speed

	var dist: float = global_position.distance_to(_player_ref.global_position)
	# Start attack when close enough
	if dist < 150.0:
		if _attack_cycle % 2 == 0:
			_start_telegraph_charge()
		else:
			_start_telegraph_slam()
		_attack_cycle += 1

func _start_telegraph_charge() -> void:
	_state = "telegraph_charge"
	_state_timer = 0.8
	velocity = Vector2.ZERO
	# Visual telegraph: flash yellow
	var tween := create_tween()
	tween.tween_property(sprite, ^"modulate", Color(1.5, 1.2, 0.3), 0.2)
	tween.tween_property(sprite, ^"modulate", Color(1.8, 0.8, 0.2), 0.2)
	tween.tween_property(sprite, ^"modulate", Color(1.5, 1.2, 0.3), 0.2)
	tween.tween_property(sprite, ^"modulate", Color.WHITE, 0.2)

func _do_telegraph_charge(delta: float) -> void:
	velocity = Vector2.ZERO
	if _state_timer <= 0:
		# Charge toward player's current position
		if _player_ref and is_instance_valid(_player_ref):
			_charge_dir = (_player_ref.global_position - global_position).normalized()
		else:
			_charge_dir = Vector2.RIGHT
		_state = "charge"
		_state_timer = 0.6

func _do_charge(delta: float) -> void:
	velocity = _charge_dir * charge_speed
	# Check if hit player during charge
	_check_charge_hit()
	if _state_timer <= 0:
		_state = "cooldown"
		_state_timer = _cooldown_time
		velocity = Vector2.ZERO

func _check_charge_hit() -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	var dist: float = global_position.distance_to(_player_ref.global_position)
	if dist < 50.0:
		if _player_ref.has_method("take_damage"):
			_player_ref.take_damage(contact_damage)
			# Push player away
			var push_dir := (_player_ref.global_position - global_position).normalized()
			_player_ref.velocity = push_dir * 200.0

func _start_telegraph_slam() -> void:
	_state = "telegraph_slam"
	_state_timer = 1.0
	velocity = Vector2.ZERO
	# Visual telegraph: grow and flash red
	var tween := create_tween()
	tween.tween_property(sprite, ^"scale", Vector2(2.5, 2.5), 0.3)
	tween.tween_property(sprite, ^"modulate", Color(1.5, 0.2, 0.2), 0.3)
	tween.tween_property(sprite, ^"modulate", Color(2.0, 0.3, 0.3), 0.2)
	tween.tween_property(sprite, ^"modulate", Color(1.5, 0.2, 0.2), 0.2)

func _do_telegraph_slam(delta: float) -> void:
	velocity = Vector2.ZERO
	if _state_timer <= 0:
		_state = "slam"
		_state_timer = 0.3
		# Enable attack area
		$AttackArea/CollisionShape2D.set_deferred("disabled", false)
		# Slam visual
		var tween := create_tween()
		tween.tween_property(sprite, ^"scale", Vector2(2.0, 2.0), 0.1)
		tween.tween_property(sprite, ^"modulate", Color.WHITE, 0.2)
		# Damage nearby player
		_do_slam_damage()

func _do_slam(delta: float) -> void:
	velocity = Vector2.ZERO
	if _state_timer <= 0:
		$AttackArea/CollisionShape2D.set_deferred("disabled", true)
		_state = "cooldown"
		_state_timer = _cooldown_time

func _do_slam_damage() -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	var dist: float = global_position.distance_to(_player_ref.global_position)
	if dist < 80.0:
		if _player_ref.has_method("take_damage"):
			_player_ref.take_damage(slam_damage)
			# Knockback
			var push_dir := (_player_ref.global_position - global_position).normalized()
			_player_ref.velocity = push_dir * 250.0

func _do_cooldown(delta: float) -> void:
	velocity = Vector2.ZERO
	if _state_timer <= 0:
		if _player_ref and is_instance_valid(_player_ref) and not _player_ref.is_dead:
			_state = "chase"
		else:
			_state = "idle"

func _on_hurt(area: Area2D) -> void:
	# Hit by player's sword
	var parent := area.get_parent()
	if parent and parent.is_in_group("player"):
		if "attack_damage" in parent:
			take_damage(parent.attack_damage)
		else:
			take_damage(25)

func take_damage(amount: int) -> void:
	if is_dead:
		return
	hp -= amount
	# Flash red
	var tween := create_tween()
	tween.tween_property(sprite, ^"modulate", Color(1.5, 0.3, 0.3), 0.05)
	tween.tween_property(sprite, ^"modulate", Color.WHITE, 0.2)

	if hp <= 0:
		hp = 0
		_die()

func _die() -> void:
	is_dead = true
	died.emit()
	# Death animation
	var tween := create_tween()
	tween.tween_property(sprite, ^"modulate", Color(1.0, 0.0, 0.0, 0.3), 0.5)
	tween.tween_property(sprite, ^"scale", Vector2(3.0, 0.5), 0.3)
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
