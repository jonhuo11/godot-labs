# s_lobby.gd contains the authoritative lobby state and defines RPCs

# inform  -> 	The server calls the function to inform clients of an event.
# request -> 	A client requests the server take some action.
# 			 	In this case, the call should be made using .rpc_id(1) so that the
# 				rpc only runs on the server

# Do not directly call methods suffixed with _rpc directly, use the helper without the suffix
# This will prevent accidentally calling server targeted RPCs on clients

# Why have the inform/request abstraction? Its somewhat overengineered
# Having distinct server/client RPCs will make it clear who is receiving function calls
# Variables prefixed with
# - s_ are server side only
# - c_ are client side only
# Makes it clear exactly what you should be reading from

class_name SLobby
extends Node

const SERVER_ID = 1

var s_player_list: Dictionary[int, LobbyPlayer] = {} # id : LobbyPlayer
var s_message_log: Array[ChatMessage] = [] # ChatMessage


# signals that client side code can subscribe to
signal player_connected(player: LobbyPlayer)
signal recv_chat_message(msg: ChatMessage)


func _ready() -> void:
	assert(name == "Server", "must be named server")


#region Server logic
func _on_player_connected(p: LobbyPlayer) -> void:
	# inform the newly connected player of all existing connections
	for existing_player_id in s_player_list:
		var existing_player := s_player_list[existing_player_id]
		inform_connected_rpc.rpc_id(p.id, existing_player.serialize())

	# inform all players the new player connected
	s_player_list[p.id] = p
	inform_connected(p)

func _on_recv_message_from_client(msg: ChatMessage) -> void:
	s_message_log.append(msg)
	inform_recv_message(msg) # relays message to all clients

	# debug: confirm the server received message
	print("server (id: %d) received message %s from %d" % [multiplayer.get_unique_id(), msg.message, multiplayer.get_remote_sender_id()])
#endregion


#region RPC
@rpc("any_peer", "call_local", "reliable")
func request_connected_rpc(ppba: PackedByteArray):
	if !multiplayer.is_server():
		return
	var p := LobbyPlayer.new(0, "", "")
	p.fill_from_serialized(ppba)
	# the ID will always be their multiplayer ID, ignore whats set here
	p.id = multiplayer.get_remote_sender_id()
	_on_player_connected(p)

func request_connected(p: LobbyPlayer):
	p.id = -1 # not valid, this is auto set later
	request_connected_rpc.rpc_id(SERVER_ID, p.serialize())


@rpc("authority", "call_local", "reliable")
func inform_connected_rpc(ppba: PackedByteArray):
	# the server calls this on all clients, causing client code to emit a signal
	var p := LobbyPlayer.new(0, "", "")
	p.fill_from_serialized(ppba)
	player_connected.emit(p)

func inform_connected(p: LobbyPlayer):
	inform_connected_rpc.rpc(p.serialize())


@rpc("authority", "call_local", "reliable")
func inform_recv_message_rpc(message_pba: PackedByteArray):
	# the server calls this on all clients, causing client code to emit a signal
	var msg = ChatMessage.new(0, "")
	msg.fill_from_serialized(message_pba)
	recv_chat_message.emit(msg)

func inform_recv_message(msg: ChatMessage):
	inform_recv_message_rpc.rpc(msg.serialize())


@rpc("any_peer", "call_local", "reliable")
func request_send_message_rpc(msg_pba: PackedByteArray):
	if !multiplayer.is_server():
		return

	var msg = ChatMessage.new(0, "")
	msg.fill_from_serialized(msg_pba)
	_on_recv_message_from_client(msg)

func request_send_message(msg: ChatMessage):
	request_send_message_rpc.rpc_id(SERVER_ID, msg.serialize())
#endregion