class_name OgatLobby extends RefCounted

var name: String
var ip: String
var port: int
var max_players: int

func _init(_name: String, _ip: String, _port: int, _max_players: int):
	name = _name
	ip = _ip
	port = _port
	max_players = _max_players

# TODO: return false if the server fields are invalid
func validate() -> bool:
	return true

func info() -> String:
	return "%s %s:%d (max %d players)" % [name, ip, port, max_players]

func json() -> String:
	var dict := {
		"name": name,
		"ip": ip,
		"port": port,
		"max_players": max_players
	}
	return JSON.stringify(dict)

static func from_json(json_str: String) -> OgatLobby:
	var json_parser := JSON.new()
	if json_parser.parse(json_str) != OK:
		push_error("failed to parse json_parser body")
		return
	var data = json_parser.get_data()
	return OgatLobby.new(data["name"], data["ip"], int(data["port"]), int(data["max_players"]))

static func from_dict(d: Dictionary) -> OgatLobby:
	return OgatLobby.new(d["name"], d["ip"], int(d["port"]), int(d["max_players"]))