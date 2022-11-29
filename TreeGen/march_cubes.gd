extends Node3D

# These should be about linearly, inversely, proportional
# About: circ_res = 20 - bake_interval * 100
@export var cell_size = 0.04
@export var size = Vector3(3,3,3)

var bake_interval = cell_size/2
var circ_res = int(0.2/bake_interval)
var radius = 0.2

var point_cloud = DebugDraw.new_point_cloud(Vector3.ZERO, 20, Color.GREEN)
var point_cloud2 = DebugDraw.new_point_cloud(Vector3.ZERO, 10, Color.BLUE)
var point_cloud3 = DebugDraw.new_point_cloud(Vector3.ZERO, 20, Color.RED)
var labels = []
var color_arr = [Color.RED, Color.GREEN, Color.BLUE, Color.PURPLE, Color.YELLOW, Color.CYAN, Color.BLUE, Color.PURPLE, Color.PINK, Color.RED]
var line_segment = DebugDraw.new_line_seg(Vector3(0,0,-5),Color.RED)

var tim_start = Time.get_unix_time_from_system()
var tim_prev = tim_start

func _ready():
	print("Bake interval: " + str(bake_interval))
	print("Circ res: " + str(circ_res))
	print("\nTIMING")
	var curves:Array[Curve3D] = [$Path3D.get_curve(),$Path3D2.get_curve(), $Path3D3.get_curve(), $Path3D4.get_curve(), $Path3D5.get_curve()]
	# Get vertecices ordered by branch and disc
	var grid = generate_grid(size, cell_size)
	fill_grid(grid,curves)
#	point_cloud.construct()


func generate_grid(size:Vector3, cell_size:float):
	var grid = []
	for x in range(size.x/cell_size):
		grid.append([])
		for y in range(size.y/cell_size):
			grid[x].append([])
			for z in range(size.z/cell_size):
				grid[x][y].append(false)
	# TIMING
	print("Generate grid: " + str(tim_prev-tim_start))
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
			if !norm.is_normalized():
				norm = norm_prev
			prev_p = p
			norm_prev = norm
			var c_points = Helpers.gen_disc(p, radius, norm, circ_res)
			for c_p in c_points:
				c_p += Vector3(size.x,0,size.z)/2.0
				grid[int(c_p.x/cell_size)][int(c_p.y/cell_size)][int(c_p.z/cell_size)] = true
	# TIMING
	print("Fill grid: " + str(tim_prev-tim_start))
	tim_prev = Time.get_unix_time_from_system()
	
	for x in range(grid.size()):
		for y in range(grid[x].size()):
			for z in range(grid[x][y].size()):
				if grid[x][y][z]:
					var mesh_inst = MeshInstance3D.new()
					mesh_inst.mesh = BoxMesh.new()
					mesh_inst.mesh.set_size(Vector3(cell_size,cell_size,cell_size))
					mesh_inst.translate(Vector3(x,y,z)*cell_size - Vector3(size.x,0,size.z)/2.0)
					add_child(mesh_inst)
#					point_cloud.add_point(Vector3(x,y,z)*cell_size - Vector3(size.x,0,size.z)/2.0)
#			for x in range(grid.size()):
#				for y in range(grid[x].size()):
#					for z in range(grid[x][y].size()):
#						var point_coord = Vector3(x,y,z)*cell_size - Vector3(size.x,0,size.z)/2.0
#						if Helpers.in_cylinder(points[p_i]+Vector3.ONE,points[p_i+1]+Vector3.ONE,0.5,point_coord+Vector3.ONE):
#							grid[x][y][z] = true
#							point_cloud.add_point(point_coord)
	# TIMING
	print("display: " + str(tim_prev-tim_start))
	tim_prev = Time.get_unix_time_from_system()
