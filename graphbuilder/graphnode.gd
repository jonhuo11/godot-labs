extends Control

@onready var label = $Label
@onready var texture_rect = $TextureRect

signal clicked
signal rclicked

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	texture_rect.gui_input.connect(_on_texture_gui_input)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_label(text: String) -> void:
	label.text = text

func _on_texture_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("clicked")
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			emit_signal("rclicked")
