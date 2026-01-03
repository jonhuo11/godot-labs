class_name OgatServer extends RefCounted

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

# TODO: implement
func from_json(_json: String) -> OgatServer:
	return OgatServer.new("", "", 0, 0)