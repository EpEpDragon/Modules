extends CSGPolygon3D

func _ready():
	_update_shape()
	var mesh = get_meshes()[1]
#	ResourceSaver.save("res://test.mesh",mesh)
