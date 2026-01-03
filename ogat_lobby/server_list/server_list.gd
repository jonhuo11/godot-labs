class_name OgatServerList extends Control

const master_server_ip := "http://0.0.0.0:8000"

var server_list: Dictionary = {}

func add_server(srv_name: String, ip: String, port: int, max_players: int):
	if srv_name in server_list:
		return

	server_list[name] = OgatServer.new(name, ip, port, max_players)

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
	
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		push_error("failed to parse json body")
		return
	var data = json.get_data()
	print(data)


func _on_list_refresh_timer_timeout():
	print("refreshing server list...")
	get_server_list()


func _on_host_server_button_toggled(toggled_on: bool) -> void:
	$NewServerPopup.visible = toggled_on


# switch to the lobby scene, passing in server settings
# IP is empty, will be loaded in the lobby scene
func _on_start_server_pressed() -> void:
	var scene := preload("res://ogat_lobby/ogat_lobby.tscn").instantiate()

	var server_name = $NewServerPopup/ServerNameInput.text
	var server_port = int($NewServerPopup/PortInput.text)
	var max_players = int($NewServerPopup/MaxPlayersInput.text)

	scene.init(OgatServer.new(server_name, "", server_port, max_players))
	switch_to_scene(scene)

func switch_to_scene(inst: Node) -> void:
	var old := get_tree().current_scene
	get_tree().root.add_child(inst)
	get_tree().current_scene = inst
	if old:
		old.queue_free()
