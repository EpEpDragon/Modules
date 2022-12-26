extends Node3D

func new_point_cloud(pos, p_size, color):
	var point_cloud = PointCloud.new(p_size, color)
	point_cloud.position = pos
	add_child(point_cloud)
	return point_cloud

func new_spheres(pos, radius, color):
	var spheres = Spheres.new(radius, color)
	spheres.position = pos
	add_child(spheres)
	return spheres

func new_lines(pos, color):
	var lines = Lines.new(color)
	lines.position = pos
	add_child(lines)
	return lines

func new_line_seg(pos, color):
	var line_seg = LineSegment.new(color)
	line_seg.position = pos
	add_child(line_seg)
	return line_seg

func new_label(text:String, pos:Vector3, camera:Camera3D):
	var label = D_Label.new(text,pos,camera)
	add_child(label)
	return label

class PointCloud extends MeshInstance3D:
	var cloud:PackedVector3Array = []
	var mat = StandardMaterial3D.new()
	
	func _init(p_size, color):
		mat.use_point_size = true
		mat.point_size = p_size
		mat.albedo_color = color
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cast_shadow = false
	
	func clear() : cloud.clear()
	func add_point(p): cloud.append(p)
	func add_points(p): cloud.append_array(p)
	func set_cloud(c): cloud = c
	
	
	func construct():
		var mesh_imm = ImmediateMesh.new()
		mesh_imm.surface_begin(Mesh.PRIMITIVE_POINTS)
		for p in cloud:
			mesh_imm.surface_add_vertex(p)
		mesh_imm.surface_end()
		mesh_imm.surface_set_material(0,mat)
		set_mesh(mesh_imm)

class Spheres extends MeshInstance3D:
	var positions:PackedVector3Array = []
	var mat = StandardMaterial3D.new()
	var _radius = 1.0
	
	func _init(radius, color):
		_radius = radius
		mat.albedo_color = color
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.set_transparency(true)
		mat.set_cull_mode(BaseMaterial3D.CULL_DISABLED)
		cast_shadow = false
	
	func clear() : positions.clear()
	func add_sphere(p): positions.append(p)
	func add_spheres(p): positions.append_array(p)
	func set_spheres(c): positions = c
	
	func construct():
		for p in positions:
			mesh = SphereMesh.new()
			mesh.radius = _radius
			mesh.height = _radius*2
			mesh.surface_set_material(0,mat)
			set_mesh(mesh)

class Lines extends MeshInstance3D:
	var points:PackedVector3Array
	var mat = StandardMaterial3D.new()
	
	func _init(color):
		mat.albedo_color = color
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cast_shadow = false
	
	func clear(): 
		points.clear()
		set_mesh(ImmediateMesh.new())
		
	func add_point(point:Vector3): points.append(point)
	func add_points(new_points:PackedVector3Array): points.append_array(new_points)
	func set_points(new_points:PackedVector3Array): points = new_points
	
	func construct():
		if points.size() > 1:
			var mesh_imm = ImmediateMesh.new()
			mesh_imm.surface_begin(Mesh.PRIMITIVE_LINES)
			for p in points:
				mesh_imm.surface_add_vertex(p)
			mesh_imm.surface_end()
			mesh_imm.surface_set_material(0,mat)
			set_mesh(mesh_imm)
		else:
			set_mesh(ImmediateMesh.new())

class LineSegment extends MeshInstance3D:
	var points:PackedVector3Array
	var mat = StandardMaterial3D.new()
	
	func _init(color):
		mat.albedo_color = color
		cast_shadow = false
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	func clear(): 
		points.clear()
		set_mesh(ImmediateMesh.new())
		
	func add_point(point:Vector3): points.append(point)
	func add_points(new_points:PackedVector3Array): points.append_array(new_points)
	func set_points(new_points:PackedVector3Array): points = new_points
	
	func construct():
#		if points.size() == 1: points.append(points[0])
		if points.size() > 1:
			var mesh_imm = ImmediateMesh.new()
			mesh_imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
			for p in points:
				mesh_imm.surface_add_vertex(p)
			mesh_imm.surface_end()
			mesh_imm.surface_set_material(0,mat)
			set_mesh(mesh_imm)
		else:
			set_mesh(ImmediateMesh.new())



class D_Label extends Label:
	var pos3D
	var camera
	func _init(t:String, p:Vector3, c:Camera3D):
		set_text(t)
		pos3D = p
		camera = c
	func update():
		_set_position(camera.unproject_position(pos3D))
