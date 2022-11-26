extends Node3D

# These should be about linearly, inversely, proportional
# About: circ_res = 20 - bake_interval * 100
@export var bake_interval = 0.2
@export var circ_res = 5

@export var padding = 0.00
@export var padding_slope = 0.1

var point_cloud = DebugDraw.new_point_cloud(Vector3.ZERO, 5, Color.GREEN)
var point_cloud2 = DebugDraw.new_point_cloud(Vector3.ZERO, 10, Color.RED)
var point_cloud3 = DebugDraw.new_point_cloud(Vector3.ZERO, 10, Color.ORANGE)
var labels = []
var color_arr = [Color.RED, Color.GREEN, Color.BLUE, Color.PURPLE, Color.YELLOW, Color.CYAN, Color.BLUE, Color.PURPLE, Color.PINK, Color.RED]
var line_segment = DebugDraw.new_line_seg(Vector3(0,0,-5),Color.RED)

var tim1 = Time.get_unix_time_from_system()
func _ready():
#	get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
	var curves = [$Path3D.get_curve(), $Path3D2.get_curve(), $Path3D3.get_curve(), $Path3D4.get_curve()]
	# Get vertecices ordered by branch and disc
	var data = generate_vertices(curves,0.5)
	generate_mesh(data)
	
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

func _process(delta):
	for l in labels:
		l.update() 

# Generate vertices from curves
# Return [arr,branches]
# branches: Array of discs on branch
# disc: vertex disc index to global index
# arr: Mesh array
func generate_vertices(curves,r):
	# Array mesh data
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	var verts = PackedVector3Array()
	var normals = PackedVector3Array()
	var index = 0
	var branches = []
	var entry_loop = PackedInt32Array() 
	
	for c in curves:
		c.set_bake_interval(bake_interval)
	
	var n_b = Vector3(0,1,0)
	var entry_norms = PackedVector3Array()
	# Loop through each curve
	for c_i1 in range(curves.size()):
		branches.append([])
		var s_pos1 = curves[c_i1].get_baked_points() # sphere points 1
		var prev1 = -n_b
		# Loop through each baked point on curve, i.e. each disc
		for s_i in range(s_pos1.size()):
			var n1 = (s_pos1[s_i] - prev1).normalized() # Normal of current disc
			# Padding formula
			var ang = n1.angle_to(Vector3.UP)
			var padd = padding + padding*padding_slope*s_i*ang*ang*ang
			
			prev1 = s_pos1[s_i] # Previous disc position, use to calc normal
			var p1 = gen_circle(s_pos1[s_i], r,n1,circ_res) # Points on current disc
			
			var use_point:Array[bool] = []
			# Initialise flag array
			for i in p1:
				use_point.append(true)
			
			var disc_points = []
			disc_points.resize(p1.size())
			
			# HACK Entry loop to edge loops, continues at bottom
			if c_i1 == 0 && s_i == 0: 
				for i in range(p1.size()):
					entry_loop = [] + p1
					entry_norms.append((p1[i]-s_pos1[s_i]).normalized())
			
			# Check, and flag, points on current disc against spheres on all other branches 
			for c_i2 in range(curves.size()):
				if c_i1 != c_i2:
					var s_pos2 = curves[c_i2].get_baked_points() # sphere points 2
					var s_i2 = min(s_i,s_pos2.size()-1)
					for p_i in range(p1.size()):
						if is_point_in_sphere(p1[p_i],s_pos2[s_i2],r+padd):
							use_point[p_i] = false
			
			# Add points to disc based checks
			for i in range(use_point.size()):
				# Flag array check
				if use_point[i]:
					verts.append(p1[i])
					normals.append((p1[i]-s_pos1[s_i]).normalized())
					disc_points[i] = index
					index += 1
			# Add disc to current branch
			branches[c_i1].append([disc_points, use_point])
	
	# HACK Entry loop finish
	for i in range(entry_loop.size()):
		verts.append(entry_loop[i])
		normals.append(entry_norms[i])
		entry_loop[i] = verts.size()-1
	
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	var tim2 = Time.get_unix_time_from_system()
	print("generate_vertices: " + str((tim2-tim1)*1000) + "ms")
#	point_cloud.set_cloud(verts)
#	point_cloud.construct()
#	print(entry_loop)
	return [arr, branches, entry_loop]


