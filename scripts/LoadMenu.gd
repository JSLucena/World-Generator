extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var world_name

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
		
		var world_size = ""
		if int(size) == 1:
			world_size = "128"
		elif int(size) == 2:
			world_size = "256"
		else:
			world_size = "512"
		
		var item = file + " " + world_size + "x" + world_size
		$UI/Control/container/VBoxContainer/saves.add_item(item)
	
	$UI/Control/container/VBoxContainer/saves.select(0)
	world_name = $UI/Control/container/VBoxContainer/saves.get_item_text(0)
	world_name = world_name.split(" ")[0]	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Button_pressed():
	AudioManager.get_node("buttonClick").play()
	AudioManager.get_node("mainMenu").stop()
	
	GlobalVariables.load_name = world_name
	GlobalVariables.load_game = true
	get_tree().change_scene("res://scenes/Generator.tscn")


func _on_saves_item_selected(index):
	world_name = $UI/Control/container/VBoxContainer/saves.get_item_text(index)
	world_name = world_name.split(" ")[0]
