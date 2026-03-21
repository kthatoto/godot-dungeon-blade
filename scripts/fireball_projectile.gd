extends Area2D
## res://scripts/fireball_projectile.gd — Fireball projectile that damages enemies

var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0
var damage: int = 50
var lifetime: float = 2.0
var _timer: float = 0.0

func _ready() -> void:
	# Connect signals for hitting enemies or walls
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	position += direction * speed * delta
	_timer += delta
	if _timer >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	# Hit wall
	if body is StaticBody2D:
		_explode()
		return

func _on_area_entered(area: Area2D) -> void:
	# Hit enemy hurtbox
	var parent := area.get_parent()
	if parent and parent.is_in_group("enemies") and parent.has_method("take_damage"):
		parent.take_damage(damage)
		_explode()

func _explode() -> void:
	# Quick flash and disappear
	var sprite := get_node_or_null("Sprite")
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, ^"scale", Vector2(3, 3), 0.1)
		tween.parallel().tween_property(sprite, ^"modulate", Color(1, 1, 1, 0), 0.1)
		tween.tween_callback(queue_free)
	else:
		queue_free()
