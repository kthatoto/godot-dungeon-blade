extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_player.gd

func _initialize() -> void:
	var root := CharacterBody2D.new()
	root.name = "Player"
	root.set_script(load("res://scripts/player_controller.gd"))
	root.collision_layer = 1  # player
	root.collision_mask = 2 | 4  # enemies, walls

	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	root.add_child(sprite)

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := CapsuleShape2D.new()
	shape.radius = 12.0
	shape.height = 32.0
	collision.shape = shape
	root.add_child(collision)

	var sword_hitbox := Area2D.new()
	sword_hitbox.name = "SwordHitbox"
	sword_hitbox.collision_layer = 8  # player_attack (layer 4)
	sword_hitbox.collision_mask = 2   # enemies
	sword_hitbox.monitoring = true
	root.add_child(sword_hitbox)

	var sword_shape := CollisionShape2D.new()
	sword_shape.name = "CollisionShape2D"
	var sword_rect := RectangleShape2D.new()
	sword_rect.size = Vector2(40, 20)
	sword_shape.shape = sword_rect
	sword_shape.position = Vector2(30, 0)
	sword_shape.disabled = true
	sword_hitbox.add_child(sword_shape)

	var anim := AnimationPlayer.new()
	anim.name = "AnimationPlayer"
	root.add_child(anim)

	_set_owners(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/player.tscn")
	print("Saved: res://scenes/player.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
