extends CharacterBody2D
## res://scripts/boss_controller.gd — Boss with menacing idle

signal died

@export var speed: float = 100.0
@export var max_hp: int = 300
@export var contact_damage: int = 20
@export var slam_damage: int = 40
@export var gold_value: int = 100

@onready var sprite: Sprite2D = $Sprite2D

var hp: int = 300

func _ready() -> void:
	hp = max_hp
	# Menacing bob (slower, larger)
	var tween := create_tween()
	tween.set_loops(0)
	tween.tween_property(sprite, ^"position:y", -3.0, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, ^"position:y", 3.0, 0.8).set_trans(Tween.TRANS_SINE)

	# Connect hurtbox
	$HurtBox.area_entered.connect(_on_hurt)

func _physics_process(delta: float) -> void:
	# Idle — facing player direction will be added in task 2
	pass

func _on_hurt(area: Area2D) -> void:
	pass

func take_damage(amount: int) -> void:
	hp -= amount
	# Flash red
	var tween := create_tween()
	tween.tween_property(sprite, ^"modulate", Color(1.5, 0.3, 0.3), 0.05)
	tween.tween_property(sprite, ^"modulate", Color.WHITE, 0.2)

	if hp <= 0:
		hp = 0
		died.emit()
		queue_free()
