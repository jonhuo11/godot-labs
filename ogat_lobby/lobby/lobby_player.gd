class_name LobbyPlayer extends OgatLobbySerializable

var id: int # the network id
var nickname: String
var group: String

func _init(_id: int, _nickname: String, _group: String):
	id = _id
	nickname = _nickname
	group = _group

func serialize() -> PackedByteArray:
	var payload := {
		"id": id,
		"nickname": nickname,
		"group": group,
	}
	return var_to_bytes(payload)

func fill_from_serialized(_pba: PackedByteArray) -> void:
	var v = bytes_to_var(_pba)

	if typeof(v) != TYPE_DICTIONARY:
		push_error("LobbyPlayer: expected Dictionary")
		return

	if not v.has("id") or typeof(v["id"]) != TYPE_INT:
		push_error("LobbyPlayer: invalid or missing id")
		return

	if not v.has("nickname") or typeof(v["nickname"]) != TYPE_STRING:
		push_error("LobbyPlayer: invalid or missing nickname")
		return

	if not v.has("group") or typeof(v["group"]) != TYPE_STRING:
		push_error("LobbyPlayer: invalid or missing group")
		return

	id = v["id"]
	nickname = v["nickname"]
	group = v["group"]
