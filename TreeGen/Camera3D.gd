extends Camera3D

@export var movespeed = 1.0
@export var mouse_sense = 0.5

var velocity = Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta):
	handle_movement_translate(delta)


func _input(event):
	handle_movement_rotate(event)
	if event.is_action_pressed("quit"):
		get_tree().quit()
	elif event.is_action_pressed("change_view"):
		if get_viewport().debug_draw == Viewport.DEBUG_DRAW_DISABLED:
			get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
		elif get_viewport().debug_draw == Viewport.DEBUG_DRAW_WIREFRAME:
			get_viewport().debug_draw = Viewport.DEBUG_DRAW_OVERDRAW
		elif get_viewport().debug_draw == Viewport.DEBUG_DRAW_OVERDRAW:
			get_viewport().debug_draw = Viewport.DEBUG_DRAW_NORMAL_BUFFER
		else:
			get_viewport().debug_draw = Viewport.DEBUG_DRAW_DISABLED

func handle_movement_translate(delta):
	velocity = Vector3()
	if Input.is_action_pressed("move_up"):
		velocity += Vector3.UP
	elif Input.is_action_pressed("move_down"):
		velocity += Vector3.DOWN
	if Input.is_action_pressed("move_left"):
		velocity += -Vector3.LEFT
	elif Input.is_action_pressed("move_right"):
		velocity += -Vector3.RIGHT
	if Input.is_action_pressed("move_forward"):
		velocity += Vector3.FORWARD
	elif Input.is_action_pressed("move_back"):
		velocity += Vector3.BACK
	velocity = velocity.normalized() * movespeed
	translate(velocity * delta)


func handle_movement_rotate(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.003 * mouse_sense)
		var changev = -event.relative.y * 0.003 * mouse_sense
#		if rotation.x + changev < PI/2 && rotation.y + changev > -PI/2:
		rotate_object_local(Vector3(1,0,0), changev)
		rotation.x = clamp(rotation.x, -PI/2, PI/2)
