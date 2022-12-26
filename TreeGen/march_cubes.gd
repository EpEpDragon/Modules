extends Node3D

# These should be about linearlyinverselyproportional
# About: circ_res = 20 - bake_interval * 100

@export var size := Vector3(5,5,5)
var cell_size := 0.05
var cloud_size := size/cell_size
var point_cloud = DebugDraw.new_point_cloud(Vector3.ZERO, 5, Color.GREEN)
var point_cloud2 = DebugDraw.new_point_cloud(Vector3.ZERO, 20, Color.RED)
var chunk_size = 4

var bake_interval = cell_size/2.0
var circ_res = int(0.4/bake_interval)
var radius = 0.2

var tim_start = Time.get_unix_time_from_system()
var tim_prev = tim_start

var baked_points = PackedVector3Array()

func _ready():
	print("Bake interval: " + str(bake_interval))
	print("Circ res: " + str(circ_res))
	print("\nTIMING")
#	,$Path3D2.get_curve(), $Path3D3.get_curve(), $Path3D4.get_curve(), $Path3D5.get_curve(),$Path3D6.get_curve(),$Path3D7.get_curve()
	var curves:Array[Curve3D] = [$Path3D.get_curve(),$Path3D2.get_curve(), $Path3D3.get_curve(), $Path3D4.get_curve(), $Path3D5.get_curve(),$Path3D6.get_curve(),$Path3D7.get_curve()]
	
	# Construct array of baked points to pass to GPU
	baked_points.append(Vector3(0,1,0))
	for c in curves:
		c.bake_interval = bake_interval
		baked_points.append_array(c.get_baked_points())
		
	run_cumpte_shaders()
	point_cloud.construct()
#	point_cloud2.construct()

# Create blank grid
func generate_grid(size:Vector3):
	var grid = []
	for x in range(size.x):
		grid.append([])
		for y in range(size.y):
			grid[x].append([])
			for z in range(size.z):
				grid[x][y].append([false, Vector3.ZERO])
	# TIMING
	print("Generate grid: " + str(( Time.get_unix_time_from_system()-tim_prev)*1000))
	tim_prev = Time.get_unix_time_from_system()
	return grid


func fill_grid(grid, curves:Array[Curve3D]):
	var prev_p = Vector3(0,1,0)
	var norm
	var norm_prev
	for c in curves:
		c.set_bake_interval(bake_interval)
		var points = c.get_baked_points()
		for p in points:
			norm = (p-prev_p).normalized()
			# Required for curve connection cases
			# Offset to center of grid
			if !norm.is_normalized():
				norm = norm_prev
			prev_p = p
			norm_prev = norm
			# Calc points on disc, brute force
			p += Vector3(size.x,0,size.z)/2
			var c_data = Helpers.gen_disc(p, radius, norm, circ_res)
			for c_d in range(c_data[0].size()):
				# Snap to grid, fill
				grid[int(c_data[0][c_d].x/cell_size)][int(c_data[0][c_d].y/cell_size)][int(c_data[0][c_d].z/cell_size)][0] = true
				grid[int(c_data[0][c_d].x/cell_size)][int(c_data[0][c_d].y/cell_size)][int(c_data[0][c_d].z/cell_size)][1] = ((grid[int(c_data[0][c_d].x/cell_size)][int(c_data[0][c_d].y/cell_size)][int(c_data[0][c_d].z/cell_size)][1] + c_data[1][c_d])/2).normalized()
	# TIMING
	print("Fill grid: " + str((Time.get_unix_time_from_system()-tim_prev)*1000))
	tim_prev = Time.get_unix_time_from_system()


func marching_cubes(grid):
	var size_x = grid.size()
	var size_y = grid[0].size()
	var size_z = grid[0][0].size()
	
	var mesh_inst = MeshInstance3D.new()
	var mesh = ArrayMesh.new()
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	arr[Mesh.ARRAY_NORMAL] = PackedVector3Array()
#	arr[Mesh.ARRAY_INDEX] = PackedInt32Array()
	
	var map = 0
	var index = 0
	for x in range(size_x-1):
		for y in range(size_y-1):
			for z in range(size_z-1):
				# Build binary neigbour map 
				map = 0
				if grid[x][y][z][0]: map += 1
				if grid[x+1][y][z][0]: map += 2
				if grid[x+1][y][z+1][0]: map += 4
				if grid[x][y][z+1][0]: map += 8
				
				if grid[x][y+1][z][0]: map += 16
				if grid[x+1][y+1][z][0]: map += 32
				if grid[x+1][y+1][z+1][0]: map += 64
				if grid[x][y+1][z+1][0]: map += 128
				# HACK Should actually change tir_table order instead of reverse iteration... but lazy
				for e in range(tri_table[map].size()-1,-1,-1):
					# Find vertices to make triangles
					var indA = edge_table[tri_table[map][e]][0]
					var indB = edge_table[tri_table[map][e]][1]
					arr[Mesh.ARRAY_VERTEX].append(((Vector3(x,y,z) + indA + Vector3(x,y,z) + indB)- Vector3(size_x,0,size_z))*cell_size/2 )
					arr[Mesh.ARRAY_NORMAL].append(((grid[x+indA.x][y+indA.y][z+indA.z][1] + grid[x+indB.x][y+indB.y][z+indB.z][1])/2).normalized())
