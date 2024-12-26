extends Resource

class_name BattleshipTurret

@export var detection_range: float = 32
@export var damage_on_hit: float = 1
@export var rotation_speed: float = 1
@export var controller: BattleshipTurretController = BattleshipTurretController.new()
@export var turret_texture: AtlasTexture = null
