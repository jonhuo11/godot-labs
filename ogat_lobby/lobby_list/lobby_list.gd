class_name OgatLobbyList extends Control

const master_server_ip := "http://0.0.0.0:8000"

const JoinServerButton := preload("res://ogat_lobby/lobby_list/join_server_button.tscn")

@onready var server_list_container := $"LobbyListContainer"

var server_list: Dictionary[String, OgatLobby] = {} # name : OgatLobby
var server_list_ui_buttons: Dictionary[String, Button] = {} # name : JoinServerButton

func add_server(srv_name: String, ip: String, port: int, max_players: int):
	if srv_name in server_list:
		return

	server_list[name] = OgatLobby.new(name, ip, port, max_players)

func rm_server(srv_name: String):
	server_list.erase(srv_name)


func _ready():
	$ListRefreshTimer.timeout.connect(_on_list_refresh_timer_timeout)
	print("server list ready!")


func get_server_list():
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_got_server_list)
	http.request(master_server_ip + "/lobbies")


func _got_server_list(result, response_code, _headers, body):
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_error("failed to get servers: %d" % response_code)
		return
	
	var json_parser := JSON.new()
	if json_parser.parse(body.get_string_from_utf8()) != OK:
		push_error("failed to parse json_parser body")
		return
	var data = json_parser.get_data()

	var lobbies = LibOgat.dig(data, ["lobbies"], {})
	for lobby_name in lobbies:
		var lobby = OgatLobby.from_dict(lobbies[lobby_name])

		server_list[lobby_name] = lobby
		
		if lobby_name in server_list_ui_buttons:
			server_list_ui_buttons[lobby_name].text = lobby.info()
			var n := LibOgat.clear_handlers(server_list_ui_buttons[lobby_name].pressed)
			print("cleaned up %d signal handlers on old join button for %s" % [n, lobby_name])
		else:
			var new_button := JoinServerButton.instantiate()
			new_button.text = lobby.info()
			server_list_container.add_child(new_button)
			server_list_ui_buttons[lobby_name] = new_button

		# subscribe to the click event
		server_list_ui_buttons[lobby_name].pressed.connect(_join_server_func(lobby_name))


func _join_server_func(lobby_name: String) -> Callable:
	return func() -> void:
		print("joining lobby %s" % lobby_name)
		

func _on_list_refresh_timer_timeout():
	print("refreshing server list...")
	get_server_list()


func _on_host_server_button_toggled(toggled_on: bool) -> void:
	$NewLobbyPopup.visible = toggled_on


# switch to the lobby scene, passing in server settings
# IP is empty, will be loaded in the lobby scene
func _on_start_server_pressed() -> void:
	var scene := preload("res://ogat_lobby/lobby/lobby.tscn").instantiate()

	var server_name = $NewLobbyPopup/LobbyNameInput.text
	var server_port = int($NewLobbyPopup/PortInput.text)
	var max_players = int($NewLobbyPopup/MaxPlayersInput.text)

	scene.init(OgatLobby.new(server_name, "", server_port, max_players))
	switch_to_scene(scene)

func switch_to_scene(inst: Node) -> void:
	var old := get_tree().current_scene
	get_tree().root.add_child(inst)
	get_tree().current_scene = inst
	if old:
		old.queue_free()
