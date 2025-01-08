extends Node

	

const HOST = "localhost"
const PORT = 9100


@export var local_playerlist_manager: LocalPlayerListManager
@export var connection_ui: Control
@export var username_input: TextEdit


var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

# each client keeps a list of all other clients
var players: Dictionary = {} # id: name


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
	
	
@rpc("call_local", "any_peer", "reliable")
func _register_this_player_name(username: String) -> void:
	var sender_pid = multiplayer.get_remote_sender_id()
	players[sender_pid] = username
	local_playerlist_manager.add_player_to_list(sender_pid, username)


# called by each peer
func _on_player_connected(id: int) -> void:
	# let the new client know what my name is
	# each client is responsible for sending its name to the new client
	_register_this_player_name.rpc_id(id, players[multiplayer.get_unique_id()])
	

func _on_multiplayer_peer_created() -> void:
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_player_connected)
	var my_id = multiplayer.get_unique_id()
	players[my_id] = username_input.text
	local_playerlist_manager.add_player_to_list(my_id, players[my_id])
	connection_ui.hide()
	

func _on_host_pressed() -> void:
	peer.create_server(PORT)
	_on_multiplayer_peer_created()
	

func _on_join_pressed() -> void:
	peer.create_client(HOST, PORT)
	_on_multiplayer_peer_created()
	
