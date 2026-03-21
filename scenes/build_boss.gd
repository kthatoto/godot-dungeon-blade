extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_boss.gd

func _initialize() -> void:
	var root := CharacterBody2D.new()
	root.name = "Boss"
	root.set_script(load("res://scripts/boss_controller.gd"))
	root.collision_layer = 2  # enemies
	root.collision_mask = 1 | 4  # player, walls

	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	root.add_child(sprite)

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := CapsuleShape2D.new()
	shape.radius = 20.0
	shape.height = 48.0
	collision.shape = shape
	root.add_child(collision)

	var hurtbox := Area2D.new()
	hurtbox.name = "HurtBox"
	hurtbox.collision_layer = 2
	hurtbox.collision_mask = 8  # player_attack
	hurtbox.monitoring = true
	root.add_child(hurtbox)

	var hurt_shape := CollisionShape2D.new()
	hurt_shape.name = "CollisionShape2D"
	var hurt_rect := RectangleShape2D.new()
	hurt_rect.size = Vector2(40, 48)
	hurt_shape.shape = hurt_rect
	hurtbox.add_child(hurt_shape)

	var attack_area := Area2D.new()
	attack_area.name = "AttackArea"
	attack_area.collision_layer = 16  # enemy_attack
	attack_area.collision_mask = 1    # player
	attack_area.monitoring = true
	root.add_child(attack_area)

	var attack_shape := CollisionShape2D.new()
	attack_shape.name = "CollisionShape2D"
	var atk_circle := CircleShape2D.new()
	atk_circle.radius = 60.0
	attack_shape.shape = atk_circle
	attack_shape.disabled = true
	attack_area.add_child(attack_shape)

	var anim := AnimationPlayer.new()
	anim.name = "AnimationPlayer"
	root.add_child(anim)

	_set_owners(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/boss.tscn")
	print("Saved: res://scenes/boss.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
