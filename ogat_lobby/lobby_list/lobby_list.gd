class_name OgatLobbyList extends Control

const master_server_ip := "http://0.0.0.0:8000"

const JoinServerButton := preload("res://ogat_lobby/lobby_list/join_server_button.tscn")

@onready var LobbyScene := preload("res://ogat_lobby/lobby/lobby.tscn")
@onready var server_list_container := $"LobbyListContainer"
@onready var nickname_field := $"NicknameField" as LineEdit

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
	http.request_completed.connect(
		func(result, response_code, _headers, body):
			_got_server_list(result, response_code, _headers, body)
			http.queue_free()
	)
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

	# remove old list
	server_list.clear()
	for lobby_name in server_list_ui_buttons:
		var btn := server_list_ui_buttons[lobby_name]
		btn.queue_free()
	server_list_ui_buttons.clear()

	var lobbies = LibOgat.dig(data, ["lobbies"], {})
	for lobby_name in lobbies:
		var lobby = OgatLobby.from_dict(lobbies[lobby_name])
		server_list[lobby_name] = lobby

		var new_button := JoinServerButton.instantiate()
		new_button.text = lobby.info()
		server_list_container.add_child(new_button)
		server_list_ui_buttons[lobby_name] = new_button

		# subscribe to the click event
		server_list_ui_buttons[lobby_name].pressed.connect(_join_server_func(lobby_name))


func _join_server_func(lobby_name: String) -> Callable:
	return func() -> void:
		var lobby := server_list[lobby_name]
		print("joining lobby %s..." % lobby.info())
		var scene := LobbyScene.instantiate()
		scene.init(lobby, nickname_field.text)
		_switch_to_scene(scene)
		

func _on_list_refresh_timer_timeout():
	print("refreshing server list...")
	get_server_list()


func _on_host_server_button_toggled(toggled_on: bool) -> void:
	$NewLobbyPopup.visible = toggled_on


# switch to the lobby scene, passing in server settings
# IP is empty, will be loaded in the lobby scene
func _on_start_server_pressed() -> void:
	var server_name = $NewLobbyPopup/LobbyNameInput.text
	var server_port = int($NewLobbyPopup/PortInput.text)
	var max_players = int($NewLobbyPopup/MaxPlayersInput.text)

	var scene := LobbyScene.instantiate()
	scene.init(OgatLobby.new(server_name, "", server_port, max_players), nickname_field.text)
	_switch_to_scene(scene)

func _switch_to_scene(inst: Node) -> void:
	var old := get_tree().current_scene
	get_tree().root.add_child(inst)
	get_tree().current_scene = inst
	if old:
		old.queue_free()
