extends Area2D
## res://scripts/dark_projectile.gd — Dark projectile fired by the necromancer boss

var direction: Vector2 = Vector2.RIGHT
var speed: float = 250.0
var damage: int = 20
var lifetime: float = 3.0
var _timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position += direction * speed * delta
	_timer += delta
	if _timer >= lifetime:
		queue_free()

	# Rotate to face direction
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
		return
	if body is StaticBody2D:
		queue_free()
