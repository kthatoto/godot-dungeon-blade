extends CharacterBody2D
## res://scripts/enemy_controller.gd

signal died(enemy: CharacterBody2D)

@export var speed: float = 80.0
@export var max_hp: int = 50
@export var contact_damage: int = 10
@export var chase_range: float = 200.0
@export var gold_value: int = 10

var hp: int = max_hp

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func _on_hurt(area: Area2D) -> void:
	pass
