extends CharacterBody2D
## res://scripts/enemy_controller.gd — Skeleton enemy with patrol and chase

signal died(enemy: CharacterBody2D)

@export var speed: float = 80.0
@export var max_hp: int = 50
@export var contact_damage: int = 10
@export var chase_range: float = 200.0
@export var gold_value: int = 10

@onready var sprite: Sprite2D = $Sprite2D

var hp: int = 50
var _patrol_dir: Vector2 = Vector2.RIGHT
var _patrol_timer: float = 0.0

func _ready() -> void:
	hp = max_hp
	_patrol_timer = randf_range(1.0, 3.0)
	# Idle bob
	var tween := create_tween()
	tween.set_loops(0)
	tween.tween_property(sprite, ^"position:y", -1.5, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, ^"position:y", 1.5, 0.5).set_trans(Tween.TRANS_SINE)

	# Connect hurtbox
	$HurtBox.area_entered.connect(_on_hurt)

func _physics_process(delta: float) -> void:
	# Simple patrol: walk in direction, reverse when timer hits
	_patrol_timer -= delta
	if _patrol_timer <= 0:
		_patrol_dir = -_patrol_dir
		_patrol_timer = randf_range(2.0, 4.0)

	velocity = _patrol_dir * speed * 0.3
	# Flip sprite
	if _patrol_dir.x < 0:
		sprite.flip_h = true
	elif _patrol_dir.x > 0:
		sprite.flip_h = false

	move_and_slide()

func _on_hurt(area: Area2D) -> void:
	pass

func take_damage(amount: int) -> void:
	hp -= amount
	# Flash white
	var tween := create_tween()
	tween.tween_property(sprite, ^"modulate", Color(2.0, 2.0, 2.0), 0.05)
	tween.tween_property(sprite, ^"modulate", Color.WHITE, 0.15)

	if hp <= 0:
		hp = 0
		died.emit(self)
		queue_free()
