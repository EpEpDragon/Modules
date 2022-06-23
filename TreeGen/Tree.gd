extends Node

@export var length = 1.0
@export var scale_factor = 0.4
@export var len_vari = 0.1
@export var ang_vari = 0.5
@export var branch_angle = 20
@export var rot_angle = 150
@export var iterations = 1
@export var axiom = ""
#@export var map = {}
#var map = {'X': ">~&@[-FX][+FX]*[-FX][+FX]"}
#var map = {'X': ">Y*Y*Y*Y*Y", 'Y': "~&@[+FX]"}
#var map = {'X': ">[-FX]+FX"}
#var map = {'F': ">FF+[+F-F-F]-[-F+F+F]"}
#var map = {'X': "YF+XF+Y", 'Y': "XF-YF-X"}
var map = {'X': "F>[~*+X]F[~/+X]"}
@export_color_no_alpha var color = Color.WHITE
@export var width = 5

var position = Vector3.ZERO
var direction = Vector3.UP
var branch_normal = Vector3.FORWARD
var stack:Array[Dictionary] = []

var lines:Array[Dictionary] = []
var paths:Array[Path3D] = []

@onready var sequence = axiom
@onready var DebugDraw = get_node("../DebugDraw")

###############################################################################
################################# Instructions ################################
###############################################################################

# Used for path generation
var pos_prev = position

# Index of path being generated
var current_branch = 0

# Top of stack
var top = -1

# Draw forward and save previous position
var move_draw = func():
	pos_prev = position
	position += direction * length
	paths[current_branch].get_curve().add_point(position)

# Rotate branch normal positive
var re_angle = func():
	direction = direction.rotated(branch_normal, deg2rad(branch_angle))

# Rotate branch normal negative
var de_angle = func():
	direction = direction.rotated(branch_normal, -deg2rad(branch_angle))

# Rotate branch diraction positive
var re_rotate = func():
	branch_normal = branch_normal.rotated(direction, deg2rad(rot_angle))

# Rotate branch diraction negative
var de_rotate = func():
	branch_normal = branch_normal.rotated(direction, -deg2rad(rot_angle))

# Push current state, add path for branch
var push = func():
	stack.append({"Position":position, "Position_Previous":pos_prev, "Direction":direction, "Branch_Normal":branch_normal, "Length":length})
	top += 1

# Pop current state, terminate current path
var pop = func():
	position = stack[top]["Position"]
	pos_prev = stack[top]["Position_Previous"]
	direction = stack[top]["Direction"]
	branch_normal = stack[top]["Branch_Normal"]
	length = stack[top]["Length"]
	stack.remove_at(top)
	top -= 1
	
	current_branch += 1
	paths.append(Path3D.new())
	paths[current_branch].set_curve(Curve3D.new())
	paths[current_branch].get_curve().add_point(pos_prev)
	paths[current_branch].get_curve().add_point(position)

# Multiply length by scale factor
var mult_leng = func():
	length *= scale_factor

# Divide length by scale factor
var div_leng = func():
	length /= scale_factor

# Vary length by random amount
var var_leng = func():
	length *= 1.0+(randf()-0.5)*2*len_vari
#	length *= 1.0+(randf()-1.0)*2*len_vari

# Vary branch normal by random amount
var var_br_ang = func():
	direction = direction.rotated(branch_normal, -deg2rad(branch_angle*(randf()-0.5)*2*ang_vari))

# Vary branch diraction by random amount
var var_rot = func():
	branch_normal = branch_normal.rotated(direction, deg2rad(rot_angle)*(randf()-0.5)*2*ang_vari)

# Wind bias, grow away from wind vector
var var_wind = func():
	pass

# Sun bias, grow into sun
var var_sun = func():
	pass

var instruction_map = {
				'F' : move_draw,
				'+' : re_angle,
				'-' : de_angle,
				'*' : re_rotate,
				'_' : de_rotate,
				'[' : push,
				']' : pop,
				'>' : mult_leng,
				'<' : div_leng,
				'~' : var_leng,
				'&' : var_br_ang,
				'@' : var_rot,
				'\\' : var_wind,
				'#' : var_sun}
###############################################################################
###############################################################################

func _ready():
#	for n in range(iterations):
#		lines.clear()
	grow()
	construct()
	DebugDraw.set_paths(paths)
#	DebugDraw.set_lines(lines)


# Grows the sequence up to interations specified
func grow():
	for n in range(iterations):
		var sequence_temp = ""
		for s in sequence:
			sequence_temp += evolve(s)
		sequence = sequence_temp


# Constructs the geometry based on current stored sequence
func construct():
	paths.append(Path3D.new())
	paths[current_branch].set_curve(Curve3D.new())
	paths[current_branch].get_curve().add_point(position)
	
	for s in sequence:
		if instruction_map.has(s):
			instruction_map[s].call()


# Evolves a symbol to the appropriate symbol/symbol sequence
func evolve(s):
	if map.has(s):
		return map[s]
	else:
		return s
