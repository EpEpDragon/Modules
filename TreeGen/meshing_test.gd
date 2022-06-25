extends Node3D

@export var bake_interval = 0.1
var debug_draw

func _ready():
	debug_draw = $DebugDraw
	var curves = [$Path3D.get_curve(), $Path3D2.get_curve(),$Path3D3.get_curve(),$Path3D4.get_curve()]
	var portals = generate_portals(curves,0.1,0.1)
	for p in portals:
		if p != null:
			debug_draw.add_packed(gen_circle(p[0], p[1], p[2],4),Color.GREEN)

# Generates the tightest portals from given curves (Limited by bake interval)
# return portals : [point, radius, normal, point index on curve]
func generate_portals(curves,r1,r2):
	for c in curves:
			c.set_bake_interval(bake_interval)
		
	var n_b = Vector3(0,1,0)
	var portals = []
	portals.resize(curves.size()+1)
	
	portals[0] = [curves[0].get_baked_points()[0], r1, n_b, 0]
	
	for c1 in range(curves.size()-1):
		var points1 = curves[c1].get_baked_points()

		for c2 in range(curves.size()-1-c1):
			var points2 = curves[c2+1+c1].get_baked_points()
			var prev1 = -n_b
			var prev2 = -n_b
			for p1 in range(points1.size()):
				var p2 = min(p1,points2.size()-1)
				var n1 = (points1[p1] - prev1).normalized()
				var n2 = (points2[p2] - prev2).normalized()
				prev1 = points1[p1]
				prev2 = points2[p2]
				if is_touching(n_b,points1[p1],points2[p2],n1,n2,r1,r1):
					pass
#					debug_draw.add_packed(gen_circle(points1[p1], r1, n1,1), Color.RED)
#					debug_draw.add_packed(gen_circle(points2[p2], r1, n2,1), Color.RED)
				else:
					if portals[c1+1] == null || portals[c1+1][3] < p1:
						portals[c1+1] = [points1[p1], r1, n1, p1]
					if portals[c2+2+c1] == null || portals[c2+2+c1][3] < p2:
						portals[c2+2+c1] = [points2[p2], r1, n2, p2]
					break
	return portals
	
func is_touching(n_b, p1, p2, n1, n2, r1, r2):
	var S = p1.distance_to(p2)
	var alpha1 = n1.angle_to(p2-p1) - PI/2
	var alpha2 = n2.angle_to(p1-p2) - PI/2
	var x = r1*cos(alpha1)
	var y = r2*cos(alpha2)
	
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
