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

var baked_points = PackedFloat32Array()

func _ready():
	var input = PackedVector3Array([Vector3(10,5,7)])
	var bytes = input.to_byte_array()
	
	print("Bake interval: " + str(bake_interval))
	print("Circ res: " + str(circ_res))
	print("\nTIMING")
	var curves:Array[Curve3D] = [$Path3D.get_curve(),$Path3D2.get_curve(), $Path3D3.get_curve(), $Path3D4.get_curve(), $Path3D5.get_curve(),$Path3D6.get_curve(),$Path3D7.get_curve()]
	
	# Construct array of baked points to pass to GPU
#	baked_points.append_array([0,1,0,0])
	for c in curves.size():
		curves[c].bake_interval = bake_interval
		var points = curves[c].get_baked_points()
		baked_points.append_array([points[0].x, points[0].y, points[0].z, 0])
		baked_points.append_array([points[-1].x, points[-1].y, points[-1].z, 0])
		
	run_cumpte_shaders()
#	point_cloud.construct()
#	point_cloud2.construct()

########### COMPUTE #############

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
	
	# Normal buffer
	var number_of_vertices_bytes := PackedInt32Array([0]).to_byte_array()
	var number_of_vertices_buffer := rd.storage_buffer_create(number_of_vertices_bytes.size(), number_of_vertices_bytes)
	var number_of_vertices_uniform := RDUniform.new()
	number_of_vertices_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	number_of_vertices_uniform.binding = 5
	number_of_vertices_uniform.add_id(number_of_vertices_buffer)
	
	var sdf_set := rd.uniform_set_create([size_uniform, b_points_uniform, sdf_uniform], sdf_shader, 0)
	var cubes_set := rd.uniform_set_create([size_uniform, sdf_uniform, vertex_uniform, normal_uniform, number_of_vertices_uniform], cubes_shader, 0)
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
	number_of_vertices_bytes = rd.buffer_get_data(number_of_vertices_buffer)
	var size = number_of_vertices_bytes.to_int32_array()[0]*12 # Number of vertices to bytes (3 verts * 4 bytes per triangle)
	vertices_bytes = rd.buffer_get_data(vertex_buffer, 0, size)
	normals_bytes = rd.buffer_get_data(normal_buffer, 0, size)
	
	# TIMING
	print("Pull data: " + str((Time.get_unix_time_from_system() - tim_prev)*1000))
	tim_prev = Time.get_unix_time_from_system()
	
	# HACK Convert to Vec3 arr, this should be direct cast, probably need to change source
	var out_vertices := vertices_bytes.to_float32_array()
	var out_normals = normals_bytes.to_float32_array()
	var temp := PackedVector3Array()
	var temp2 := PackedVector3Array()
	for i in range(0,size/4,3):
		temp.append(Vector3(out_vertices[i],out_vertices[i+1],out_vertices[i+2]))
		temp2.append(Vector3(out_normals[i],out_normals[i+1],out_normals[i+2]))
	
	# TIMING
	print("Convert data: " + str((Time.get_unix_time_from_system() - tim_prev)*1000))
	
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
