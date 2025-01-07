extends HBoxContainer

class_name EarthquakeEntry

var magnitude: float
var location: String

func setup(_magnitude: float, _location: String) -> void:
	magnitude = _magnitude
	location = _location


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var magnitudeLabel = Label.new()
	magnitudeLabel.text = str(magnitude)
	var locationLabel = Label.new()
	locationLabel.text = location
	add_child(magnitudeLabel)
	add_child(locationLabel)
