extends Node3D
class_name DebugDraw

func new_point_cloud(pos, p_size, color):
	var point_cloud = PointCloud.new(p_size, color)
	point_cloud.position = pos
	add_child(point_cloud)
	return point_cloud

func new_line_seg(pos, color):
	var line_seg = LineSegment.new(color)
	line_seg.position = pos
	add_child(line_seg)
	return line_seg

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

class LineSegment extends MeshInstance3D:
	var points:PackedVector3Array
	var mat = StandardMaterial3D.new()
	
	func _init(color):
		mat.albedo_color = color
	
	func add_point(point:Vector3): points.push_back(point)
	func add_points(new_points:PackedVector3Array): points += new_points
	func set_points(new_points:PackedVector3Array): points = new_points
	
	func construct():
		if points.size() == 1: points.append(points[0])
		var mesh_imm = ImmediateMesh.new()
		mesh_imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		mesh_imm.surface_set_normal(Vector3(0,0,1))
		for p in points:
			mesh_imm.surface_add_vertex(p)
		mesh_imm.surface_end()
		mesh_imm.surface_set_material(0,mat)
		set_mesh(mesh_imm)
		
