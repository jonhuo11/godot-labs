extends Node

var server_list: ServerListClass

const master_server_ip = "http://0.0.0.0:8000"

func _ready():
	server_list = ServerListClass.new()

	$ListRefreshTimer.timeout.connect(_on_list_refresh_timer_timeout)

	print("server list ready!")

func get_server_list():
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_got_server_list)
	http.request(master_server_ip + "/")

func _got_server_list(result, response_code, _headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("failed to get servers: " + response_code)
		return
	
	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		push_error("failed to parse json body")
		return
	var data = json.get_data()
	print(data)

func _on_list_refresh_timer_timeout():
	print("refreshing server list...")
	get_server_list()
