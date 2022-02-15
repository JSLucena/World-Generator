extends Node

#### used in world loading
var load_name : String = ""
var worldsize : int = 0
var load_game : bool = false
############################

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

func _input(event):
	if Input.is_action_pressed("ui_cancel"):
		if get_tree().get_current_scene().get_name() != "MainMenu":
			QuitPopup.get_node("Control/ConfirmationDialog").show()
		else:
			get_tree().quit()
