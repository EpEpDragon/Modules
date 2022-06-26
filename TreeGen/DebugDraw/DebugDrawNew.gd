extends Node3D
class_name DebugDraw

func new_point_cloud(pos, p_size, color):
	var point_cloud = PointCloud.new(p_size, color)
	point_cloud.position = pos
	add_child(point_cloud)
	return point_cloud


class PointCloud extends MeshInstance3D:
	var cloud:PackedVector3Array
	var mat = StandardMaterial3D.new()
	
	func _init(p_size, color):
		mat.use_point_size = true
		mat.point_size = p_size
		mat.albedo_color = color
	
	
	func add_point(p):
		if p is PackedVector3Array:
			cloud += p
		else:
			cloud.push_back(p)
	
	
	func set_cloud(c):
		cloud = c
	
	
	func construct():
		var mesh_imm = ImmediateMesh.new()
		mesh_imm.surface_begin(Mesh.PRIMITIVE_POINTS)
		mesh_imm.surface_set_normal(Vector3(0,0,1))
		for p in cloud:
			mesh_imm.surface_add_vertex(p)
		mesh_imm.surface_end()
		mesh_imm.surface_set_material(0,mat)
		print(mesh_imm.surface_get_material(0))
		set_mesh(mesh_imm)
