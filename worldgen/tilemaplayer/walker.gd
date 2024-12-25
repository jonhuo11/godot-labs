extends CharacterBody2D

@export var speed: float = 1600

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("mouse_click"):
		nav_agent.target_position = get_global_mouse_position()
	
	if nav_agent.is_navigation_finished():
		return
	
	var move_vec = position.direction_to(nav_agent.get_next_path_position()).normalized() * delta * speed
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(move_vec)
	velocity = move_vec
	move_and_slide()
