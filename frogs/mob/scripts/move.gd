extends Node2D

class ValueRange:
	var _min: float
	var _max: float

	func _init(__min: float, __max: float):
		if __min > __max:
			push_error("Range min cannot be greater than max")
		_min = __min
		_max = __max
		
	func pick_random() -> float:
		return randf_range(_min, _max)

class PickRandomNotCurrent:
	var _i: int
	var _arr: Array
	
	func _init(items: Array):
		_arr = items
		_i = 0
		
	func _randi_between_inclusive(_min: int, _max: int) -> int:
		if _max < _min:
			return _min
		return randi() % (_max - _min + 1) + _min
		
	func rand() -> void:
		var random_index = (_i + _randi_between_inclusive(1, len(_arr) - 1)) % len(_arr)
		_i = random_index
		
	func cur() -> Variant:
		return _arr[_i]


enum Directions {
	UP,
	RIGHT,
	DOWN,
	LEFT
}

const DIRECTION_VECTORS: Dictionary = {
	Directions.UP: Vector2(0, -1),
	Directions.DOWN: Vector2(0, 1),
	Directions.LEFT: Vector2(-1, 0),
	Directions.RIGHT: Vector2(1, 0)
}

const PICKABLE_DIRECTIONS: Array[Directions] = [Directions.UP, Directions.RIGHT, Directions.DOWN, Directions.LEFT]
var direction = PickRandomNotCurrent.new(PICKABLE_DIRECTIONS)

var speed = 1
var newDirectionDelayRange: ValueRange = ValueRange.new(1, 5)
var pickNewDirectionDelay: float = 0
var secondsSinceLastDirectionPick: float = 0

@onready var animated_sprite = $AnimatedSprite2D


func _ready() -> void:
	animated_sprite.play("default")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if secondsSinceLastDirectionPick >= pickNewDirectionDelay:
		pickNewDirectionDelay = newDirectionDelayRange.pick_random()
		secondsSinceLastDirectionPick = 0
		
		# pick new direction
		direction.rand()
		if direction.cur() == Directions.LEFT:
			animated_sprite.scale.x = 1
		elif direction.cur() == Directions.RIGHT:
			animated_sprite.scale.x = -1
	else:
		secondsSinceLastDirectionPick += delta
		
	# move in direction
	translate(DIRECTION_VECTORS[direction.cur()].normalized() * speed)
