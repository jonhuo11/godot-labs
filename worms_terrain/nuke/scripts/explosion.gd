extends AnimatedSprite2D

func _ready() -> void:
	play("default")
	connect("animation_finished", self._on_anim_done)

func _on_anim_done() -> void:
	queue_free()  # Clean up when done
