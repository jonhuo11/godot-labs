extends Node2D

class_name Battleship

class ShipNode extends Node2D:
	var sprite2d: Sprite2D


class ShipTurret extends ShipNode:
	class TurretArea extends Area2D:
		var _shape: CollisionShape2D
		var _turret: ShipTurret
		var _target_queue: Array[Node2D] = []
		var _targets_in_area: Dictionary = {}
		
		func _init(__turret: ShipTurret, radius: float):
			_shape = CollisionShape2D.new()
			_shape.shape = CircleShape2D.new()
			_shape.shape.radius = radius
			add_child(_shape)
			
			_turret = __turret
			_turret.add_child(self)
		
		
		func _ready() -> void:
			area_entered.connect(self._on_area_entered)
			area_exited.connect(self._on_area_exited)
			
			
		func _on_area_entered(other: Area2D) -> void:
			_targets_in_area[other.get_instance_id()] = 0
			if _turret.target:
				_target_queue.push_back(other)
				return
			_turret.target = other
			print("Target set!")
			
		
		func _on_area_exited(other: Area2D) -> void:
			_targets_in_area.erase(other.get_instance_id())
			if other == _turret.target:
				_turret.target = null
				print("Target removed")
				
				# pick next target
				while len(_target_queue) > 0:
					var next: Node2D = _target_queue.pop_front()
					if next.get_instance_id() in _targets_in_area:
						_turret.target = next
						break
			
	
	var _ship_body_part: ShipBodyPart
	var _resource: BattleshipTurret
	var _area: TurretArea
	var target: Node2D
	
	func _init(__ship_body_part: ShipBodyPart, __resource: BattleshipTurret):
		_ship_body_part = __ship_body_part
		_resource = __resource
		
		sprite2d = Battleship.make_sprite(_resource.turret_texture, self)
		_area = TurretArea.new(self, _resource.detection_range)
		
		
	func _process(delta: float) -> void:
		# check for enemies in the area
		if not target:
			return
		
		# use the resource controller to control the turret rotation
		var ship_node = _get_ship_node()
		var desired_angle = _resource.controller.control(ship_node.position, ship_node.current_speed, get_global_mouse_position(), Vector2.ZERO)
		rotation = desired_angle
		
		
	func _get_ship_node() -> Battleship:
		return _ship_body_part.get_ship_node()
	

class ShipBodyPart extends ShipNode:
	var _battleship: Battleship
	var turret: ShipTurret = null
	
	func _init(__battleship: Battleship, _sprite2d: Sprite2D, _turret_resource: BattleshipTurret = null):
		sprite2d = _sprite2d
		add_child(sprite2d)
		
		if _turret_resource:
			turret = ShipTurret.new(self, _turret_resource)
			add_child(turret)
		
		_battleship = __battleship
		_battleship.add_child(self)
	
	func get_ship_node() -> Battleship:
		return _battleship


@export var turrets: Array[BattleshipTurret] = []
@export var body_texture: AtlasTexture = AtlasTexture.new()
@export var front_texture: AtlasTexture = AtlasTexture.new()
@export var back_texture: AtlasTexture = AtlasTexture.new()
@export var speed: float = 1
@export var rotation_speed: float = 0.1

const BODY_PART_PIXEL_SIZE: int = 8

var ship_body_parts: Array[ShipBodyPart] = []
var current_speed: float = 0
var current_rotation_speed: float = 0


static func cap(val: float, abs_max: float) -> float:
	if val < 0:
		return max(-abs(abs_max), val)
	elif val > 0:
		return min(abs(abs_max), val)
	else:
		return 0


static func make_sprite(texture: Texture2D, parent: Node = null) -> Sprite2D:
	var new_sprite = Sprite2D.new()
	new_sprite.texture = texture
	if parent:
		parent.add_child(new_sprite)
	return new_sprite
	

# generate the nodes for the ship body
func construct_ship() -> void:
	# construct main turret parts
	for i in range(len(turrets)):
		var turret_part = ShipBodyPart.new(
			self,
			make_sprite(body_texture),
			turrets[i]
		)
		ship_body_parts.append(turret_part)
	
	# construct front and back
	ship_body_parts.push_front(ShipBodyPart.new(self, make_sprite(front_texture)))
	ship_body_parts.push_back(ShipBodyPart.new(self, make_sprite(back_texture)))
	
	# spread the ship parts out and center it
	var ship_len_pixels = len(ship_body_parts) * BODY_PART_PIXEL_SIZE
	for i in range(len(ship_body_parts)):
		var part = ship_body_parts[i]
		var center_y = ((0.5 * BODY_PART_PIXEL_SIZE) + BODY_PART_PIXEL_SIZE * i) - ship_len_pixels/2
		part.position.y = center_y


func movement(delta: float) -> void:
	var rotation_direction = 0
	if Input.is_key_pressed(KEY_A):
		rotation_direction += -1
	if Input.is_key_pressed(KEY_D):
		rotation_direction += 1
	current_rotation_speed = rotation_direction * rotation_speed * delta
	current_speed = speed * delta * -1
	position += Vector2(0, current_speed).rotated(rotation)
	rotation += current_rotation_speed
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if len(turrets) < 1:
		push_error("Not enough turrets on battleship")
		get_tree().quit()
	
	for texture in [body_texture, front_texture, back_texture]:
		if texture.region.size.x != texture.region.size.y and texture.region.size.x != BODY_PART_PIXEL_SIZE:
			push_error("Invalid battleship part pixel size, expected ", BODY_PART_PIXEL_SIZE)
			get_tree().quit()
	
	construct_ship()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	movement(delta)
