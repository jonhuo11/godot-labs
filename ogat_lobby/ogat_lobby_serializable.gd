class_name OgatLobbySerializable extends RefCounted

func serialize() -> PackedByteArray:
	return []

# inits calling instance using serialized data
func fill_from_serialized(_pba: PackedByteArray) -> void:
	return