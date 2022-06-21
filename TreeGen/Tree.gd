extends Node
var DebugDraw
@export var length = 1.0
@export var scale_factor = 0.6
@export var angle = 60
@export var iterations = 1
@export var axiom = "YF"
@export_color_no_alpha var color = Color.WHITE
@export var width = 5

#var symbols = ['X', 'F', '+', '-', ]
var position = Vector3.ZERO
var direction = Vector3.UP
var stack = []
var sequence = axiom
#var map = {'X': ">[-FX]+FX"}
#var map = {'F': ">FF+[+F-F-F]-[-F+F+F]"}
#var map = {'F': "FF", 'X': "F[+X]F[-X]+X"}
var map = {'X': "YF+XF+Y", 'Y': "XF-YF-X"}

var lines = []

var move_draw = func():
	position += direction * length

var rotate_right = func():
	direction = direction.rotated(Vector3(0,0,1), deg2rad(angle))

var rotate_left = func():
	direction = direction.rotated(Vector3(0,0,1), -deg2rad(angle))

var push = func():
	stack.append({"Position":position, "Direction":direction, "Length":length})

var pop = func():
	position = stack[stack.size()-1]["Position"]
	direction = stack[stack.size()-1]["Direction"]
	length = stack[stack.size()-1]["Length"]
	stack.remove_at(stack.size()-1)

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

func _ready():
	DebugDraw = get_node("../DebugDraw")
	grow()
	construct()
	DebugDraw.set_lines(lines)
#	print("Seq: " + str(sequence))
#	print("Pos: " + str(position))
#	print("Dir: " + str(direction))


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
				lines.append({"Start":pos_prev, "End":position, "Color":Color(1+position.x/2,-position.x/5, position.y/4), "Width":width})

# Evolves a symbol to the appropriate symbol/symbol sequence
func evolve(s):
	if map.has(s):
		return map[s]
	else:
		return s
