extends Control

var ogat_server: OgatServer
var is_host: bool = false

func init(server: OgatServer) -> void:
	if server.ip == "": # we are hosting
		is_host = true
	ogat_server = server


func _ready() -> void:
	if ogat_server == null:
		push_error("server info was not initialized")
		return
	if !ogat_server.validate():
		push_error("server is invalid")
		return
	print("starting server with settings: %s" % ogat_server.info())

	if is_host:
		# start multiplayer server, register with master server, and load IP
		# the master server will infer the IP and pass it back
		var peer := ENetMultiplayerPeer.new()
		peer.create_server(ogat_server.port)
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
		ogat_server.ip = ip
	else:
		# connect to the server with the given ip
		var peer := ENetMultiplayerPeer.new()
		peer.create_client(ogat_server.ip, ogat_server.port)
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
			push_error("Failed to start multiplayer client.")
			return
		multiplayer.multiplayer_peer = peer
	
	start_lobby()


func _register_with_master_server():
	var http = HTTPRequest.new()
	add_child(http)

	var headers := [
		"Content-Type: application/json",
		"Accept: application/json"
	]
	var json: String = ogat_server.json()

	http.request(OgatServerList.master_server_ip + "/lobbies", headers, HTTPClient.METHOD_POST, json)
	return http.request_completed

func start_lobby() -> void:
	print("lobby started! %s" % ogat_server.info())
	pass
