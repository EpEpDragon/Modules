extends Control

@export_node_path(Camera3D) var camera_path
@export var draw_fov = 60

var _lines = []
var _paths:Array[Path3D] = []
var _camera
var _p = []

func _ready():
	_camera = get_node(camera_path)


func _process(delta):
	update()


func _draw():
	for l in _p:
		var p_proj:PackedVector2Array
		for point in l[0]:
			p_proj.append(_camera.unproject_position(point))
			
		draw_polyline(p_proj,l[1])
	var zero = _camera.unproject_position(Vector3.ZERO)
	
	draw_line(zero,_camera.unproject_position(Vector3(1,0,0)),Color.RED)
	draw_line(zero,_camera.unproject_position(Vector3(0,1,0)),Color.GREEN)
	draw_line(zero,_camera.unproject_position(Vector3(0,0,1)),Color.BLUE)
#	for l in _lines:
#		var look_dir = _camera.get_global_transform().basis.z
#		var cam_pos = _camera.position
#		if look_dir.angle_to(cam_pos-l["Start"]) < deg2rad(draw_fov) && look_dir.angle_to(cam_pos-l["End"]) < deg2rad(draw_fov):
#			var start = _camera.unproject_position(l["Start"])
#			var end = _camera.unproject_position(l["End"])
#			draw_line(start, end, l["Color"], l["Width"])

#	var points:PackedVector2Array
#	for path in _paths:
#		points = []
#		for point in path.get_curve().get_baked_points():
#			points.append(_camera.unproject_position(point))
#
#		draw_polyline(points, Color.WHITE, 5)
#	points = []
#	for point in _paths[3].get_curve().get_baked_points():
#		points.append(_camera.unproject_position(point))
#	print(_paths[3].get_curve().get_baked_points())
#	draw_polyline(points, Color.RED, 5)

func add_line(start:Vector3, end:Vector3, color:Color, width:float):
	_lines.append({"Start":start, "End":end, "Color":color, "Width":width})

func set_lines(lines):
	_lines = lines

func set_packed(p):
	_p = p

func add_packed(p,c):
	_p.append([p,c])

func set_paths(paths):
	_paths = paths
