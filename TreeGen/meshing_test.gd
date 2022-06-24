extends Node3D

var debug_draw
func _ready():
	debug_draw = $DebugDraw
	var curve = $Path3D.get_curve()
	var points = curve.get_baked_points()
	var p_prev = Vector3(0,-1,0)
	for p in points:
		var n = (p - p_prev).normalized()
		p_prev = p
		debug_draw.add_packed(gen_circle(p, 0.1, n,5))
		

func gen_circle(pos:Vector3, r:float, n:Vector3, res:int):
	var phi = atan2(n.y,n.x)
	var theta = atan2(sqrt(n.x*n.x + n.y*n.y) ,n.z)
	var step = PI/2/res
	var points:PackedVector3Array
	
	var rot = 0
	for i in range(4*res):
		var x = pos.x - r*(cos(rot)*sin(phi) + sin(rot)*cos(theta)*cos(phi))
		var y = pos.y + r*(cos(rot)*cos(phi) - sin(rot)*cos(theta)*sin(phi))
		var z = pos.z + r*sin(rot)*sin(theta)
		points.append(Vector3(x,y,z))
		rot += step
	points.append(points[0])
	return points
