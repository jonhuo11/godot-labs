extends Node

@export var width: int = 64
@export var height: int = 64
@export var noise_threshold: float = 0

@onready var tile_map_layer: TileMapLayer = $TileMapLayer

var noise: FastNoiseLite = FastNoiseLite.new()


const TILESET_SOURCE_ID: int = 0
const LAND_TILE_ATLAS_POS: Vector2i = Vector2i(0, 5)
const WATER_TILE_ATLAS_POS: Vector2i = Vector2i(0, 7)


func generate() -> void:
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = Time.get_unix_time_from_system()
	
	for y in range(width):
		for x in range(height):
			var noise_value: float = noise.get_noise_2d(x, y)
			var atlas_tile_posn = WATER_TILE_ATLAS_POS # default tile type
			if noise_value >= noise_threshold:
				atlas_tile_posn = LAND_TILE_ATLAS_POS
			
			tile_map_layer.set_cell(Vector2i(x, y), TILESET_SOURCE_ID, atlas_tile_posn)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_SPACE):
		generate()
