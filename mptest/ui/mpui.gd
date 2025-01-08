extends Node

class_name LocalPlayerListManager

class PlayerListEntry extends Label:
	var _player_id: int
	var _player_name: String
	
	func _init(scene_parent: Node, player_id: int, player_name: String):
		_player_id = player_id
		_player_name = player_name
		text = player_name
		scene_parent.add_child(self)
		

var _player_list: Dictionary = {}

@onready var _player_list_node = $Panel/VBoxContainer


func add_player_to_list(player_id: int, player_name: String) -> void:
	_player_list[player_id] = PlayerListEntry.new(_player_list_node, player_id, player_name)
	

func remove_player_from_list(player_id: int) -> void:
	_player_list.erase(player_id)