# Generate a mesh from the given curves
func generate_mesh(data):
	var tim1 = Time.get_unix_time_from_system()
	
	var arr = data[0]
	var branches = data[1]
	var edge_loops = []
	edge_loops.append(data[2])
	var indices:PackedInt32Array = []
	var mesh_inst = MeshInstance3D.new()
	var mesh = ArrayMesh.new()
	
	# Iterate adding vertices branch by branch creating strips from stacked discs
	for b_i in range(branches.size()):
		edge_loops.append(PackedInt32Array())
		for d_i in range(branches[b_i].size()-1):
			# Identify edge loops
			for i in range(branches[b_i][d_i][1].size()):
				if branches[b_i][d_i][1][i]:
					var i_next = i + 1
					# Wrap for overflow
					if i == branches[b_i][d_i][1].size()-1:
						i_next = 0
					# Main mesh
					if (branches[b_i][d_i][1][i_next]):
						# Triangle 1
						indices.append(branches[b_i][d_i][0][i])
						indices.append(branches[b_i][d_i+1][0][i])
						indices.append(branches[b_i][d_i][0][i_next])
						# Triangle 2
						indices.append(branches[b_i][d_i][0][i_next])
						indices.append(branches[b_i][d_i+1][0][i])
						indices.append(branches[b_i][d_i+1][0][i_next])
					# Remove jagged edges by filling with triangle 
					if (branches[b_i][d_i-1][1][i] && branches[b_i][d_i][1][i-1] 
						&& branches[b_i][d_i][1][i_next]):
							if not branches[b_i][d_i-1][1][i_next]:
								indices.append(branches[b_i][d_i-1][0][i])
								indices.append(branches[b_i][d_i][0][i])
								indices.append(branches[b_i][d_i][0][i_next])
							if not branches[b_i][d_i-1][1][i-1]:
								indices.append(branches[b_i][d_i-1][0][i])
								indices.append(branches[b_i][d_i][0][i-1])
								indices.append(branches[b_i][d_i][0][i])
					# Edge loop
					elif (not branches[b_i][d_i-1][1][i] || 
						not branches[b_i][d_i][1][i_next] ||
						not branches[b_i][d_i][1][i-1] ||
						not branches[b_i][d_i+1][1][i]):
							edge_loops[b_i+1].append(branches[b_i][d_i][0][i])
	
	# Order loops
	var loops_ordered = []
	loops_ordered.resize(edge_loops.size())
	loops_ordered[0] = edge_loops[0]
	for l in range(edge_loops.size()-1):
		loops_ordered[l+1] = order_loop(edge_loops[l+1], arr)
	var l = loops_ordered[0]
	
	loops_ordered = merge_loops(loops_ordered, arr, indices)
	######## DEBUG #########
#	var debug_edge_loops = []
#	#	point_cloud2.add_points(arr[Mesh.ARRAY_VERTEX][edge_loops[0]])
#	debug_edge_loops.append(DebugDraw.new_line_seg(Vector3.ZERO, color_arr[0]))
#	for l_i in range(loops_ordered.size()):
#		debug_edge_loops.append(DebugDraw.new_line_seg(Vector3.ZERO, color_arr[l_i]))
#		for p_i in range(loops_ordered[l_i].size()):
#			var pos = arr[Mesh.ARRAY_VERTEX][loops_ordered[l_i][p_i]]
##			labels.append(DebugDraw.new_label(str(p_i),pos,$Camera))
#			point_cloud2.add_point(pos)
#			debug_edge_loops[-1].add_point(pos)
#		debug_edge_loops[-1].construct()
	########################
	
	# Mesh
	arr[Mesh.ARRAY_INDEX] = indices
	point_cloud.add_points(arr[Mesh.ARRAY_VERTEX])
#	point_cloud.construct()
	point_cloud2.construct()
#	point_cloud3.construct()
#	debug_line.construct()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arr)
	mesh_inst.set_mesh(mesh)
#	ResourceSaver.save("res://TestMesh.", mesh)
	add_child(mesh_inst)
	var tim2 = Time.get_unix_time_from_system()
	print("generate_mesh: " + str((tim2-tim1)*1000) + "ms")


func order_loop(loop, arr):
	var ordered_loop = PackedInt32Array()
	ordered_loop.resize(loop.size())
	ordered_loop[0] = loop[0]
	var c_i = 0 # Current point in unordered sequence
	var n_i = 0 # Next point to test against
	for i in range(loop.size()-1): # Current index of oredered sequence
		var short_dist = INF
		for comp_i in range(loop.size()):
			if comp_i != c_i:
				if loop[comp_i] != -1:
					var dist = arr[Mesh.ARRAY_VERTEX][loop[c_i]].distance_squared_to(arr[Mesh.ARRAY_VERTEX][loop[comp_i]])
					if dist < short_dist:
						short_dist = dist
						n_i = comp_i
		ordered_loop[i+1] = loop[n_i]
		loop[c_i] = -1
		c_i = n_i
		
	return ordered_loop


