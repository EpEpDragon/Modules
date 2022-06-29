extends Node3D

@export var bake_interval = 0.1
@export var padding = 0.00
var debug_draw

var circ_res = 10
var point_cloud = DebugDraw2.new_point_cloud(Vector3.ZERO, 5, Color.GREEN)
var point_cloud2 = DebugDraw2.new_point_cloud(Vector3.ZERO, 10, Color.RED)
var point_cloud3 = DebugDraw2.new_point_cloud(Vector3.ZERO, 10, Color.ORANGE)
var color_arr = [Color.RED, Color.GREEN, Color.BLUE, Color.CYAN, Color.ORANGE_RED]
var line_segment = DebugDraw2.new_line_seg(Vector3(0,0,-5),Color.RED)


func _ready():
#	get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
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
# Return [arr,branches]
# branches: Array of discs on branch
# disc: Dict, index on disc as key, vertex index as value
# arr: Mesh array
func generate_vertices(curves,r):
	# Array mesh data
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	var verts = PackedVector3Array()
	var normals = PackedVector3Array()
	var index = 0
	var branches = []
	var entry_loop = PackedVector3Array() 
	
	for c in curves:
		c.set_bake_interval(bake_interval)
	
	var n_b = Vector3(0,1,0)
	
	# Loop through each curve
	for c_i1 in range(curves.size()):
		branches.append([])
		var s_pos1 = curves[c_i1].get_baked_points() # sphere points 1
		var prev1 = -n_b
		# Loop through each baked point on curve, i.e. each disc
		for s_i in range(s_pos1.size()):
			var n1 = (s_pos1[s_i] - prev1).normalized() # Normal of current disc
			prev1 = s_pos1[s_i] # Previous disc position, use to calc normal
			var p1 = gen_circle(s_pos1[s_i], r,n1,circ_res) # Points on current disc
			# Add entry loop to edge loops
			if c_i1 == 0 && s_i == 0:
				entry_loop = p1
				
			var use_point:Array[bool] = []
			# Initialise flag array
			for i in p1:
				use_point.append(true)
				
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
					verts.append(p1[i])
					normals.append((p1[i]-s_pos1[s_i]).normalized())
					disc_points[i] = index
					index += 1
				else:
					if c_i1 == 0:
						point_cloud3.add_point(p1[i])
			# Add disc to current branch
			branches[c_i1].append([disc_points, use_point])
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	return [arr, branches, entry_loop]


# Generate a mesh from the given curves
func generate_mesh(curves):
	# Get vertecices ordered by branch and disc
	var data = generate_vertices(curves,0.5)
	var arr = data[0]
	var branches = data[1]
	var edge_loops = []
	edge_loops.append(data[2])
	var indices:PackedInt32Array = []
	var mesh_inst = MeshInstance3D.new()
	var mesh = ArrayMesh.new()
	
	# Iterate adding vertices branch by branch creating strips from stacked discs
	for b_i in range(branches.size()):
		edge_loops.append(PackedVector3Array())
		for d_i in range(branches[b_i].size()-1):
			var keys = branches[b_i][d_i][0].keys()
			# Identify edge loops
			for i in range(branches[b_i][d_i][1].size()-1):
				if branches[b_i][d_i][1][i] == true:
					if (branches[b_i][d_i-1][1][i] == false || 
					branches[b_i][d_i-1][1][i+1] == false ||
					branches[b_i][d_i-1][1][i-1] == false ||
					branches[b_i][d_i][1][i+1] == false ||
					branches[b_i][d_i][1][i-1] == false ||
					branches[b_i][d_i+1][1][i] == false || 
					branches[b_i][d_i+1][1][i+1] == false ||
					branches[b_i][d_i+1][1][i-1] == false):
						edge_loops[b_i].append(arr[Mesh.ARRAY_VERTEX][branches[b_i][d_i][0][i]])
			
			if keys.size() > 1:
				for k_i in range(keys.size()-1):
					# Only add when square possible
					if keys[k_i+1] - keys[k_i] <= 1:
						# Triangle 1
						indices.append(branches[b_i][d_i][0][keys[k_i]])
						indices.append(branches[b_i][d_i+1][0][keys[k_i]])
						indices.append(branches[b_i][d_i][0][keys[k_i+1]])
						# Triangle 2
						indices.append(branches[b_i][d_i][0][keys[k_i+1]])
						indices.append(branches[b_i][d_i+1][0][keys[k_i]])
						indices.append(branches[b_i][d_i+1][0][keys[k_i+1]])
	point_cloud2.add_points(edge_loops[0])
	point_cloud2.add_points(edge_loops[1])
	point_cloud2.add_points(edge_loops[2])
	point_cloud2.add_points(edge_loops[3])
	point_cloud2.add_points(edge_loops[4])
	arr[Mesh.ARRAY_INDEX] = indices
	point_cloud.add_points(arr[Mesh.ARRAY_VERTEX])
#	point_cloud.construct()
	point_cloud2.construct()
#	point_cloud3.construct()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arr)
	mesh_inst.mesh = mesh
	print("Surface count: " + str(mesh.get_surface_count()))
#	ResourceSaver.save("res://TestMesh.", mesh)
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
