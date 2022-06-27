extends Node3D

@export var bake_interval = 0.1
@export var padding = 0.00
var debug_draw

var circ_res = 5
var point_cloud = DebugDraw2.new_point_cloud(Vector3.ZERO, 5, Color.GREEN)
var color_arr = [Color.CYAN, Color.BLUE_VIOLET, Color.RED, Color.GREEN, Color.ORANGE_RED]
var line_segment = DebugDraw2.new_line_seg(Vector3(0,0,-5),Color.RED)


func _ready():
	var curves = [$Path3D.get_curve(), $Path3D2.get_curve(), $Path3D3.get_curve(), $Path3D4.get_curve()]
#	var portals = generate_portals(curves,0.1,0.1)
#	for p in portals:
#		if p != null:
#			point_cloud.add_point(gen_circle(p[0], p[1], p[2],res))
	var cloud = generate_cloud(curves,0.5)
	point_cloud.set_cloud(cloud)
	point_cloud.construct()
#
#	line_segment.set_points(cloud)
#	line_segment.construct()
#
#	var lines = generate_line_segments(curves,0.5)
#	for l in lines:
#		var line_seg = DebugDraw2.new_line_seg(Vector3(-5,0,0),Color.YELLOW)
#		line_seg.set_points(l)
#		line_seg.construct()
	
	var branches = generate_vertices(curves,0.5)
#	print("branches: " + str(vertices.size()))
	for b_i in range(branches.size()):
		for disc in branches[b_i]:
#			print("discs: " + str(disc.size()))
			for line in disc:
				if line.size() > 0:
#					print("line: " + line.size())
					var line_seg = DebugDraw2.new_line_seg(Vector3(0,0,0),color_arr[b_i])
					line_seg.set_points(line[POS])
					line_seg.construct()

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
					point_cloud.add_point(gen_circle(points1[p1], r1, n1,circ_res))
					point_cloud.add_point(gen_circle(points2[p2], r1, n2,circ_res))
				else:
					
					if portals[c1+1] == null || portals[c1+1][3] < p1:
						portals[c1+1] = [points1[p1], r1, n1, p1]
					if portals[c2+2+c1] == null || portals[c2+2+c1][3] < p2:
						portals[c2+2+c1] = [points2[p2], r1, n2, p2]
#					point_cloud.add_point(gen_circle(points1[p1], r1, n1,circ_res))
#					point_cloud.add_point(gen_circle(points2[p2], r1, n2,circ_res))
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
	var cloud:PackedVector3Array = []
	var n_b = Vector3(0,1,0)
	for c_i1 in range(curves.size()):
		print(range(curves.size()))
		var s_pos1 = curves[c_i1].get_baked_points() # sphere points 1
		var prev1 = -n_b
		for s_i1 in range(s_pos1.size()):
			var n1 = (s_pos1[s_i1] - prev1).normalized()
			prev1 = s_pos1[s_i1]
			var p1 = gen_circle(s_pos1[s_i1], r,n1,circ_res)
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


func generate_line_segments(curves,r):
	for c in curves:
		c.set_bake_interval(bake_interval)
	var lines = []
	var n_b = Vector3(0,1,0)
	for c_i1 in range(curves.size()):
		var s_pos1 = curves[c_i1].get_baked_points() # sphere points 1
		var prev1 = -n_b
		for s_i1 in range(s_pos1.size()):
			var line_points = []
			var n1 = (s_pos1[s_i1] - prev1).normalized()
			prev1 = s_pos1[s_i1]
			var p1 = gen_circle(s_pos1[s_i1], r,n1,circ_res)
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
					line_points.push_back(p1[i])
					if i == use_point.size()-1 :
						lines.append(line_points)
						var line_seg = DebugDraw2.new_line_seg(Vector3(0,0,5),color_arr[c_i1])
						line_seg.set_points(line_points)
						line_seg.construct()
					elif use_point[i+1] == false:
						lines.append(line_points)
						var line_seg = DebugDraw2.new_line_seg(Vector3(0,0,5),color_arr[c_i1])
						line_seg.set_points(line_points)
						line_seg.construct()
						line_points = []
	return lines


enum {POS=0,DISC_INDEX=1} # Indices for lines
func generate_vertices(curves,r):
	for c in curves:
		c.set_bake_interval(bake_interval)
	
	var branches = []
	var lines = []
	
	var n_b = Vector3(0,1,0)
	for c_i1 in range(curves.size()):
		branches.push_back([])
		var s_pos1 = curves[c_i1].get_baked_points() # sphere points 1
		var prev1 = -n_b
		for s_i in range(s_pos1.size()):
#			print(discs)
			var line_points = [[],[]]
			var n1 = (s_pos1[s_i] - prev1).normalized()
			prev1 = s_pos1[s_i]
			var p1 = gen_circle(s_pos1[s_i], r,n1,circ_res)
			var use_point = []
			for i in p1:
				use_point.push_back(true)
				
			for c_i2 in range(curves.size()):
				if c_i1 != c_i2:
					var s_pos2 = curves[c_i2].get_baked_points() # sphere points 2
					var s_i2 = min(s_i,s_pos2.size()-1)
					for p_i in range(p1.size()):
						if is_point_in_sphere(p1[p_i],s_pos2[s_i2],r+padding):
							use_point[p_i] = false
				
			for i in range(use_point.size()):
				if use_point[i]:
					line_points[POS].push_back(p1[i])
					line_points[DISC_INDEX].push_back(i)
					if i == use_point.size()-1 :
#						print(str(s_i) + ": " + str(line_points))
						lines.append(line_points)
#						var line_seg = DebugDraw2.new_line_seg(Vector3(0,0,5),color_arr[c_i1])
#						line_seg.set_points(line_points)
#						line_seg.construct()
					elif use_point[i+1] == false:
						lines.append(line_points)
#						print(str(s_i) + ": " + str(line_points))
#						var line_seg = DebugDraw2.new_line_seg(Vector3(0,0,5),color_arr[c_i1])
#						line_seg.set_points(line_points)
#						line_seg.construct()
						line_points = [[],[]]
			if lines.size() > 0:
#				print(str(s_i) + ": " + str(lines))
				branches[c_i1].append(lines)
				lines = []
	print(branches[0].size())
	return branches


func generate_mesh(lines):
	var mesh_imm = ImmediateMesh.new()
	var mesh_inst = MeshInstance3D.new()
	
	for l_i in range(lines.size()-1):
		mesh_imm.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		mesh_imm.surface_set_normal(Vector3(0,0,1))
		for p_i in range(lines[l_i].size()):
			var p_i_next = min(p_i, lines[l_i+1].size()-1)
			mesh_imm.surface_add_vertex(lines[l_i][p_i])
			mesh_imm.surface_add_vertex(lines[l_i+1][p_i_next])
		mesh_imm.surface_end()


func is_point_in_sphere(p_pos, s_pos, r):
	return (p_pos - s_pos).length() < r


func gen_circle(pos:Vector3, r:float, n:Vector3, res:int):
	var rot = 0
	var step = PI/2/res
	var points:PackedVector3Array = []
	var point = (Vector3.UP).cross(n).cross(n)
	if (point == Vector3.ZERO): point = r*Vector3.FORWARD #will need info to align this correctly
	else: point *=  r/point.length()
	for i in range(4*res):
		points.append(point.rotated(n, rot)+pos)
		rot+=step
	points.append(points[0]) #this is only necessary to complete the circle if points are used to generate lines
	return points
