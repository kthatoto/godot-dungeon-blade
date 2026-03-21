extends CharacterBody2D
## res://scripts/player_controller.gd

signal died
signal attacked

@export var speed: float = 200.0
@export var max_hp: int = 100
@export var attack_damage: int = 25

var hp: int = max_hp
var facing: Vector2 = Vector2.DOWN
var is_attacking: bool = false

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func _on_sword_hit(area: Area2D) -> void:
	pass
