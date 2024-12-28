extends GDScript

class_name BattleshipTurretController

func control(my_pos: Vector2, my_vel: Vector2, enemy_pos: Vector2, enemy_vel: Vector2) -> float:
	# TODO: account for velocities
	var desired_angle = (enemy_pos - my_pos).angle()
	return desired_angle + PI/2
	
