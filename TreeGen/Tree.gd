extends Node

@export var length = 1.0
@export var scale_factor = 0.6
@export var angle = 20
@export var iterations = 1
@export var axiom = ""
@export var map = {}
#var map = {'X': ">[-FX]+FX"}
#var map = {'F': ">FF+[+F-F-F]-[-F+F+F]"}
#var map = {'X': "YF+XF+Y", 'Y': "XF-YF-X"}
@export_color_no_alpha var color = Color.WHITE
@export var width = 5

var position = Vector3.ZERO
var direction = Vector3.UP
var stack = []
var lines = []

@onready var sequence = axiom
@onready var DebugDraw = get_node("../DebugDraw")

#########################################
############## Instructions #############
#########################################

var move_draw = func():
	position += direction * length

var rotate_right = func():
	direction = direction.rotated(Vector3(0,0,1), deg2rad(angle))

var rotate_left = func():
	direction = direction.rotated(Vector3(0,0,1), -deg2rad(angle))

var push = func():
	stack.append({"Position":position, "Direction":direction, "Length":length})

var pop = func():
	var last = stack.size()-1
	position = stack[last]["Position"]
	direction = stack[last]["Direction"]
	length = stack[last]["Length"]
	stack.remove_at(last)

var mult_leng = func():
	length *= scale_factor

var div_leng = func():
	length /= scale_factor

var instruction_map = {
				'F' : move_draw,
				'+' : rotate_right,
				'-' : rotate_left,
				'[' : push,
				']' : pop,
				'>' : mult_leng,
				'<' : div_leng}
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
				lines.append({"Start":pos_prev, "End":position, "Color":Color(position.y/13,1-position.y/12, 0.5-position.x/2), "Width":width})


# Evolves a symbol to the appropriate symbol/symbol sequence
func evolve(s):
	if map.has(s):
		return map[s]
	else:
		return s
