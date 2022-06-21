extends Control

@export_node_path(Camera3D) var camera_path
@export_color_no_alpha var color = Color.WHITE
@export var width = 10


var lines = []
var camera

func _ready():
	camera = get_node(camera_path)


func _process(delta):
	update()


func _draw():
	draw()


func add_line(start:Vector3, end:Vector3, color:Color, width:float):
	lines.append({"Start":start, "End":end, "Color":color, "Width":width})


func set_lines(lines):
	lines = lines


func draw():
	for l in lines:
		var start = camera.unproject_position(l["Start"])
		var end = camera.unproject_position(l["End"])
		draw_line(start, end, l["Color"], l["Width"])
