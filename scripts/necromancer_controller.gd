extends CharacterBody2D
## res://scripts/necromancer_controller.gd — Necromancer boss that summons skeletons and shoots dark projectiles

const DropSystem = preload("res://scripts/drop_system.gd")

signal died

@export var speed: float = 60.0
@export var max_hp: int = 250
@export var contact_damage: int = 15
@export var slam_damage: int = 0
@export var gold_value: int = 150
@export var chase_range: float = 400.0
@export var summon_cooldown: float = 6.0
@export var shoot_cooldown: float = 2.5
@export var max_summons: int = 3

@onready var sprite: Sprite2D = $Sprite2D

var hp: int = 250
var is_dead: bool = false
var _player_ref: CharacterBody2D = null
var _state: String = "idle"  # idle, chase, telegraph_summon, summon, telegraph_shoot, shoot, cooldown
var _state_timer: float = 0.0
var _attack_step: int = 0  # 0=summon, 1=shoot, 2=shoot, then cooldown and repeat
var _current_summons: int = 0
var _cooldown_time: float = 2.0

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	sprite.modulate = Color(0.6, 0.3, 0.8)

	# Menacing bob (slower, larger)
	var tween := create_tween()
	tween.set_loops(0)
	tween.tween_property(sprite, ^"position:y", -3.0, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, ^"position:y", 3.0, 0.8).set_trans(Tween.TRANS_SINE)

	# Connect hurtbox
	$HurtBox.area_entered.connect(_on_hurt)

	# Register with game manager (only for fixed rooms; endless mode handles its own registration)
	var gm = _get_game_manager()
	if gm and not gm.endless_mode:
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
		"telegraph_summon":
			_do_telegraph_summon(delta)
		"summon":
			_do_summon(delta)
		"telegraph_shoot":
			_do_telegraph_shoot(delta)
		"shoot":
			_do_shoot(delta)
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
	if dist < 200.0:
		_start_next_attack()

func _start_next_attack() -> void:
	match _attack_step % 3:
		0:
			_start_telegraph_summon()
		1:
			_start_telegraph_shoot()
		2:
			_start_telegraph_shoot()
	_attack_step += 1

func _start_telegraph_summon() -> void:
	_state = "telegraph_summon"
	_state_timer = 1.0
	velocity = Vector2.ZERO
	# Purple flash telegraph
	var tween := create_tween()
	tween.tween_property(sprite, ^"modulate", Color(1.0, 0.3, 1.5), 0.25)
	tween.tween_property(sprite, ^"modulate", Color(0.6, 0.3, 0.8), 0.25)
	tween.tween_property(sprite, ^"modulate", Color(1.0, 0.3, 1.5), 0.25)
	tween.tween_property(sprite, ^"modulate", Color(0.6, 0.3, 0.8), 0.25)

func _do_telegraph_summon(delta: float) -> void:
	velocity = Vector2.ZERO
	if _state_timer <= 0:
		_state = "summon"
		_state_timer = 0.3
		_perform_summon()

func _perform_summon() -> void:
	if _current_summons >= max_summons:
		return
	var enemy_scene: PackedScene = load("res://scenes/enemy.tscn")
	var summon_count: int = randi_range(1, 2)
	for i in range(summon_count):
		if _current_summons >= max_summons:
			break
		var enemy := enemy_scene.instantiate() as CharacterBody2D
		enemy.name = "Summon_%d" % randi()
		var offset := Vector2(randf_range(-80, 80), randf_range(-80, 80))
		enemy.position = global_position + offset
		# DON'T connect their died to GameManager (they don't count for room clear)
		# Connect their died to track summon count
		enemy.died.connect(_on_summon_died)
		# Set low gold value for summons
		enemy.gold_value = 5
		get_tree().current_scene.add_child(enemy)
		_current_summons += 1

func _on_summon_died(_enemy: CharacterBody2D) -> void:
	_current_summons -= 1
	if _current_summons < 0:
		_current_summons = 0

func _do_summon(delta: float) -> void:
	velocity = Vector2.ZERO
	if _state_timer <= 0:
		_state = "cooldown"
		_state_timer = _cooldown_time

func _start_telegraph_shoot() -> void:
	_state = "telegraph_shoot"
	_state_timer = 0.6
	velocity = Vector2.ZERO
	# Dark red flash telegraph
	var tween := create_tween()
	tween.tween_property(sprite, ^"modulate", Color(1.5, 0.2, 0.2), 0.15)
	tween.tween_property(sprite, ^"modulate", Color(0.8, 0.1, 0.3), 0.15)
	tween.tween_property(sprite, ^"modulate", Color(1.5, 0.2, 0.2), 0.15)
	tween.tween_property(sprite, ^"modulate", Color(0.6, 0.3, 0.8), 0.15)

func _do_telegraph_shoot(delta: float) -> void:
	velocity = Vector2.ZERO
	if _state_timer <= 0:
		_state = "shoot"
		_state_timer = 0.3
		_perform_shoot()

func _perform_shoot() -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	var base_dir := (_player_ref.global_position - global_position).normalized()
	var projectile_scene: PackedScene = load("res://scenes/dark_projectile.tscn")

	# Shoot 3 projectiles in a spread: -15deg, 0, +15deg
	var angles := [-deg_to_rad(15), 0.0, deg_to_rad(15)]
	for angle in angles:
		var proj := projectile_scene.instantiate()
		proj.global_position = global_position
		proj.direction = base_dir.rotated(angle)
		get_tree().current_scene.add_child(proj)

func _do_shoot(delta: float) -> void:
	velocity = Vector2.ZERO
	if _state_timer <= 0:
		_state = "cooldown"
		_state_timer = _cooldown_time

func _do_cooldown(delta: float) -> void:
	velocity = Vector2.ZERO
	if _state_timer <= 0:
		if _player_ref and is_instance_valid(_player_ref) and not _player_ref.is_dead:
			_state = "chase"
		else:
			_state = "idle"

func _on_hurt(area: Area2D) -> void:
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
	tween.tween_property(sprite, ^"modulate", Color(0.6, 0.3, 0.8), 0.2)

	if hp <= 0:
		hp = 0
		_die()

func _die() -> void:
	is_dead = true
	died.emit()
	var depth: int = 0
	var gm = _get_game_manager()
	if gm:
		depth = gm.dungeon_depth if gm.endless_mode else 2
	DropSystem.try_drop(global_position, "necromancer", depth, get_tree().current_scene)
	# Death animation
	var tween := create_tween()
	tween.tween_property(sprite, ^"modulate", Color(0.5, 0.0, 0.8, 0.3), 0.5)
	tween.tween_property(sprite, ^"scale", Vector2(3.0, 0.5), 0.3)
	tween.tween_callback(queue_free)

func _find_player() -> CharacterBody2D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as CharacterBody2D
	return null

func apply_depth_scaling(depth: int) -> void:
	max_hp = int(250 * (1.0 + depth * 0.2))
	hp = max_hp
	contact_damage = int(15 * (1.0 + depth * 0.1))
	gold_value = int(150 * (1.0 + depth * 0.15))
	speed = 60.0 + depth * 5.0

func _get_game_manager() -> Node:
	var root_children := get_tree().root.get_children()
	for node in root_children:
		if node.name == "GameManager":
			return node
	return null
