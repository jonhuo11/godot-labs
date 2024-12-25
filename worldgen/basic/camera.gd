extends Camera2D

@export var speed: float = 1

func dir_ceil(value: float) -> float:
	if value < 0:
		return floor(value)
	elif value > 0:
		return ceil(value)
	return 0

func dir_ceil_vec(value: Vector2) -> Vector2:
	return Vector2(dir_ceil(value.x), dir_ceil(value.y))
	

func _process(delta):
	var movement = Vector2.ZERO
	# Check for arrow key inputs
	if Input.is_action_pressed("ui_left"):
		movement.x -= 1
	if Input.is_action_pressed("ui_right"):
		movement.x += 1
	if Input.is_action_pressed("ui_up"):
		movement.y -= 1
	if Input.is_action_pressed("ui_down"):
		movement.y += 1
	if movement == Vector2.ZERO: return
		
	# Normalize the movement to prevent diagonal faster movement
	movement = movement.normalized() * speed * delta
	# Move the camera and snap it to an int
	position += dir_ceil_vec(movement)
	position.x = round(position.x)
	position.y = round(position.y)
