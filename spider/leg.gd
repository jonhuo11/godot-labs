class_name Leg

extends Node2D

@onready var _foot: Node2D = $foot

var REL_DESIRED_FOOT_POS: Vector2 = Vector2.ZERO # a const
var _target_foot_pos: Vector2 = Vector2.ZERO # global location
var _spider: Spider = null

func setup(s: Spider) -> void:
	_spider = s

	REL_DESIRED_FOOT_POS = _foot.global_position - _spider.global_position
	_target_foot_pos = _foot.global_position



func _process(_delta: float) -> void:
	if _spider == null:
		return

	# rotate towards the real desired _foot pos
	var target_rot = global_position.angle_to_point(_target_foot_pos) + deg_to_rad(90)
	global_rotation = lerp_angle(global_rotation, target_rot, _spider.lerp_weight)


func needs_to_move_target() -> bool: # check if the _foot is too far from the rel desired _foot pos
	var dist_to_desired = _global_desired_foot_pos().distance_to(_foot.global_position)
	return dist_to_desired > _spider.max_allowed_dist_from_rel_desired_foot_pos + randf_range(-_spider.random_allowed_dist_delta, _spider.random_allowed_dist_delta)


func _global_desired_foot_pos() -> Vector2:
	if _spider == null:
		push_error("Null _spider")
		return Vector2.ZERO
	return REL_DESIRED_FOOT_POS + _spider.global_position


func update_target() -> void:
	if _spider == null:
		push_error("Null _spider")
		return
	_target_foot_pos = _spider.global_position + REL_DESIRED_FOOT_POS + Vector2(
		randf_range(-_spider.random_new_target_max_radius, _spider.random_new_target_max_radius), 
		randf_range(-_spider.random_new_target_max_radius, _spider.random_new_target_max_radius)
	)