func merge_loops(loops, arr, indices):
	var merged_loops = [] + loops # Value copy
	
	# Merge flags for points
	var merge_flags = []
	merge_flags.resize(merged_loops.size())
	for i in range(merge_flags.size()):
		var blank = []
		blank.resize(merged_loops[i].size())
		blank.fill(false)
		merge_flags[i] = blank
	
	# Iterate existing loops 
	for l_i in range(5): 
		# Iterate points in loops
		for p_i in range(merged_loops[l_i].size()):
			if merge_flags[l_i][p_i]:
				continue
			var short = INF
			var sp_i = null
			var point_merged = false
			# Iterate through other loops
			for lc_i in range(merged_loops.size()-l_i-1):
				# Iterate points 
				for pc_i in range(merged_loops[lc_i+l_i+1].size()):
					# Compare points, check that it is not in current loop (because of merge)
					if merge_flags[lc_i+l_i+1][pc_i]:
						continue
					var dist = arr[Mesh.ARRAY_VERTEX][merged_loops[l_i][p_i]].distance_squared_to(arr[Mesh.ARRAY_VERTEX][merged_loops[lc_i+l_i+1][pc_i]]) + arr[Mesh.ARRAY_VERTEX][merged_loops[l_i][p_i-1]].distance_squared_to(arr[Mesh.ARRAY_VERTEX][merged_loops[lc_i+l_i+1][pc_i]])
					if dist < short && dist < 0.25:
						short = dist
						sp_i = [lc_i+l_i+1, pc_i]
			if sp_i != null:
				var merge_vert = (arr[Mesh.ARRAY_VERTEX][merged_loops[l_i][p_i]] - arr[Mesh.ARRAY_VERTEX][merged_loops[sp_i[0]][sp_i[1]]])/2 + arr[Mesh.ARRAY_VERTEX][merged_loops[sp_i[0]][sp_i[1]]]
				var merge_normal = (arr[Mesh.ARRAY_NORMAL][merged_loops[l_i][p_i]] + arr[Mesh.ARRAY_NORMAL][merged_loops[sp_i[0]][sp_i[1]]]).normalized()
				
				# Add merge point to array
				arr[Mesh.ARRAY_VERTEX].append(merge_vert)
				arr[Mesh.ARRAY_NORMAL].append(merge_normal)
				
				# Change reference to merge point
				Helpers.find_replace(indices, merged_loops[l_i][p_i], arr[Mesh.ARRAY_VERTEX].size()-1)
				Helpers.find_replace(indices, merged_loops[sp_i[0]][sp_i[1]], arr[Mesh.ARRAY_VERTEX].size()-1)
				merged_loops[l_i][p_i] = arr[Mesh.ARRAY_VERTEX].size()-1
				merged_loops[sp_i[0]][sp_i[1]] = arr[Mesh.ARRAY_VERTEX].size()-1
				# Set merge flags
				merge_flags[l_i][p_i] = true
				merge_flags[sp_i[0]][sp_i[1]] = true
	return merged_loops


func is_point_in_sphere(p_pos, s_pos, r):
	return (p_pos - s_pos).length() < r


func gen_circle(pos:Vector3, r:float, n:Vector3, res:int):
	var rot = 0
	var step = PI/2/res
	var points = []
	var point = (Vector3.UP).cross(n).cross(n)
	if (point == Vector3.ZERO): point = r*Vector3.FORWARD #will need info to align this correctly
	else: point *=  r/point.length()
	for i in range(4*res):
		points.append(point.rotated(n, rot)+pos)
		rot+=step
#	points.append(points[0]) #this is only necessary to complete the circle if points are used to generate lines
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
						var line_seg = DebugDraw.new_line_seg(Vector3(0,0,5),color_arr[c_i1])
						line_seg.set_points(line_points)
						line_seg.construct()
					elif use_point[i+1] == false:
						lines.append(line_points)
						var line_seg = DebugDraw.new_line_seg(Vector3(0,0,5),color_arr[c_i1])
						line_seg.set_points(line_points)
						line_seg.construct()
						line_points = []
	return lines