#					arr[Mesh.ARRAY_INDEX].append(index)
					index += 1
					# Calc surface normal when triangle finished
					# TODO change to vertex normals for smoother finish
#					if index % 3 == 0:
#						var face_normal = (arr[Mesh.ARRAY_VERTEX][-1]-arr[Mesh.ARRAY_VERTEX][-3]).cross(arr[Mesh.ARRAY_VERTEX][-2]-arr[Mesh.ARRAY_VERTEX][-3]).normalized()
#						arr[Mesh.ARRAY_NORMAL].append(face_normal)
#						arr[Mesh.ARRAY_NORMAL].append(face_normal)
#						arr[Mesh.ARRAY_NORMAL].append(face_normal)
	# TIMING
	print("Marching cubes: " + str((Time.get_unix_time_from_system()-tim_prev)*1000))
	tim_prev = Time.get_unix_time_from_system()
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arr)
	mesh_inst.set_mesh(mesh)
	add_child(mesh_inst)
	# TIMING
	print("Draw: " + str((Time.get_unix_time_from_system() - tim_prev)*1000))
	tim_prev = Time.get_unix_time_from_system()
	print(arr[Mesh.ARRAY_VERTEX].size())


########### COMPUTE #############

# Create blank grid
func generate_grid_compute(size:Vector3):
	var grid = PackedInt32Array()
	for x in range(size.x):
		for y in range(size.y):
			for z in range(size.z):
				grid.append(0)
	# TIMING
	print("Generate grid: " + str((Time.get_unix_time_from_system() - tim_prev)))
	tim_prev = Time.get_unix_time_from_system()
	return grid


func fill_grid_compute(grid, curves:Array[Curve3D]):
	var prev_p = Vector3(0,1,0)
	var norm
	var norm_prev
	for c in curves:
		c.set_bake_interval(bake_interval)
		var points = c.get_baked_points()
		for p in points:
			norm = (p-prev_p).normalized()
			# Required for curve connection cases
			if !norm.is_normalized():
				norm = norm_prev
			prev_p = p
			norm_prev = norm
			# Offset to center of grid
			p += Vector3(size.x,0,size.z)/2
			# Calc points on disc, brute force
			var c_data = Helpers.gen_disc(p, radius, norm, circ_res)
			for c_d in range(c_data[0].size()):
				# Snap to grid, fill
				var x = int(c_data[0][c_d].x/cell_size)
				var y = int(c_data[0][c_d].y/cell_size)
				var z = int(c_data[0][c_d].z/cell_size)
				grid[cloud_size.x*cloud_size.y*z + cloud_size.x*y + x] = 1
#				grid[int(c_data[0][c_d].x/cell_size)][int(c_data[0][c_d].y/cell_size)][int(c_data[0][c_d].z/cell_size)][1] = ((grid[int(c_data[0][c_d].x/cell_size)][int(c_data[0][c_d].y/cell_size)][int(c_data[0][c_d].z/cell_size)][1] + c_data[1][c_d])/2).normalized()
	# TIMING
	print("Fill grid: " + str((Time.get_unix_time_from_system() - tim_prev)*1000))
	tim_prev = Time.get_unix_time_from_system()


