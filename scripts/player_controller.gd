extends CharacterBody2D
## res://scripts/player_controller.gd — Player movement, facing, and attack visuals

signal died
signal attacked

@export var speed: float = 200.0
@export var max_hp: int = 100
@export var attack_damage: int = 25

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sword_hitbox: Area2D = $SwordHitbox

var hp: int = 100
var facing: Vector2 = Vector2.DOWN
var is_attacking: bool = false
var _attack_timer: float = 0.0

func _ready() -> void:
	hp = max_hp
	# Bobbing idle animation via tween
	_start_idle_bob()

func _start_idle_bob() -> void:
	var tween := create_tween()
	tween.set_loops(0)  # infinite
	tween.tween_property(sprite, ^"position:y", -2.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, ^"position:y", 2.0, 0.6).set_trans(Tween.TRANS_SINE)

func _physics_process(delta: float) -> void:
	# Movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed

	if input_dir.length() > 0.1:
		facing = input_dir.normalized()
		# Flip sprite based on horizontal direction
		if facing.x < -0.1:
			sprite.flip_h = true
		elif facing.x > 0.1:
			sprite.flip_h = false

	move_and_slide()

	# Attack
	if _attack_timer > 0:
		_attack_timer -= delta
		if _attack_timer <= 0:
			is_attacking = false
			$SwordHitbox/CollisionShape2D.disabled = true

	if Input.is_action_just_pressed("attack") and not is_attacking:
		_do_attack()

func _do_attack() -> void:
	is_attacking = true
	_attack_timer = 0.3
	$SwordHitbox/CollisionShape2D.disabled = false
	attacked.emit()

	# Visual feedback: quick rotation
	var tween := create_tween()
	tween.tween_property(sprite, ^"rotation", deg_to_rad(-15.0), 0.08)
	tween.tween_property(sprite, ^"rotation", 0.0, 0.15)

	# Position sword hitbox based on facing
	var sword_offset := facing * 30.0
	$SwordHitbox/CollisionShape2D.position = sword_offset

func _on_sword_hit(area: Area2D) -> void:
	pass

func take_damage(amount: int) -> void:
	hp -= amount
	# Flash red
	var tween := create_tween()
	tween.tween_property(sprite, ^"modulate", Color(1.0, 0.3, 0.3), 0.05)
	tween.tween_property(sprite, ^"modulate", Color.WHITE, 0.15)

	if hp <= 0:
		hp = 0
		died.emit()
