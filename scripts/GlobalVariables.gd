extends Node


var load_name : String = ""
var worldsize : int = 0
var load_game : bool = false


func get_save_files():
	var files = []
	var dir = Directory.new()
	dir.open("user://Saves")
	dir.list_dir_begin(true)
	
	var file = dir.get_next()
	while file != '':
		files += [file]
		file = dir.get_next()
	return files
