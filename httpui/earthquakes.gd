extends HTTPRequest

var earthquake_entry: PackedScene = preload("res://httpui/earthquake_entry.tscn")

const EARTHQUAKE_API_URL = "https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&starttime=2025-01-01&endtime=2025-12-30"

@export var entries_container: Container

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	request_completed.connect(_on_request_completed)
	var error = request(EARTHQUAKE_API_URL)
	if error != OK:
		push_error("Could not create the request")
		return


func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result != RESULT_SUCCESS or response_code != 200:
		push_error("Request failed")
		return
	
	var json_parser = JSON.new()
	var parse_error = json_parser.parse(body.get_string_from_utf8())
	if parse_error != OK:
		push_error("Failed to parse JSON")
		return
	
	for feature in json_parser.data["features"]:
		var quake = feature.get("properties")
		if not quake:
			continue
		var entry = earthquake_entry.instantiate() as EarthquakeEntry
		entry.setup(quake.get("mag"), quake.get("place"))
		entries_container.add_child(entry)
	
