extends Node

static func set_enabled_rbody(rbody: RigidBody2D, state: bool) -> void:
	if rbody == null:
		return
	
	rbody.visible = state
	rbody.sleeping = !state
	rbody.freeze = !state


	for child in rbody.get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			child.visible = state
		elif child is CollisionShape2D:
			child.disabled = !state
