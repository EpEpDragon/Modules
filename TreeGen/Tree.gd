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
#var map = {'a': ">[-Fa][+Fa]*[-Fa][+Fa]"}
var map = {'X': ">Y*Y*Y*Y*Y", 'Y': "~&@[+FX]"}
#var map = {'X': ">[-FX]+FX"}
#var map = {'F': ">FF+[+F-F-F]-[-F+F+F]"}
#var map = {'X': "YF+XF+Y", 'Y': "XF-YF-X"}
@export_color_no_alpha var color = Color.WHITE
@export var width = 5

var position = Vector3.ZERO
var direction = Vector3.UP
var branch_normal = Vector3.FORWARD
var stack = []
var lines = []

@onready var sequence = axiom
@onready var DebugDraw = get_node("../DebugDraw")

#########################################
############## Instructions #############
#########################################

var move_draw = func():
	position += direction * length

var re_angle = func():
	direction = direction.rotated(branch_normal, deg2rad(branch_angle))

var de_angle = func():
	direction = direction.rotated(branch_normal, -deg2rad(branch_angle))

var re_rotate = func():
	branch_normal = branch_normal.rotated(direction, deg2rad(rot_angle))

var de_rotate = func():
	branch_normal = branch_normal.rotated(direction, -deg2rad(rot_angle))

var push = func():
	stack.append({"Position":position, "Direction":direction, "Branch_Normal":branch_normal, "Length":length})

var pop = func():
	var last = stack.size()-1
	position = stack[last]["Position"]
	direction = stack[last]["Direction"]
	branch_normal = stack[last]["Branch_Normal"]
	length = stack[last]["Length"]
	stack.remove_at(last)

var mult_leng = func():
	length *= scale_factor

var div_leng = func():
	length /= scale_factor

var var_leng = func():
	length *= 1.0+(randf()-0.5)*2*len_vari
#	length *= 1.0+(randf()-1.0)*2*len_vari

var var_br_ang = func():
	direction = direction.rotated(branch_normal, -deg2rad(branch_angle*(randf()-0.5)*2*ang_vari))

var var_rot = func():
	branch_normal = branch_normal.rotated(direction, deg2rad(rot_angle)*(randf()-0.5)*2*ang_vari)

var var_wind = func():
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
				'\\' : var_wind}
#########################################
#########################################

func _ready():
#	for n in range(iterations):
#		lines.clear()
	grow()
	construct()
	DebugDraw.set_lines(lines)
#		position = Vector3.ZERO
#		direction = Vector3.UP
#		await get_tree().create_timer(2).timeout


# Grows the sequence up to interations specified
func grow():
	for n in range(iterations):
		var sequence_temp = ""
		for s in sequence:
			sequence_temp += evolve(s)
		sequence = sequence_temp


# Constructs the geometry based on current stored sequence
func construct():
	for s in sequence:
		if instruction_map.has(s):
			var pos_prev = position
			instruction_map[s].call()
			if s == 'F':
#				lines.append({"Start":pos_prev, "End":position, "Color":Color(position.y/13,1-position.y/12, 0.5-position.x/2), "Width":width})
				lines.append({"Start":pos_prev, "End":position, "Color":Color(0.5-position.x/4,position.y/5, 0.5-position.z/12), "Width":width})


# Evolves a symbol to the appropriate symbol/symbol sequence
func evolve(s):
	if map.has(s):
		return map[s]
	else:
		return s
