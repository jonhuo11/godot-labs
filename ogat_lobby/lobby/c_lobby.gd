# c_lobby.gd updates UI and sends client actions to the server
# expects s_lobby to be a sibling named "Server"

extends Node

var message_input: LineEdit
var s_lobby: SLobby

var message_log := [] # []ChatMessage

func _ready() -> void:
	s_lobby = get_node("../Server")
	assert(s_lobby != null, "could not find server script node")
	message_input = get_node("../Chat/ChatContainer/ChatInputContainer/ChatField")
	assert(message_input != null, "could not find chat field")

	# subscribe to events from the server
	s_lobby.recv_chat_message.connect(_recv_chat_message)
	s_lobby.player_connected.connect(_player_connected)

func _recv_chat_message(cm: ChatMessage) -> void:
	message_log.append(cm)
	print("client %d got message %s" % [multiplayer.get_unique_id(), cm.message])

func _player_connected() -> void:
	pass

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
