extends Node3D

@export var bake_interval = 0.01
@export var padding = 0.02
var debug_draw
var res = 5
var point_cloud = DebugDraw2.new_point_cloud(Vector3.ZERO, 5, Color.GREEN)


func _ready():
	var curves = [$Path3D.get_curve(), $Path3D2.get_curve(), $Path3D3.get_curve(), $Path3D4.get_curve()]
#	var portals = generate_portals(curves,0.1,0.1)
#	for p in portals:
#		if p != null:
#			point_cloud.add_point(gen_circle(p[0], p[1], p[2],res))
	point_cloud.set_cloud(generate_cloud(curves,0.5))
	point_cloud.construct()

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
#					pass
					point_cloud.add_point(gen_circle(points1[p1], r1, n1,res))
					point_cloud.add_point(gen_circle(points2[p2], r1, n2,res))
				else:
					
					if portals[c1+1] == null || portals[c1+1][3] < p1:
						portals[c1+1] = [points1[p1], r1, n1, p1]
					if portals[c2+2+c1] == null || portals[c2+2+c1][3] < p2:
						portals[c2+2+c1] = [points2[p2], r1, n2, p2]
#					point_cloud.add_point(gen_circle(points1[p1], r1, n1,res))
#					point_cloud.add_point(gen_circle(points2[p2], r1, n2,res))
					break
					
				
	return portals
	
func is_touching(n_b, p1, p2, n1, n2, r1, r2):
	var S = p1.distance_to(p2)
	var alpha1 = n1.angle_to(p2-p1) - PI/2
	var alpha2 = n2.angle_to(p1-p2) - PI/2
	var x = r1*cos(alpha1)
	var y = r2*cos(alpha2)
	
	return x + y >= S


func generate_cloud(curves,r):
	for c in curves:
		c.set_bake_interval(bake_interval)
	var cloud:PackedVector3Array
	var n_b = Vector3(0,1,0)
	for c_i1 in range(curves.size()):
		print(range(curves.size()))
		var s_pos1 = curves[c_i1].get_baked_points() # sphere points 1
		var prev1 = -n_b
		for s_i1 in range(s_pos1.size()):
			var n1 = (s_pos1[s_i1] - prev1).normalized()
			prev1 = s_pos1[s_i1]
			var p1 = gen_circle(s_pos1[s_i1], r,n1,res)
			var use_point = []
			for i in p1:
				use_point.push_back(true)
				
			for c_i2 in range(curves.size()):
				if c_i1 != c_i2:
					var s_pos2 = curves[c_i2].get_baked_points() # sphere points 2
					var s_i2 = min(s_i1,s_pos2.size()-1)
					for p_i in range(p1.size()):
						if is_point_in_sphere(p1[p_i],s_pos2[s_i2],r+padding):
							use_point[p_i] = false
			for i in range(use_point.size()):
				if use_point[i]:
					cloud.push_back(p1[i])
	return cloud

func is_point_in_sphere(p_pos, s_pos, r):
	return (p_pos - s_pos).length() < r


func gen_circle(pos:Vector3, r:float, n:Vector3, res:int):
	var rot = 0
	var step = PI/2/res
	var points:PackedVector3Array
	var point = (Vector3.UP).cross(n).cross(n)
	if (point == Vector3.ZERO): point = r*Vector3.FORWARD #will need info to align this correctly
	else: point *=  r/point.length()
	for i in range(4*res):
		points.append(point.rotated(n, rot)+pos)
		rot+=step
#	points.append(points[0]) #this is only necessary to complete the circle if points are used to generate lines
	return points
