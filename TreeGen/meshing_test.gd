extends Node3D


func _ready():
	pass
#	var csg = CSGPolygon3D.new()
#	var path = Path3D.new()
#	add_child(path)
#
#	path.set_curve(Curve3D.new())
#	path.get_curve().add_point(Vector3.ZERO)
#	path.get_curve().add_point(Vector3(0,1,0))
#	path.get_curve().add_point(Vector3(0,1,1))
#	csg.set_path_node(get_child(2).get_path())
#	csg.set_mode(CSGPolygon3D.MODE_PATH)
#	csg.set_polygon(gen_circle(0.1,2))
#	add_child(csg)

#	var path = $Path3D
#	var csg = $CSGPolygon3D
#	csg.set_path_node(path.get_path())

func gen_circle(r:float, res:int):
	var step = PI/2/res
	var points:PackedVector2Array
	
	var angle = 0
	for i in range(4*res):
		points.append(r*Vector2(cos(angle),sin(angle)))
		angle += step
		
	return points
