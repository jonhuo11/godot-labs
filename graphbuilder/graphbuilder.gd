extends Node2D

@onready var canvas_layer = $CanvasLayer
@onready var label_font: Font = preload("res://graphbuilder/assets/graphlabel.tres")

var active_node = null
var node_picked_up_at = 0

var active_edge_start = null
var nodes_to_edges = {} # (reference, list of edges)

var counter = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if active_node:
		active_node.position = get_viewport().get_mouse_position()
		
	queue_redraw()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if active_node and Time.get_ticks_msec() - node_picked_up_at > 100:
			active_node = null
			

func _draw():
	if active_edge_start:
		var start_node = active_edge_start
		draw_line(start_node.get_global_position(), get_viewport().get_mouse_position(), Color.WHITE, 2.0)
		
	# draw all active lines
	for from in nodes_to_edges:
		for to in nodes_to_edges[from]:
			draw_line(from.get_global_position(), to.get_global_position(), Color.WHITE, 1.0)
			
			# label for the line
			var midpoint = (from.get_global_position() + to.get_global_position())/2
			var dist = round(from.get_global_position().distance_to(to.get_global_position()))
			draw_string(label_font, Vector2(midpoint.x, midpoint.y), "{0}".format([dist]))

func _on_button_pressed() -> void:
	var graph_node_scn = preload("res://graphbuilder/graphnode.tscn")
	var graph_node = graph_node_scn.instantiate()
	canvas_layer.add_child(graph_node)
	
	# connect the click signal
	graph_node.clicked.connect(_on_node_clicked.bind(graph_node))
	graph_node.rclicked.connect(_on_node_rclicked.bind(graph_node))
	
	graph_node.position = get_viewport().get_mouse_position()
	graph_node.set_label(str(counter))
	counter += 1
	
	active_node = graph_node
	node_picked_up_at = Time.get_ticks_msec()

func _on_node_clicked(signaller_node) -> void:
	print("Node clicked")
	if active_node:
		return
	active_node = signaller_node
	node_picked_up_at = Time.get_ticks_msec()
	
func _on_node_rclicked(signaller_node) -> void:
	print("Node r clicked")
	if active_edge_start:
		# end the line at the right clicked node
		var from = active_edge_start
		var to = signaller_node
		if from not in nodes_to_edges:
			nodes_to_edges[from] = []
		nodes_to_edges[from].append(to)
		active_edge_start = null
	else:
		# start a new edge
		active_edge_start = null
		active_edge_start = signaller_node
