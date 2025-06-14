extends Node2D

@export var boid_scene: PackedScene
@export var n_boids = 10
@export var spawn_radius = 750

func _ready() -> void:
	for _i in range(n_boids):
		var boid = boid_scene.instantiate()
		var x = randf_range(-spawn_radius, spawn_radius)
		var y = randf_range(-spawn_radius, spawn_radius)
		boid.position = Vector2(x, y)
		add_child(boid)
