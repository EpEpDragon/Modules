extends Node3D

@export var bake_interval = 0.05
@export var padding = 0.00
var debug_draw

var circ_res = 100
var point_cloud = DebugDraw2.new_point_cloud(Vector3.ZERO, 2, Color.GREEN)
var color_arr = [Color.RED, Color.GREEN, Color.BLUE, Color.CYAN, Color.ORANGE_RED]
var line_segment = DebugDraw2.new_line_seg(Vector3(0,0,-5),Color.RED)


func _ready():
	var curves = [$Path3D.get_curve(), $Path3D2.get_curve(), $Path3D3.get_curve(), $Path3D4.get_curve()]
	generate_mesh(curves)
#	var portals = generate_portals(curves,0.1,0.1)
#	for p in portals:
#		if p != null:
#			point_cloud.add_point(gen_circle(p[0], p[1], p[2],res))
#	var cloud = generate_cloud(curves,0.5)
#	point_cloud.set_cloud(cloud)
#	point_cloud.construct()
#
#	line_segment.set_points(cloud)
#	line_segment.construct()
#
#	var lines = generate_line_segments(curves,0.5)
#	for l in lines:
#		var line_seg = DebugDraw2.new_line_seg(Vector3(-5,0,0),Color.YELLOW)
#		line_seg.set_points(l)
#		line_seg.construct()
	
#	var branches = generate_vertices(curves,0.5)
#	for b_i in range(branches.size()):
#		for disc in branches[b_i]:
#			var line_seg = DebugDraw2.new_line_seg(Vector3(0,0,0),color_arr[b_i])
#			var i_prev = disc.keys()[0]
#			for i in disc.keys():
#				if i - i_prev > 1:
#					line_seg.construct()
#					line_seg = DebugDraw2.new_line_seg(Vector3(0,0,0),color_arr[b_i])
#				line_seg.add_point(disc[i])
#				i_prev = i
#			line_seg.construct()



# Generate vertices from curves
# return branches, contains vertex data ordered per branch per disc
# Branches: Array of Discs on branch
# Disc: Dict with key as vertex index on disc and value as position in 3D space
func generate_vertices(curves,r):
	for c in curves:
		c.set_bake_interval(bake_interval)
	
	var branches = []
	var n_b = Vector3(0,1,0)
	# Loop through each curve
	for c_i1 in range(curves.size()):
		branches.push_back([])
		var s_pos1 = curves[c_i1].get_baked_points() # sphere points 1
		var prev1 = -n_b
		# Loop through each baked point on curve, i.e. each disc
		for s_i in range(s_pos1.size()):
			var n1 = (s_pos1[s_i] - prev1).normalized() # Normal of current disc
			prev1 = s_pos1[s_i] # Previous disc position, use to calc normal
			var p1 = gen_circle(s_pos1[s_i], r,n1,circ_res) # Points on current disc
			var use_point:Array[bool] = []
			# Initialise flag array
			for i in p1:
				use_point.push_back(true)
				
			# Check, and flag, points on current disc against spheres on all other branches 
			for c_i2 in range(curves.size()):
				if c_i1 != c_i2:
					var s_pos2 = curves[c_i2].get_baked_points() # sphere points 2
					var s_i2 = min(s_i,s_pos2.size()-1)
					for p_i in range(p1.size()):
						if is_point_in_sphere(p1[p_i],s_pos2[s_i2],r+padding):
							use_point[p_i] = false
			
			var disc_points = {} 
			# Add points to disc based checks
			for i in range(use_point.size()):
				# Flag array check
				if use_point[i]:
					# Polygon construction possible checks
					if i == 0:
						if use_point[i+1] == true:
							disc_points[i] = {"vertex":p1[i],"normal":p1[i]-s_pos1[s_i]}
					elif i == use_point.size()-1:
						if use_point[i-1] == true:
							disc_points[i] = {"vertex":p1[i],"normal":p1[i]-s_pos1[s_i]}
					elif use_point[i+1] == true || use_point[i-1] == true:
						disc_points[i] = {"vertex":p1[i],"normal":p1[i]-s_pos1[s_i]}
			# Add disc to current branch
			branches[c_i1].append(disc_points)
	return branches


# Generate a mesh from the given curves
func generate_mesh(curves):
	# Get vertecices ordered by branch and disc
	var branches = generate_vertices(curves,0.5)
	var mesh_inst = MeshInstance3D.new()
	var mesh_imm = ImmediateMesh.new()
	
	# Iterate adding vertices branch by branch creating strips from stacked discs
	for b_i in range(branches.size()):
		for d_i in range(branches[b_i].size()-1):
			var keys = branches[b_i][d_i].keys()
			if keys.size() > 1:
				mesh_imm.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
				for k_i in range(keys.size()):
					
					# When strip ends prematurley end current strip and start another
					if keys[k_i] - keys[k_i-1] > 1:
						mesh_imm.surface_end()
						mesh_imm.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
						
					# Connect current vertex to vertex in above disc
					mesh_imm.surface_set_normal(branches[b_i][d_i][keys[k_i]]["normal"])
					mesh_imm.surface_add_vertex(branches[b_i][d_i][keys[k_i]]["vertex"])
					mesh_imm.surface_set_normal(branches[b_i][d_i][keys[k_i]]["normal"])
					mesh_imm.surface_add_vertex(branches[b_i][d_i+1][keys[k_i]]["vertex"])
				mesh_imm.surface_end()
	mesh_inst.mesh = mesh_imm
	ResourceSaver.save("res://TestMesh.tres", mesh_imm)
	add_child(mesh_inst)


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

####################################### Debug use functions ###################################

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
