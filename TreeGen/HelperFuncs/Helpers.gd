extends Node

func find_replace(arr, find, replace):
	for i in range(arr.size()):
		if arr[i] == find:
			arr[i] = replace
