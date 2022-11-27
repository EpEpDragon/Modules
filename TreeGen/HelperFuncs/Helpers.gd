extends Node

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
#		triangle.append(merged_loops[l_i][p_i])
#		triangle.append(merged_loops[l_i][p_i-1])
#		triangle.append(merged_loops[merge_points[l_i][p_i][0]][merge_points[l_i][p_i][1] + inc])
	else:
		triangle.append(points[2])
		triangle.append(points[1])
		triangle.append(points[0])
#		triangle.append(merged_loops[merge_points[l_i][p_i][0]][merge_points[l_i][p_i][1] + inc])
#		triangle.append(merged_loops[l_i][p_i-1])
#		triangle.append(merged_loops[l_i][p_i])
	return triangle
