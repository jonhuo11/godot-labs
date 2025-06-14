class_name Boid

extends RigidBody2D

@export var hide_debug = true

@export var others_query_radius: int = 10

@export var sep_factor: float = 1
@export var align_factor: float = 1
@export var coh_factor: float = 1
@export var mouse_factor: float = 1
@export var max_steering_force: float = 5
@export var steering_force_factor: float = 2

@onready var debug_font = load("res://boids/boid/assets/debug.tres")

var n_other_boids = 0
var steer_dir = Vector2.ZERO

func _ready() -> void:
	$AnimatedSprite2D.play("default")
	
	linear_velocity = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(10, 50)

func _draw():
	if hide_debug:
		return

	draw_circle(Vector2.ZERO, others_query_radius, Color(1,0,0,0.1))
	draw_string(debug_font, Vector2(0, -others_query_radius), str(n_other_boids))
	

	draw_dashed_line(
		Vector2.ZERO,
		Vector2.UP * others_query_radius, # Draw a line straight "up" from the boid's perspective
		Color(0,1,0,0.5)
	)
	
	var global_steer_dir = steer_dir.normalized()
	var local_steer_dir = global_steer_dir.rotated(-rotation)
	draw_dashed_line(
		Vector2.ZERO,
		local_steer_dir * others_query_radius / 2,
		Color(0,0,1,0.5)
	)
	
func _physics_process(_delta: float) -> void:
	var others = get_others_in_radius(others_query_radius)
	n_other_boids = len(others[0])
	steer_dir = boid(others) * steering_force_factor
	apply_central_force(steer_dir)
	
	rotation = linear_velocity.angle() + deg_to_rad(90)

func _process(_delta: float) -> void:
	queue_redraw()
	
	
func boid(others) -> Vector2: # apply the boid update rules
	var sep = separation(others)
	var align = alignment(others)
	var coh = cohesion(others)
	var mf = mouse_follow()
	var move_towards = (sep * sep_factor) + (align * align_factor) + (coh * coh_factor) + (mf * mouse_factor)
	return move_towards.limit_length(max_steering_force)


func mouse_follow() -> Vector2:
	var dist = get_global_mouse_position() - global_position
	return (dist).normalized() * dist.length_squared()


func separation(others: Array) -> Vector2:
	var other_boids = others[0]
	if len(other_boids) < 1:
		return Vector2.ZERO
	
	var out = Vector2.ZERO
	for oboid: Boid in other_boids:
		var vec_away = global_position - oboid.global_position
		var dist_sq = vec_away.length_squared()
		
		# Add a check to prevent division by zero and extreme forces at close range
		if dist_sq > 0:
			# Scale the repulsive force inversely to the distance
			out += vec_away.normalized() / dist_sq
		
	if len(other_boids) > 0:
		out /= len(other_boids)
		
	return out


func cohesion(others: Array) -> Vector2: # average position
	var other_boids = others[0]
	if len(other_boids) < 1:
		return Vector2.ZERO
	
	var com = Vector2.ZERO
	for oboid: Boid in other_boids:
		com += oboid.global_position
	
	if len(other_boids) > 0:
		com /= len(other_boids)
	
	var dist = com - global_position
	return dist.normalized() * dist.length_squared()
	

func alignment(others: Array) -> Vector2: # average heading
	var other_boids = others[0]
	if len(other_boids) < 1:
		return Vector2.ZERO
		
	var out = Vector2.ZERO
	
	for oboid: Boid in other_boids:
		var heading_dir = oboid.linear_velocity.normalized()
		out += heading_dir
	return out / len(other_boids)


func get_others_in_radius(radius: int) -> Array:
	var space_state = get_world_2d().direct_space_state
	
	var circle = CircleShape2D.new()
	circle.radius = radius
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0, global_position)
	
	var hits = space_state.intersect_shape(query, 32)
	var boid_hits = []
	var nonboid_hits = []
	for hit in hits:
		if hit.collider != self:
			if hit.collider is Boid:
				boid_hits.append(hit.collider)
			else:
				nonboid_hits.append(hit.collider)
	return [boid_hits, nonboid_hits]