func run_cumpte_shaders():
	var rd := RenderingServer.create_local_rendering_device()
	
	# SDF pipeline
	var shader_file := load("res://sdl_compute.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	var sdf_shader := rd.shader_create_from_spirv(shader_spirv)
	var sdf_pipe := rd.compute_pipeline_create(sdf_shader)

	# Cubes pipeline
	shader_file = load("res://cubes_compute.glsl")
	shader_spirv = shader_file.get_spirv()
	var cubes_shader := rd.shader_create_from_spirv(shader_spirv)
	var cubes_pipe := rd.compute_pipeline_create(cubes_shader)
	
	###################### Buffers ##############################
	
	# Size buffer
	var size_input := PackedInt32Array([cloud_size.x, cloud_size.y, cloud_size.z])
	var size_bytes := size_input.to_byte_array()
	var size_buffer := rd.storage_buffer_create(size_bytes.size(), size_bytes)
	var size_uniform := RDUniform.new()
	size_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	size_uniform.binding = 0
	size_uniform.add_id(size_buffer)

	# Baked points buffer
	var b_points_bytes := baked_points.to_byte_array()
	var b_points_buffer := rd.storage_buffer_create(b_points_bytes.size(), b_points_bytes)
	var b_points_uniform := RDUniform.new()
	b_points_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	b_points_uniform.binding = 1
	b_points_uniform.add_id(b_points_buffer)
	
	# SDF buffer
#	var sdf := PackedFloat32Array([0,0,0, 0,0,0, 0,0,0,  0,0,0, 0,-1,0, 0,0,0,  0,0,0, 0,0,0, 0,0,0])
	var sdf := PackedFloat32Array()
	sdf.resize(cloud_size.x*cloud_size.y*cloud_size.z)
	var sdf_bytes := sdf.to_byte_array()
	var sdf_buffer := rd.storage_buffer_create(sdf_bytes.size(), sdf_bytes)
	var sdf_uniform := RDUniform.new()
	sdf_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	sdf_uniform.binding = 2
	sdf_uniform.add_id(sdf_buffer)
	
	# Vertex buffer
	var vertices := PackedVector3Array()
	vertices.resize(cloud_size.x*cloud_size.y*cloud_size.z*15)
	vertices.fill(Vector3(0,0,0))
	var vertices_bytes := vertices.to_byte_array()
	var vertex_buffer := rd.storage_buffer_create(vertices_bytes.size(), vertices_bytes)
	var vertex_uniform := RDUniform.new()
	vertex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	vertex_uniform.binding = 3
	vertex_uniform.add_id(vertex_buffer)

	# Normal buffer
	var normals := PackedVector3Array()
	normals.resize(cloud_size.x*cloud_size.y*cloud_size.z*15)
	var normals_bytes := vertices.to_byte_array()
	var normal_buffer := rd.storage_buffer_create(normals_bytes.size(), normals_bytes)
	var normal_uniform := RDUniform.new()
	normal_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	normal_uniform.binding = 4
	normal_uniform.add_id(normal_buffer)
	
	var sdf_set := rd.uniform_set_create([size_uniform, b_points_uniform, sdf_uniform], sdf_shader, 0)
	var cubes_set := rd.uniform_set_create([size_uniform, sdf_uniform, vertex_uniform, normal_uniform], cubes_shader, 0)
	############################################################
	
	# SDF compute pipeline
	var sdf_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(sdf_list, sdf_pipe)
	rd.compute_list_bind_uniform_set(sdf_list, sdf_set, 0)
	rd.compute_list_dispatch(sdf_list, int(cloud_size.x/chunk_size), int(cloud_size.y/chunk_size), int(cloud_size.z/chunk_size))
	rd.compute_list_end()

	# Run SDF
	tim_prev = Time.get_unix_time_from_system()
	rd.submit()
	rd.sync()
	# TIMING
	print("SDF build: " + str((Time.get_unix_time_from_system() - tim_prev)*1000))
	tim_prev = Time.get_unix_time_from_system()

#	sdf_bytes = rd.buffer_get_data(sdf_buffer)
#	sdf = sdf_bytes.to_float32_array()
#
#	# TIMING
#	print("Pull: " + str((Time.get_unix_time_from_system() - tim_prev)*1000))
#	tim_prev = Time.get_unix_time_from_system()

#	var temp = []
#	for i in range(sdf.size()):
##		temp.append(sdf[i])
#		if sdf[i] <= 0:
#			var point = Vector3(i % int(cloud_size.x), int(i / cloud_size.x) % int(cloud_size.y), i / int(cloud_size.x * cloud_size.y))
#			point_cloud.add_point(point*cell_size-Vector3(2.5,0,2.5))
#	point_cloud2.add_points(baked_points)
	
	# Cubes compute pipeline
	var cubes_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(cubes_list, cubes_pipe)
	rd.compute_list_bind_uniform_set(cubes_list, cubes_set, 0)
	rd.compute_list_dispatch(cubes_list, int(cloud_size.x/chunk_size), int(cloud_size.y/chunk_size), int(cloud_size.z/chunk_size))
	rd.compute_list_end()

	# Run Cubes
	rd.submit()
	rd.sync()
	# TIMING
	print("Marching cubes: " + str((Time.get_unix_time_from_system() - tim_prev)*1000))
	tim_prev = Time.get_unix_time_from_system()
	
	# Read back the data from the buffer
	vertices_bytes = rd.buffer_get_data(vertex_buffer)
	normals_bytes = rd.buffer_get_data(normal_buffer)
	
	# TIMING
	print("Pull data: " + str((Time.get_unix_time_from_system() - tim_prev)*1000))
	tim_prev = Time.get_unix_time_from_system()
	
	var out_vertices := vertices_bytes.to_float32_array()
	var out_normals = normals_bytes.to_float32_array()
	var temp := PackedVector3Array()
	var temp2 := PackedVector3Array()
	for i in range(0,out_vertices.size(),3):
		if Vector3(out_vertices[i],out_vertices[i+1],out_vertices[i+2]) != Vector3(0,0,0):
			temp.append(Vector3(out_vertices[i],out_vertices[i+1],out_vertices[i+2]))
			temp2.append(Vector3(out_normals[i],out_normals[i+1],out_normals[i+2]))
#	temp = PackedVector3Array(Array(out_vertices))
#	temp2 = PackedVector3Array(Array(out_normals))
	# TIMING
	print("Clean data: " + str((Time.get_unix_time_from_system() - tim_prev)*1000))
	
	var mesh_inst = MeshInstance3D.new()
	var mesh = ArrayMesh.new()
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = temp
	arr[Mesh.ARRAY_NORMAL] = temp2
	
	tim_prev = Time.get_unix_time_from_system()

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arr)
	mesh_inst.set_mesh(mesh)
	add_child(mesh_inst)
	# TIMING
	print("Draw: " + str((Time.get_unix_time_from_system() - tim_prev)*1000))
	tim_prev = Time.get_unix_time_from_system()
	print(arr[Mesh.ARRAY_VERTEX].size())
	

