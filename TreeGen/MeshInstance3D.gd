extends MeshInstance3D



func _ready():
	get_viewport().debug_draw=Viewport.DEBUG_DRAW_WIREFRAME
	var mesh_imm = ImmediateMesh.new()
	mesh_imm.clear_surfaces()
	
	mesh_imm.surface_begin(Mesh.PRIMITIVE_POINTS)
	mesh_imm.surface_set_normal(Vector3(0,0,1))
	mesh_imm.surface_add_vertex(Vector3(-1,-1,0))
	mesh_imm.surface_add_vertex(Vector3(-1,1,0))
	mesh_imm.surface_add_vertex(Vector3(1,-1,0))
	mesh_imm.surface_add_vertex(Vector3(1,1,0))
	mesh_imm.surface_add_vertex(Vector3(2,-1,0))
	mesh_imm.surface_add_vertex(Vector3(2,1,0))
	mesh_imm.surface_end()
#	var mat = StandardMaterial3D.new()
#	mat.use_point_size = true
#	mat.set_point_size = 10
#	mesh_imm.surface_set_material(0,mat)
	
	mesh = mesh_imm
