extends Node

@export var width: int = 256
@export var height: int = 256
@export var tile_size_pixels: int = 16
@export var noise_threshold: float = 0
@export var tile_sprite: AtlasTexture

var noise: FastNoiseLite = FastNoiseLite.new()

func spawn_tile_at(position: Vector2) -> void:
	var new_tile = Sprite2D.new()
	new_tile.texture = tile_sprite
	new_tile.position = position
	add_child(new_tile)
	

func _ready() -> void:
	if tile_sprite.region.size.x != tile_sprite.region.size.y && tile_sprite.region.size.x != tile_size_pixels:
		push_error("Invalid tile sprite size, expected size ", tile_size_pixels)
		get_tree().quit()
	
	noise.noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN
	
	var tiles_generated = 0
	for y in range(height):
		for x in range(width):
			var noise_value = noise.get_noise_2d(x, y)
			if noise_value >= noise_threshold:
				spawn_tile_at(Vector2(x * tile_size_pixels, y * tile_size_pixels))
				tiles_generated += 1
	
	print("Tiles generated: ", tiles_generated)
