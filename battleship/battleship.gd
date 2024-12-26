extends Node

@export var turrets: Array[BattleshipTurret] = []


# generate the nodes for the ship body
func construct_ship() -> void:
	# construct main turret parts
	
	# construct front and back
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if len(turrets) < 1:
		push_error("Not enough turrets on battleship")
		get_tree().quit()
	
	construct_ship()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
