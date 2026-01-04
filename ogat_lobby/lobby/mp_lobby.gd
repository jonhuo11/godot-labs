# mp_lobby.gd sets up the multiplayer peer
# lobby logic is controlled by s_lobby.gd
# client actions sent from c_lobby.gd

extends Node

var ogat_lobby: OgatLobby
var is_host: bool = false

signal joined_server

func init(server: OgatLobby) -> void:
	if server.ip == "": # we are hosting
		is_host = true
	ogat_lobby = server


func _ready() -> void:
	if ogat_lobby == null:
		push_error("server info was not initialized")
		return
	if !ogat_lobby.validate():
		push_error("server is invalid")
		return
	print("starting server with settings: %s" % ogat_lobby.info())

	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.connection_failed.connect(_conn_failed)
	multiplayer.server_disconnected.connect(_server_disconnected)

	if is_host:
		# start multiplayer server, register with master server, and load IP
		# the master server will infer the IP and pass it back
		var peer := ENetMultiplayerPeer.new()
		peer.create_server(ogat_lobby.port)
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
			push_error("failed to start server")
			return
		multiplayer.multiplayer_peer = peer

		var result = await _register_with_master_server()
		var result_code = result[0]
		var response_code = result[1]
		var body: PackedByteArray = result[3]
		if result_code != OK or response_code != HTTPClient.RESPONSE_OK:
			push_error("failed to register with master server: %d" % response_code)
			return
		var json := JSON.new()
		if json.parse(body.get_string_from_utf8()) != OK:
			push_error("failed to parse register with master server response json")
			return
		var data = json.get_data()
		print("master server response: %s" % data)
		var ip = str(data["lobby"]["ip"])
		ogat_lobby.ip = ip
	else:
		# connect to the server with the given ip
		var peer := ENetMultiplayerPeer.new()
		peer.create_client(ogat_lobby.ip, ogat_lobby.port)
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
			push_error("Failed to start multiplayer client.")
			return
		multiplayer.multiplayer_peer = peer
	
	print("multiplayer peer initialized!")

func _exit_tree() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new() # terminates networking


# TODO: this should use UPnP to grab a forwarded port
func _register_with_master_server():
	var http = HTTPRequest.new()
	add_child(http)

	var headers := [
		"Content-Type: application/json",
		"Accept: application/json"
	]
	var json: String = ogat_lobby.json()

	http.request(OgatLobbyList.master_server_ip + "/lobbies", headers, HTTPClient.METHOD_POST, json)
	return http.request_completed

func _server_disconnected():
	print("the server quit the game")
	ogat_lobby = null
	is_host = false

func _conn_failed():
	print("connection failed")

func _connected_to_server():
	print("connected to server!")
	joined_server.emit()
