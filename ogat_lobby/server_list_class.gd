class_name ServerListClass
extends RefCounted

class Server extends RefCounted:
	var name: String
	var ip: String
	var port: int
	var max_players: int

	func _init(name: String, ip: String, port: int, max_players: int):
		self.name = name
		self.ip = ip
		self.port = port
		self.max_players = max_players

var server_list: Dictionary

func add_server(name: String, ip: String, port: int, max_players: int):
	if name in server_list:
		return

	server_list[name] = Server.new(name, ip, port, max_players)

func rm_server(name: String):
	server_list.erase(name)
