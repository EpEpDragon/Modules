extends Node

# Cylinder definded by line through point A -> B with radius R
# Infinite line A -> B must not pass thorugh [0,0,0]
func in_cylinder(A:Vector3, B:Vector3, R:float, P:Vector3):
	var e = B - A
	var m = A.cross(B)
	
	var temp = e.cross(P - A)
	var d = temp.length()/e.length()
	
	if d < R:
		var Q = e.cross(temp)/e.length_squared()
		var wA = Q.cross(B).length()/m.length()
		var wB = Q.cross(A).length()/m.length()
		if wA >= 0 && wA <= 1 && wB >= 0 && wB <= 1:
			return true
	return false


func gen_circle(pos:Vector3, r:float, n:Vector3, res:int):
	var rot = 0
	var step = PI/2/res
	var points = []
	var point = (Vector3.UP).cross(n).cross(n)
	if (point == Vector3.ZERO): point = r*Vector3.FORWARD #will need info to align this correctly
	else: point *=  r/point.length()
	for i in range(4*res):
		points.append(point.rotated(n, rot)+pos)
		rot+=step
#	points.append(points[0]) #this is only necessary to complete the circle if points are used to generate lines
	return points


func gen_disc(pos:Vector3, r:float, n:Vector3, res:int):
	var rot = 0
	var step = PI/2/res
	var points = []
	var point = (Vector3.UP).cross(n).cross(n)
	if (point == Vector3.ZERO): point = r*Vector3.FORWARD #will need info to align this correctly
	else: point *=  r/point.length()
	for i in range(4*res):
		points.append(point.rotated(n, rot)+pos)
		rot+=step
		var temp = []
		for a in range(r*res*2):
			temp.append(points[-1]*a/(r*res*2))
		points.append_array(temp)
			
#	points.append(points[0]) #this is only necessary to complete the circle if points are used to generate lines
	return points


func find_replace(arr, find, replace):
	for i in range(arr.size()):
		if arr[i] == find:
			arr[i] = replace


func contains_triangle(triangle, indices):
	for t in range(0,indices.size(),3):
		var tri_slice = indices.slice(t,t+3)
		var similar = true
		for i in triangle:
			if !tri_slice.has(i):
				similar = false
				break
		if similar:
			return similar
	return false


func calc_mean_normal(normals):
	var sum_normal = Vector3.ZERO
	for n in normals:
		sum_normal += n
	return sum_normal.normalized()


func make_triangle(arr, points):
	var triangle:PackedInt32Array = []
	if (arr[Mesh.ARRAY_VERTEX][points[1]] - arr[Mesh.ARRAY_VERTEX][points[0]]).cross(arr[Mesh.ARRAY_VERTEX][points[2]] - arr[Mesh.ARRAY_VERTEX][points[0]]).dot(arr[Mesh.ARRAY_NORMAL][points[0]]) < 0:
		triangle.append(points[0])
		triangle.append(points[1])
		triangle.append(points[2])
	else:
		triangle.append(points[2])
		triangle.append(points[1])
		triangle.append(points[0])
	return triangle
