extends Node

const e = 2.71828

@onready var raycast: RayCast3D = $Gun/ShootPoint

@export var max_spread_angle_deg: float = 30.0
@export var base_spread_angle_deg: float = 1
@export var bullet_index_cooldown_time_sec: float = 0.1
@export var min_sec_between_shots: float = 0.1
@export var bullets_per_mag: int = 10

var bullet_index: int = 0
var sec_since_last_shot: float = INF


func spread(bullet_i: int) -> float:
	return pow(0.5 * e, bullet_i - 4)
	

func randf_between(min_value: float, max_value: float) -> float:
	return lerp(min_value, max_value, randf())


func shot_deg() -> float:
	var clamped_spread_deg = min(spread(bullet_index) * base_spread_angle_deg, max_spread_angle_deg)
	print(clamped_spread_deg)
	var min_deg = -clamped_spread_deg / 2
	var max_deg = clamped_spread_deg / 2
	var shot_deg_out = randf_between(min_deg, max_deg)
	return shot_deg_out


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# print(sec_since_last_shot)
	if Input.is_action_pressed("left_click"):
		if sec_since_last_shot < min_sec_between_shots:
			sec_since_last_shot += delta
			return
		
		# fire a shot
		sec_since_last_shot = 0
		bullet_index = max(bullets_per_mag - 1, bullet_index + 1)
		shoot(shot_deg())
	else:
		# not shooting
		sec_since_last_shot += delta
		if sec_since_last_shot > bullet_index_cooldown_time_sec:
			bullet_index = max(0, bullet_index - 1)
			raycast.rotation.y = deg_to_rad(shot_deg())


func shoot(shot_angle_deg: float) -> void:
	var shot_angle_rad = deg_to_rad(shot_angle_deg)
	raycast.rotation.y = shot_angle_rad
	var shot_pos = MeshInstance3D.new()
	shot_pos.mesh = SphereMesh.new()
	shot_pos.transform.scaled(Vector3(0.1, 0.1, 0.1))
	shot_pos.position = raycast.target_position
	raycast.add_child(shot_pos)
