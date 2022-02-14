extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var loadGame = File.new()
	var existing_saves = GlobalVariables.get_save_files()
	print(existing_saves)
	for file in existing_saves:
		loadGame.open("user://Saves/"+file, File.READ)

		var file_text = loadGame.get_as_text()
		var current_line = parse_json(file_text)
		var size = current_line["worldSize"]
			
		loadGame.close()
		$UI/Control/ScrollContainer/LoadUI.add_new_child(file,size)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
