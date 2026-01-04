class_name ChatMessage extends OgatLobbySerializable

var author_id: int
var message: String

func _init(_author_id: int, _message: String):
	author_id = _author_id
	message = _message

func serialize() -> PackedByteArray:
	var payload := {
		"author_id": author_id,
		"message": message,
	}
	return var_to_bytes(payload)

func fill_from_serialized(_pba: PackedByteArray) -> void:
	var v = bytes_to_var(_pba)

	if typeof(v) != TYPE_DICTIONARY:
		push_error("ChatMessage: expected Dictionary")
		return

	if not v.has("author_id") or typeof(v["author_id"]) != TYPE_INT:
		push_error("ChatMessage: invalid or missing author_id")
		return

	if not v.has("message") or typeof(v["message"]) != TYPE_STRING:
		push_error("ChatMessage: invalid or missing message")
		return

	author_id = v["author_id"]
	message = v["message"]