var edge_table = (
	[[Vector3(0,0,0), Vector3(1,0,0)], # 0
	[Vector3(1,0,0), Vector3(1,0,1)],  # 1 
	[Vector3(1,0,1), Vector3(0,0,1)],  # 2
	[Vector3(0,0,1), Vector3(0,0,0)],  # 3
	[Vector3(0,1,0), Vector3(1,1,0)],  # 4
	[Vector3(1,1,0), Vector3(1,1,1)],  # 5
	[Vector3(1,1,1), Vector3(0,1,1)],  # 6
	[Vector3(0,1,1), Vector3(0,1,0)],  # 7
	[Vector3(0,0,0), Vector3(0,1,0)],  # 8
	[Vector3(1,0,0), Vector3(1,1,0)],  # 9
	[Vector3(1,0,1), Vector3(1,1,1)],  # 10
	[Vector3(0,0,1), Vector3(0,1,1)]]  # 11
	)
var tri_table = (
	[[],
	[0, 8, 3],
	[0, 1, 9],
	[1, 8, 3, 9, 8, 1],
	[1, 2, 10],
	[0, 8, 3, 1, 2, 10],
	[9, 2, 10, 0, 2, 9],
	[2, 8, 3, 2, 10, 8, 10, 9, 8],
	[3, 11, 2],
	[0, 11, 2, 8, 11, 0],
	[1, 9, 0, 2, 3, 11],
	[1, 11, 2, 1, 9, 11, 9, 8, 11],
	[3, 10, 1, 11, 10, 3],
	[0, 10, 1, 0, 8, 10, 8, 11, 10],
	[3, 9, 0, 3, 11, 9, 11, 10, 9],
	[9, 8, 10, 10, 8, 11],
	[4, 7, 8],
	[4, 3, 0, 7, 3, 4],
	[0, 1, 9, 8, 4, 7],
	[4, 1, 9, 4, 7, 1, 7, 3, 1],
	[1, 2, 10, 8, 4, 7],
	[3, 4, 7, 3, 0, 4, 1, 2, 10],
	[9, 2, 10, 9, 0, 2, 8, 4, 7],
	[2, 10, 9, 2, 9, 7, 2, 7, 3, 7, 9, 4],
	[8, 4, 7, 3, 11, 2],
	[11, 4, 7, 11, 2, 4, 2, 0, 4],
	[9, 0, 1, 8, 4, 7, 2, 3, 11],
	[4, 7, 11, 9, 4, 11, 9, 11, 2, 9, 2, 1],
	[3, 10, 1, 3, 11, 10, 7, 8, 4],
	[1, 11, 10, 1, 4, 11, 1, 0, 4, 7, 11, 4],
	[4, 7, 8, 9, 0, 11, 9, 11, 10, 11, 0, 3],
	[4, 7, 11, 4, 11, 9, 9, 11, 10],
	[9, 5, 4],
	[9, 5, 4, 0, 8, 3],
	[0, 5, 4, 1, 5, 0],
	[8, 5, 4, 8, 3, 5, 3, 1, 5],
	[1, 2, 10, 9, 5, 4],
	[3, 0, 8, 1, 2, 10, 4, 9, 5],
	[5, 2, 10, 5, 4, 2, 4, 0, 2],
	[2, 10, 5, 3, 2, 5, 3, 5, 4, 3, 4, 8],
	[9, 5, 4, 2, 3, 11],
	[0, 11, 2, 0, 8, 11, 4, 9, 5],
	[0, 5, 4, 0, 1, 5, 2, 3, 11],
	[2, 1, 5, 2, 5, 8, 2, 8, 11, 4, 8, 5],
	[10, 3, 11, 10, 1, 3, 9, 5, 4],
	[4, 9, 5, 0, 8, 1, 8, 10, 1, 8, 11, 10],
	[5, 4, 0, 5, 0, 11, 5, 11, 10, 11, 0, 3],
	[5, 4, 8, 5, 8, 10, 10, 8, 11],
	[9, 7, 8, 5, 7, 9],
	[9, 3, 0, 9, 5, 3, 5, 7, 3],
	[0, 7, 8, 0, 1, 7, 1, 5, 7],
	[1, 5, 3, 3, 5, 7],
	[9, 7, 8, 9, 5, 7, 10, 1, 2],
	[10, 1, 2, 9, 5, 0, 5, 3, 0, 5, 7, 3],
	[8, 0, 2, 8, 2, 5, 8, 5, 7, 10, 5, 2],
	[2, 10, 5, 2, 5, 3, 3, 5, 7],
	[7, 9, 5, 7, 8, 9, 3, 11, 2],
	[9, 5, 7, 9, 7, 2, 9, 2, 0, 2, 7, 11],
	[2, 3, 11, 0, 1, 8, 1, 7, 8, 1, 5, 7],
	[11, 2, 1, 11, 1, 7, 7, 1, 5],
	[9, 5, 8, 8, 5, 7, 10, 1, 3, 10, 3, 11],
	[5, 7, 0, 5, 0, 9, 7, 11, 0, 1, 0, 10, 11, 10, 0],
	[11, 10, 0, 11, 0, 3, 10, 5, 0, 8, 0, 7, 5, 7, 0],
	[11, 10, 5, 7, 11, 5],
	[10, 6, 5],
	[0, 8, 3, 5, 10, 6],
	[9, 0, 1, 5, 10, 6],
	[1, 8, 3, 1, 9, 8, 5, 10, 6],
	[1, 6, 5, 2, 6, 1],
	[1, 6, 5, 1, 2, 6, 3, 0, 8],
	[9, 6, 5, 9, 0, 6, 0, 2, 6],
	[5, 9, 8, 5, 8, 2, 5, 2, 6, 3, 2, 8],
	[2, 3, 11, 10, 6, 5],
	[11, 0, 8, 11, 2, 0, 10, 6, 5],
	[0, 1, 9, 2, 3, 11, 5, 10, 6],
	[5, 10, 6, 1, 9, 2, 9, 11, 2, 9, 8, 11],
	[6, 3, 11, 6, 5, 3, 5, 1, 3],
	[0, 8, 11, 0, 11, 5, 0, 5, 1, 5, 11, 6],
	[3, 11, 6, 0, 3, 6, 0, 6, 5, 0, 5, 9],
	[6, 5, 9, 6, 9, 11, 11, 9, 8],
	[5, 10, 6, 4, 7, 8],
	[4, 3, 0, 4, 7, 3, 6, 5, 10],
	[1, 9, 0, 5, 10, 6, 8, 4, 7],
	[10, 6, 5, 1, 9, 7, 1, 7, 3, 7, 9, 4],
	[6, 1, 2, 6, 5, 1, 4, 7, 8],
	[1, 2, 5, 5, 2, 6, 3, 0, 4, 3, 4, 7],
	[8, 4, 7, 9, 0, 5, 0, 6, 5, 0, 2, 6],
	[7, 3, 9, 7, 9, 4, 3, 2, 9, 5, 9, 6, 2, 6, 9],
	[3, 11, 2, 7, 8, 4, 10, 6, 5],
	[5, 10, 6, 4, 7, 2, 4, 2, 0, 2, 7, 11],
	[0, 1, 9, 4, 7, 8, 2, 3, 11, 5, 10, 6],
	[9, 2, 1, 9, 11, 2, 9, 4, 11, 7, 11, 4, 5, 10, 6],
	[8, 4, 7, 3, 11, 5, 3, 5, 1, 5, 11, 6],
	[5, 1, 11, 5, 11, 6, 1, 0, 11, 7, 11, 4, 0, 4, 11],
	[0, 5, 9, 0, 6, 5, 0, 3, 6, 11, 6, 3, 8, 4, 7],
	[6, 5, 9, 6, 9, 11, 4, 7, 9, 7, 11, 9],
	[10, 4, 9, 6, 4, 10],
	[4, 10, 6, 4, 9, 10, 0, 8, 3],
	[10, 0, 1, 10, 6, 0, 6, 4, 0],
	[8, 3, 1, 8, 1, 6, 8, 6, 4, 6, 1, 10],
	[1, 4, 9, 1, 2, 4, 2, 6, 4],
	[3, 0, 8, 1, 2, 9, 2, 4, 9, 2, 6, 4],
	[0, 2, 4, 4, 2, 6],
	[8, 3, 2, 8, 2, 4, 4, 2, 6],
	[10, 4, 9, 10, 6, 4, 11, 2, 3],
	[0, 8, 2, 2, 8, 11, 4, 9, 10, 4, 10, 6],
	[3, 11, 2, 0, 1, 6, 0, 6, 4, 6, 1, 10],
	[6, 4, 1, 6, 1, 10, 4, 8, 1, 2, 1, 11, 8, 11, 1],
	[9, 6, 4, 9, 3, 6, 9, 1, 3, 11, 6, 3],
	[8, 11, 1, 8, 1, 0, 11, 6, 1, 9, 1, 4, 6, 4, 1],
	[3, 11, 6, 3, 6, 0, 0, 6, 4],
	[6, 4, 8, 11, 6, 8],
	[7, 10, 6, 7, 8, 10, 8, 9, 10],
	[0, 7, 3, 0, 10, 7, 0, 9, 10, 6, 7, 10],
	[10, 6, 7, 1, 10, 7, 1, 7, 8, 1, 8, 0],
	[10, 6, 7, 10, 7, 1, 1, 7, 3],
	[1, 2, 6, 1, 6, 8, 1, 8, 9, 8, 6, 7],
	[2, 6, 9, 2, 9, 1, 6, 7, 9, 0, 9, 3, 7, 3, 9],
	[7, 8, 0, 7, 0, 6, 6, 0, 2],
	[7, 3, 2, 6, 7, 2],
	[2, 3, 11, 10, 6, 8, 10, 8, 9, 8, 6, 7],
	[2, 0, 7, 2, 7, 11, 0, 9, 7, 6, 7, 10, 9, 10, 7],
	[1, 8, 0, 1, 7, 8, 1, 10, 7, 6, 7, 10, 2, 3, 11],
	[11, 2, 1, 11, 1, 7, 10, 6, 1, 6, 7, 1],
	[8, 9, 6, 8, 6, 7, 9, 1, 6, 11, 6, 3, 1, 3, 6],
	[0, 9, 1, 11, 6, 7],
	[7, 8, 0, 7, 0, 6, 3, 11, 0, 11, 6, 0],
	[7, 11, 6],
	[7, 6, 11],
	[3, 0, 8, 11, 7, 6],
	[0, 1, 9, 11, 7, 6],
	[8, 1, 9, 8, 3, 1, 11, 7, 6],
	[10, 1, 2, 6, 11, 7],
	[1, 2, 10, 3, 0, 8, 6, 11, 7],
	[2, 9, 0, 2, 10, 9, 6, 11, 7],
	[6, 11, 7, 2, 10, 3, 10, 8, 3, 10, 9, 8],
	[7, 2, 3, 6, 2, 7],
	[7, 0, 8, 7, 6, 0, 6, 2, 0],
	[2, 7, 6, 2, 3, 7, 0, 1, 9],
	[1, 6, 2, 1, 8, 6, 1, 9, 8, 8, 7, 6],
	[10, 7, 6, 10, 1, 7, 1, 3, 7],
	[10, 7, 6, 1, 7, 10, 1, 8, 7, 1, 0, 8],
	[0, 3, 7, 0, 7, 10, 0, 10, 9, 6, 10, 7],
	[7, 6, 10, 7, 10, 8, 8, 10, 9],
	[6, 8, 4, 11, 8, 6],
	[3, 6, 11, 3, 0, 6, 0, 4, 6],
	[8, 6, 11, 8, 4, 6, 9, 0, 1],
	[9, 4, 6, 9, 6, 3, 9, 3, 1, 11, 3, 6],
	[6, 8, 4, 6, 11, 8, 2, 10, 1],
	[1, 2, 10, 3, 0, 11, 0, 6, 11, 0, 4, 6],
	[4, 11, 8, 4, 6, 11, 0, 2, 9, 2, 10, 9],
	[10, 9, 3, 10, 3, 2, 9, 4, 3, 11, 3, 6, 4, 6, 3],
	[8, 2, 3, 8, 4, 2, 4, 6, 2],
	[0, 4, 2, 4, 6, 2],
	[1, 9, 0, 2, 3, 4, 2, 4, 6, 4, 3, 8],
	[1, 9, 4, 1, 4, 2, 2, 4, 6],
	[8, 1, 3, 8, 6, 1, 8, 4, 6, 6, 10, 1],
	[10, 1, 0, 10, 0, 6, 6, 0, 4],
	[4, 6, 3, 4, 3, 8, 6, 10, 3, 0, 3, 9, 10, 9, 3],
	[10, 9, 4, 6, 10, 4],
	[4, 9, 5, 7, 6, 11],
	[0, 8, 3, 4, 9, 5, 11, 7, 6],
	[5, 0, 1, 5, 4, 0, 7, 6, 11],
	[11, 7, 6, 8, 3, 4, 3, 5, 4, 3, 1, 5],
	[9, 5, 4, 10, 1, 2, 7, 6, 11],
	[6, 11, 7, 1, 2, 10, 0, 8, 3, 4, 9, 5],
	[7, 6, 11, 5, 4, 10, 4, 2, 10, 4, 0, 2],
	[3, 4, 8, 3, 5, 4, 3, 2, 5, 10, 5, 2, 11, 7, 6],
	[7, 2, 3, 7, 6, 2, 5, 4, 9],
	[9, 5, 4, 0, 8, 6, 0, 6, 2, 6, 8, 7],
	[3, 6, 2, 3, 7, 6, 1, 5, 0, 5, 4, 0],
	[6, 2, 8, 6, 8, 7, 2, 1, 8, 4, 8, 5, 1, 5, 8],
	[9, 5, 4, 10, 1, 6, 1, 7, 6, 1, 3, 7],
	[1, 6, 10, 1, 7, 6, 1, 0, 7, 8, 7, 0, 9, 5, 4],
	[4, 0, 10, 4, 10, 5, 0, 3, 10, 6, 10, 7, 3, 7, 10],
	[7, 6, 10, 7, 10, 8, 5, 4, 10, 4, 8, 10],
	[6, 9, 5, 6, 11, 9, 11, 8, 9],
	[3, 6, 11, 0, 6, 3, 0, 5, 6, 0, 9, 5],
	[0, 11, 8, 0, 5, 11, 0, 1, 5, 5, 6, 11],
	[6, 11, 3, 6, 3, 5, 5, 3, 1],
	[1, 2, 10, 9, 5, 11, 9, 11, 8, 11, 5, 6],
	[0, 11, 3, 0, 6, 11, 0, 9, 6, 5, 6, 9, 1, 2, 10],
	[11, 8, 5, 11, 5, 6, 8, 0, 5, 10, 5, 2, 0, 2, 5],
	[6, 11, 3, 6, 3, 5, 2, 10, 3, 10, 5, 3],
	[5, 8, 9, 5, 2, 8, 5, 6, 2, 3, 8, 2],
	[9, 5, 6, 9, 6, 0, 0, 6, 2],
	[1, 5, 8, 1, 8, 0, 5, 6, 8, 3, 8, 2, 6, 2, 8],
	[1, 5, 6, 2, 1, 6],
	[1, 3, 6, 1, 6, 10, 3, 8, 6, 5, 6, 9, 8, 9, 6],
	[10, 1, 0, 10, 0, 6, 9, 5, 0, 5, 6, 0],
	[0, 3, 8, 5, 6, 10],
	[10, 5, 6],
	[11, 5, 10, 7, 5, 11],
	[11, 5, 10, 11, 7, 5, 8, 3, 0],
	[5, 11, 7, 5, 10, 11, 1, 9, 0],
	[10, 7, 5, 10, 11, 7, 9, 8, 1, 8, 3, 1],
	[11, 1, 2, 11, 7, 1, 7, 5, 1],
	[0, 8, 3, 1, 2, 7, 1, 7, 5, 7, 2, 11],
	[9, 7, 5, 9, 2, 7, 9, 0, 2, 2, 11, 7],
	[7, 5, 2, 7, 2, 11, 5, 9, 2, 3, 2, 8, 9, 8, 2],
	[2, 5, 10, 2, 3, 5, 3, 7, 5],
	[8, 2, 0, 8, 5, 2, 8, 7, 5, 10, 2, 5],
	[9, 0, 1, 5, 10, 3, 5, 3, 7, 3, 10, 2],
	[9, 8, 2, 9, 2, 1, 8, 7, 2, 10, 2, 5, 7, 5, 2],
	[1, 3, 5, 3, 7, 5],
	[0, 8, 7, 0, 7, 1, 1, 7, 5],
	[9, 0, 3, 9, 3, 5, 5, 3, 7],
	[9, 8, 7, 5, 9, 7],
	[5, 8, 4, 5, 10, 8, 10, 11, 8],
	[5, 0, 4, 5, 11, 0, 5, 10, 11, 11, 3, 0],
	[0, 1, 9, 8, 4, 10, 8, 10, 11, 10, 4, 5],
	[10, 11, 4, 10, 4, 5, 11, 3, 4, 9, 4, 1, 3, 1, 4],
	[2, 5, 1, 2, 8, 5, 2, 11, 8, 4, 5, 8],
	[0, 4, 11, 0, 11, 3, 4, 5, 11, 2, 11, 1, 5, 1, 11],
	[0, 2, 5, 0, 5, 9, 2, 11, 5, 4, 5, 8, 11, 8, 5],
	[9, 4, 5, 2, 11, 3],
	[2, 5, 10, 3, 5, 2, 3, 4, 5, 3, 8, 4],
	[5, 10, 2, 5, 2, 4, 4, 2, 0],
	[3, 10, 2, 3, 5, 10, 3, 8, 5, 4, 5, 8, 0, 1, 9],
	[5, 10, 2, 5, 2, 4, 1, 9, 2, 9, 4, 2],
	[8, 4, 5, 8, 5, 3, 3, 5, 1],
	[0, 4, 5, 1, 0, 5],
	[8, 4, 5, 8, 5, 3, 9, 0, 5, 0, 3, 5],
	[9, 4, 5],
	[4, 11, 7, 4, 9, 11, 9, 10, 11],
	[0, 8, 3, 4, 9, 7, 9, 11, 7, 9, 10, 11],
	[1, 10, 11, 1, 11, 4, 1, 4, 0, 7, 4, 11],
	[3, 1, 4, 3, 4, 8, 1, 10, 4, 7, 4, 11, 10, 11, 4],
	[4, 11, 7, 9, 11, 4, 9, 2, 11, 9, 1, 2],
	[9, 7, 4, 9, 11, 7, 9, 1, 11, 2, 11, 1, 0, 8, 3],
	[11, 7, 4, 11, 4, 2, 2, 4, 0],
	[11, 7, 4, 11, 4, 2, 8, 3, 4, 3, 2, 4],
	[2, 9, 10, 2, 7, 9, 2, 3, 7, 7, 4, 9],
	[9, 10, 7, 9, 7, 4, 10, 2, 7, 8, 7, 0, 2, 0, 7],
	[3, 7, 10, 3, 10, 2, 7, 4, 10, 1, 10, 0, 4, 0, 10],
	[1, 10, 2, 8, 7, 4],
	[4, 9, 1, 4, 1, 7, 7, 1, 3],
	[4, 9, 1, 4, 1, 7, 0, 8, 1, 8, 7, 1],
	[4, 0, 3, 7, 4, 3],
	[4, 8, 7],
	[9, 10, 8, 10, 11, 8],
	[3, 0, 9, 3, 9, 11, 11, 9, 10],
	[0, 1, 10, 0, 10, 8, 8, 10, 11],
	[3, 1, 10, 11, 3, 10],
	[1, 2, 11, 1, 11, 9, 9, 11, 8],
	[3, 0, 9, 3, 9, 11, 1, 2, 9, 2, 11, 9],
	[0, 2, 11, 8, 0, 11],
	[3, 2, 11],
	[2, 3, 8, 2, 8, 10, 10, 8, 9],
	[9, 10, 2, 0, 9, 2],
	[2, 3, 8, 2, 8, 10, 0, 1, 8, 1, 10, 8],
	[1, 10, 2],
	[1, 3, 8, 9, 1, 8],
	[0, 9, 1],
	[0, 3, 8],
	[]])
