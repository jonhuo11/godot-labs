# mp_lobby.gd sets up the multiplayer peer
# this script only manages connection state, not logic
# lobby logic is controlled by s_lobby.gd
# client UI changes / actions controlled and sent from c_lobby.gd

class_name MpLobby extends Node

var _ogat_lobby: OgatLobby
var _is_host: bool = false
var _nickname: String = "Anonymous Scout"

var nickname: String: # readonly
	get:
		return _nickname

signal joined_server

func init(server: OgatLobby, nick: String) -> void:
	if server.ip == "": # we are hosting
		_is_host = true
	_ogat_lobby = server
	_nickname = nick if len(nick.strip_edges()) > 0 else _nickname


func _ready() -> void:
	if _ogat_lobby == null:
		push_error("server info was not initialized")
		return
	if !_ogat_lobby.validate():
		push_error("server is invalid")
		return
	print("starting server with settings: %s" % _ogat_lobby.info())

	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.connection_failed.connect(_conn_failed)
	multiplayer.server_disconnected.connect(_server_disconnected)

	if _is_host:
		# start multiplayer server, register with master server, and load IP
		# the master server will infer the IP and pass it back
		var peer := ENetMultiplayerPeer.new()
		peer.create_server(_ogat_lobby.port)
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
		var ip = str(LibOgat.dig(data, ["lobby", "ip"], ""))
		_ogat_lobby.ip = ip

		# Godot does not consider servers as clients,
		# so manually trigger the client events for connect/disconnect.
		# We do this because the server is also a player
		_connected_to_server()
	else:
		# connect to the server with the given ip
		var peer := ENetMultiplayerPeer.new()
		peer.create_client(_ogat_lobby.ip, _ogat_lobby.port)
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
			push_error("Failed to start multiplayer client.")
			return
		multiplayer.multiplayer_peer = peer
	
	print("multiplayer peer initialized!")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			print("exiting to menu...")
			_back_to_menu()


func _exit_tree() -> void:
	if multiplayer.is_server():
		_server_disconnected()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new() # terminates networking


# TODO: this should use UPnP to grab a forwarded port
func _register_with_master_server():
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		func(_a, _b, _c, _d):
			http.queue_free()
	)

	var headers := [
		"Content-Type: application/json",
		"Accept: application/json"
	]
	var json: String = _ogat_lobby.json()

	http.request(OgatLobbyList.master_server_ip + "/lobbies", headers, HTTPClient.METHOD_POST, json)
	return http.request_completed

# triggered on clients automatically, manually called for server cleanup (server is a player too)
func _server_disconnected():
	print("the server quit the game")
	_ogat_lobby = null
	_is_host = false
	_back_to_menu()


func _conn_failed():
	print("connection failed")
	_back_to_menu()


# triggered on clients automatically, manually called for server cleanup (server is a player too)
func _connected_to_server():
	print("connected to server as Player %d!" % multiplayer.get_unique_id())
	joined_server.emit()


func _back_to_menu() -> void:
	get_tree().change_scene_to_file("res://ogat_lobby/lobby_list/lobby_list.tscn")
