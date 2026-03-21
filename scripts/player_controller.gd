extends CharacterBody2D
## res://scripts/player_controller.gd — Player movement, combat, HP, death

signal died
signal attacked

@export var speed: float = 200.0
@export var max_hp: int = 100
@export var attack_damage: int = 25
@export var knockback_force: float = 150.0
@export var invincibility_time: float = 0.5
@export var regen_rate: float = 5.0  # HP per second when idle
@export var regen_delay: float = 3.0  # seconds of no damage before regen starts

@onready var sprite: Sprite2D = $Sprite2D
@onready var sword_hitbox: Area2D = $SwordHitbox

var hp: int = 100
var facing: Vector2 = Vector2.DOWN
var is_attacking: bool = false
var is_dead: bool = false
var _attack_timer: float = 0.0
var _invincible_timer: float = 0.0
var _damage_cooldown: float = 0.0
var _regen_timer: float = 0.0
var _regen_accumulator: float = 0.0
var _dash_speed: float = 0.0
var _dash_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO

func _ready() -> void:
	_apply_upgrades()
	hp = max_hp
	add_to_group("player")
	# Bobbing idle animation via tween
	_start_idle_bob()
	# Connect sword hitbox
	sword_hitbox.area_entered.connect(_on_sword_hit)
	# Register with GameManager
	var gm = _get_game_manager()
	if gm:
		gm.player_ref = self
	# Add Camera2D at runtime (not saved in scene due to instantiation ownership)
	if not get_node_or_null("Camera2D"):
		var camera := Camera2D.new()
		camera.name = "Camera2D"
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 8.0
		add_child(camera)
	# Add SkillSystem
	var skill_sys := Node.new()
	skill_sys.name = "SkillSystem"
	skill_sys.set_script(load("res://scripts/skill_system.gd"))
	add_child(skill_sys)

func _start_idle_bob() -> void:
	var tween := create_tween()
	tween.set_loops(0)  # infinite
	tween.tween_property(sprite, ^"position:y", -2.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, ^"position:y", 2.0, 0.6).set_trans(Tween.TRANS_SINE)

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Invincibility timer
	if _invincible_timer > 0:
		_invincible_timer -= delta
		# Flicker effect
		sprite.modulate.a = 0.5 if fmod(_invincible_timer, 0.15) < 0.075 else 1.0
		if _invincible_timer <= 0:
			sprite.modulate = Color.WHITE

	# Damage cooldown
	if _damage_cooldown > 0:
		_damage_cooldown -= delta

	# Dash movement override
	if _dash_timer > 0:
		_dash_timer -= delta
		velocity = _dash_dir * _dash_speed
		move_and_slide()
		if _dash_timer <= 0:
			sprite.modulate = Color.WHITE
		return

	# Movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not is_attacking:
		velocity = input_dir * speed
	else:
		velocity = velocity * 0.9  # slow down during attack

	if input_dir.length() > 0.1:
		facing = input_dir.normalized()
		# Flip sprite based on horizontal direction
		if facing.x < -0.1:
			sprite.flip_h = true
		elif facing.x > 0.1:
			sprite.flip_h = false

	move_and_slide()

	# Check for contact damage from enemies
	_check_contact_damage()

	# Attack
	if _attack_timer > 0:
		_attack_timer -= delta
		if _attack_timer <= 0:
			is_attacking = false
			$SwordHitbox/CollisionShape2D.disabled = true

	if Input.is_action_just_pressed("attack") and not is_attacking:
		_do_attack()

	# HP regen when idle (not moving, not attacking)
	if input_dir.length() < 0.1 and not is_attacking and hp < max_hp and hp > 0:
		_regen_timer += delta
		if _regen_timer >= regen_delay:
			_regen_accumulator += regen_rate * delta
			if _regen_accumulator >= 1.0:
				var heal := int(_regen_accumulator)
				hp = mini(hp + heal, max_hp)
				_regen_accumulator -= heal
	else:
		_regen_timer = 0.0
		_regen_accumulator = 0.0

func _do_attack() -> void:
	is_attacking = true
	_attack_timer = 0.3
	$SwordHitbox/CollisionShape2D.disabled = false
	attacked.emit()

	# Visual feedback: quick rotation
	var tween := create_tween()
	tween.tween_property(sprite, ^"rotation", deg_to_rad(-15.0), 0.08)
	tween.tween_property(sprite, ^"rotation", 0.0, 0.15)

	# Position sword hitbox based on facing (wider range)
	var sword_offset := facing * 40.0
	$SwordHitbox/CollisionShape2D.position = sword_offset

	# Slash visual effect
	_spawn_slash_effect(sword_offset)

func _on_sword_hit(area: Area2D) -> void:
	# Hit enemy or boss hurtbox
	var parent := area.get_parent()
	if parent and parent.has_method("take_damage"):
		parent.take_damage(attack_damage)
		# Knockback
		if parent is CharacterBody2D:
			var body := parent as CharacterBody2D
			var kb_dir: Vector2 = (body.global_position - global_position).normalized()
			body.velocity = kb_dir * knockback_force

