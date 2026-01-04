# c_lobby.gd updates UI and sends client actions to the server
# expects s_lobby to be a sibling named "Server"

extends Node

const SYSTEM_ID := -11

@onready var player_list_container: VBoxContainer = get_node("../PlayerList/PlayerListContainer")
@onready var chat_messages_container: VBoxContainer = get_node("../Chat/ChatContainer/ChatMessagesScrollContainer/ChatMessagesContainer")
@onready var message_input: LineEdit = get_node("../Chat/ChatContainer/ChatInputContainer/ChatField")
@onready var ChatMessageLabel := preload("res://ogat_lobby/lobby/chat_message.tscn")

@onready var s_lobby: SLobby = get_node("../Server")
@onready var mp_lobby: MpLobby = get_parent()

var player_list: Dictionary[int, LobbyPlayer] = {}
var message_log: Array[ChatMessage] = []


func _ready() -> void:
	assert(mp_lobby != null, "could not find mp connection manager node")
	assert(s_lobby != null, "could not find server script node")
	assert(message_input != null, "could not find chat field")
	assert(chat_messages_container != null, "could not find chat messages container")
	assert(player_list_container != null, "could not find player list container")

	# subscribe to events from the mp connection / server
	mp_lobby.joined_server.connect(_i_joined_server)
	s_lobby.recv_chat_message.connect(_recv_chat_message)
	s_lobby.player_connected.connect(_player_connected)


func _recv_chat_message(cm: ChatMessage) -> void:
	message_log.append(cm)
	print("client %d got message %s" % [multiplayer.get_unique_id(), cm.message])

	# update chat UI
	var nn := player_list[cm.author_id].nickname
	var new_txt := "%s%s: %s" % [nn, "" if cm.author_id != 1 else " (host)", cm.message]
	_spawn_chat_message(new_txt, chat_messages_container)

func _i_joined_server() -> void:
	var me := LobbyPlayer.new(-1, mp_lobby.nickname, "Unknown Group")
	s_lobby.request_connected(me)

# when a player connects to the server
func _player_connected(p: LobbyPlayer) -> void:
	player_list[p.id] = p

	_spawn_chat_message(p.nickname, player_list_container)

	var join_msg := ChatMessage.new(SYSTEM_ID, "%s (%d) joined the lobby" % [p.nickname, p.id])
	message_log.append(join_msg)
	_spawn_chat_message(join_msg.message, chat_messages_container)


func _send_message(message: String):
	message_input.text = ""
	print("sending message to server: %s" % message)

	var msg := ChatMessage.new(multiplayer.get_unique_id(), message)
	s_lobby.request_send_message(msg)


func _on_send_button_pressed() -> void:
	var message_contents := message_input.text
	_send_message(message_contents)


func _on_chat_field_text_submitted(new_text: String) -> void:
	_send_message(new_text)


func _spawn_chat_message(text: String, parent: Node) -> void:
	var new_chat_msg := ChatMessageLabel.instantiate() as Label
	new_chat_msg.text = text
	parent.add_child(new_chat_msg)