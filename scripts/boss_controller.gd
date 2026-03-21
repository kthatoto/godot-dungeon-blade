extends CharacterBody2D
## res://scripts/boss_controller.gd

signal died

@export var speed: float = 100.0
@export var max_hp: int = 300
@export var contact_damage: int = 20
@export var slam_damage: int = 40
@export var gold_value: int = 100

var hp: int = max_hp

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func _on_hurt(area: Area2D) -> void:
	pass