func _check_contact_damage() -> void:
	if _invincible_timer > 0 or is_dead:
		return
	# Check collision with enemies via slide collisions
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider is CharacterBody2D and collider.is_in_group("enemies"):
			var enemy_body := collider as CharacterBody2D
			var dmg: int = 10
			if "contact_damage" in enemy_body:
				dmg = enemy_body.contact_damage
			take_damage(dmg)
			# Push player back
			var push_dir: Vector2 = (global_position - enemy_body.global_position).normalized()
			velocity = push_dir * 120.0
			break

func take_damage(amount: int) -> void:
	if _invincible_timer > 0 or is_dead:
		return
	hp -= amount
	_invincible_timer = invincibility_time
	_regen_timer = 0.0
	_regen_accumulator = 0.0
	# Flash red
	var tween := create_tween()
	tween.tween_property(sprite, ^"modulate", Color(1.0, 0.3, 0.3), 0.05)
	tween.tween_property(sprite, ^"modulate", Color.WHITE, 0.15)

	if hp <= 0:
		hp = 0
		_die()

func _die() -> void:
	is_dead = true
	died.emit()
	# Death visual
	var tween := create_tween()
	tween.tween_property(sprite, ^"modulate", Color(0.5, 0.0, 0.0, 0.5), 0.5)
	tween.tween_property(sprite, ^"scale", Vector2(2.5, 0.5), 0.3)
	# Notify game manager
	var gm = _get_game_manager()
	if gm:
		gm.player_died()

func _spawn_slash_effect(offset: Vector2) -> void:
	var slash := Node2D.new()
	slash.name = "SlashFX"
	slash.position = offset
	slash.rotation = atan2(facing.y, facing.x)
	add_child(slash)

	# Arc shape using multiple small rects
	for i in range(5):
		var arc := ColorRect.new()
		var angle_offset: float = deg_to_rad(-40 + i * 20)
		arc.size = Vector2(24, 3)
		arc.position = Vector2(cos(angle_offset) * 20, sin(angle_offset) * 20)
		arc.rotation = angle_offset
		arc.color = Color(1.0, 0.95, 0.7, 0.9)
		slash.add_child(arc)

	# Animate: scale up and fade
	var slash_tween := create_tween()
	slash_tween.tween_property(slash, ^"scale", Vector2(1.5, 1.5), 0.1)
	slash_tween.parallel().tween_property(slash, ^"modulate", Color(1, 1, 1, 0), 0.15)
	slash_tween.tween_callback(slash.queue_free)

## --- Skill actions ---

func perform_dash() -> void:
	if is_dead:
		return
	_dash_dir = facing if facing.length() > 0.1 else Vector2.DOWN
	_dash_speed = 600.0
	_dash_timer = 0.15
	_invincible_timer = 0.2  # brief invincibility during dash
	# Visual: blue-white flash
	sprite.modulate = Color(0.5, 0.7, 1.0, 0.7)

func perform_fireball() -> void:
	if is_dead:
		return
	var fireball_scene := load("res://scenes/fireball.tscn") as PackedScene
	if fireball_scene == null:
		return
	var fireball := fireball_scene.instantiate()
	fireball.global_position = global_position + facing * 30.0
	fireball.direction = facing if facing.length() > 0.1 else Vector2.DOWN
	fireball.damage = attack_damage * 2
	get_tree().current_scene.add_child(fireball)

func perform_heal() -> void:
	if is_dead:
		return
	var heal_amount := int(max_hp * 0.3)
	hp = mini(hp + heal_amount, max_hp)
	# Visual: green flash
	var tween := create_tween()
	tween.tween_property(sprite, ^"modulate", Color(0.3, 1.0, 0.3), 0.1)
	tween.tween_property(sprite, ^"modulate", Color.WHITE, 0.3)
	# Scale pulse
	var tween2 := create_tween()
	tween2.tween_property(sprite, ^"scale", Vector2(2.3, 2.3), 0.1)
	tween2.tween_property(sprite, ^"scale", Vector2(2.0, 2.0), 0.2)

func _apply_upgrades() -> void:
	var sm_node := _get_autoload("SaveManager")
	if sm_node == null:
		return
	max_hp = 100 + sm_node.get_upgrade_level("max_hp") * 20
	attack_damage = 25 + sm_node.get_upgrade_level("attack_damage") * 5
	speed = 200.0 + sm_node.get_upgrade_level("speed") * 20.0
	regen_rate = 5.0 + sm_node.get_upgrade_level("regen_rate") * 2.0

func _get_game_manager() -> Node:
	return _get_autoload("GameManager")

func _get_autoload(autoload_name: String) -> Node:
	var root_children := get_tree().root.get_children()
	for node in root_children:
		if node.name == autoload_name:
			return node
	return null
