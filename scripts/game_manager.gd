extends Node
## res://scripts/game_manager.gd

signal room_changed(room_index: int)
signal game_over(won: bool)

var current_room: int = 0
var gold: int = 0
var enemies_alive: int = 0

func _ready() -> void:
	pass

func _on_enemy_died(enemy: CharacterBody2D) -> void:
	pass

func _on_boss_died() -> void:
	pass
