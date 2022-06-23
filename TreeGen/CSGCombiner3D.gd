extends CSGPolygon3D

func _ready():
	var path = Path3D.new()
	path.set_curve(Curve3D.new())
	path.get_curve().add_point(Vector3.ZERO)
	path.get_curve().add_point(Vector3(1,0,0))
	
	set_polygon(gen_circle(0.1,10))
	add_child(path)
	set_path_node(get_path_to(get_child(0)))

#	_update_shape()
#	var mesh = get_meshes()[1]
#	ResourceSaver.save("res://test.mesh",mesh)

func gen_circle(r:float, res:int):
	var step = PI/2/res
	var points:PackedVector2Array
	
	var angle = 0
	for i in range(4*res):
		points.append(r*Vector2(cos(angle),sin(angle)))
		angle += step
		
	return points
