extends Control

@export_node_path(Camera3D) var camera_path

var _lines = []
var _camera

func _ready():
	_camera = get_node(camera_path)


func _process(delta):
	update()


func _draw():
	draw()


func add_line(start:Vector3, end:Vector3, color:Color, width:float):
	_lines.append({"Start":start, "End":end, "Color":color, "Width":width})


func set_lines(lines):
	_lines = lines


func draw():
	for l in _lines:
		var start = _camera.unproject_position(l["Start"])
		var end = _camera.unproject_position(l["End"])
		draw_line(start, end, l["Color"], l["Width"])
