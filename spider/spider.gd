class_name Spider

extends Node2D

@export var draw_debug = false

@export var max_allowed_dist_from_rel_desired_foot_pos: float = 30
@export var random_new_target_max_radius: float = 10
@export var random_allowed_dist_delta: float = 20
@export var lerp_weight: float = 0.1
@export var move_spd: float = 10

@export var top_left_leg: Leg
@export var mid_left_leg: Leg
@export var back_left_leg: Leg
@export var top_right_leg: Leg
@export var mid_right_leg: Leg
@export var back_right_leg: Leg
@export var hind_left_leg: Leg
@export var hind_right_leg: Leg

@onready var legs: Array[Leg] = [
	top_left_leg,
	mid_left_leg,
	back_left_leg,
	top_right_leg,
	mid_right_leg,
	back_right_leg,
	hind_left_leg,
	hind_right_leg
]

@onready var leg_groups: Array[Array]= [
	[top_left_leg, back_right_leg],
	[mid_left_leg, hind_right_leg],
	[back_left_leg, top_right_leg],
	[mid_right_leg, hind_left_leg]
]

func _ready() -> void:
	_setup_legs()


func _draw() -> void:
	if !draw_debug:
		return
	for leg in legs:
		draw_circle(leg._target_foot_pos - global_position, 10, Color.AQUA)
		draw_circle(leg.REL_DESIRED_FOOT_POS, 10, Color.SEA_GREEN)

		# the threshold
		draw_circle(leg.REL_DESIRED_FOOT_POS, max_allowed_dist_from_rel_desired_foot_pos, Color.RED, 0.1)


func _process(delta: float) -> void:
	queue_redraw()

	if Input.is_key_pressed(KEY_W):
		position.y -= move_spd * delta
	if Input.is_key_pressed(KEY_S):
		position.y += move_spd * delta

	_update_legs()


func _update_legs() -> void:
	for group in leg_groups:
		for leg: Leg in group:
			if leg.needs_to_move_target():
				for leg1: Leg in group:
					leg1.update_target()
				break


func _setup_legs() -> void:
	for leg: Leg in legs:
		leg.setup(self)
