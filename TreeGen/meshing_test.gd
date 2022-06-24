extends Node3D

var debug_draw
func _ready():
	debug_draw = $DebugDraw
	var curves = [$Path3D.get_curve(), $Path3D2.get_curve()]
	var r1 = 0.1
	var n_b = Vector3(0,1,0)
	for c1 in range(curves.size()-1):
		var points1 = curves[c1].get_baked_points()
		debug_draw.add_packed(gen_circle(points1[0], r1, n_b,5))
		for c2 in range(curves.size()-1):
			var points2 = curves[c2+1+c1].get_baked_points()
			var prev1 = -n_b
			var prev2 = -n_b
			for p in range(points1.size()-1):
				var n1 = (points1[p] - prev1).normalized()
				var n2 = (points2[p] - prev2).normalized()
				prev1 = points1[p]
				prev2 = points2[p]
				if is_touching(n_b,points1[p],points2[p],n1,n2,r1,r1):
					print(str(p) + ": touch")
				else:
					debug_draw.add_packed(gen_circle(points1[p], r1, n1,5))
					debug_draw.add_packed(gen_circle(points2[p], r1, n2,5))
					print(str(p) + ": no_touch")
					break


func is_touching(n_b, p1, p2, n1, n2, r1, r2):
	var S = p1.distance_to(p2)
	var alpha1 = PI/2 - n2.angle_to(n_b)
	var alpha2 = PI/2 - n1.angle_to(n_b)
	var x = r1*sin(alpha1)
	var y = r2*sin(alpha2)
	
	return x + y >= S
	
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
