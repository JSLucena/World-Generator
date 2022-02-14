extends Control





# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



func add_new_child(name,size):
	var world_size = ""
	if int(size) == 1:
		world_size = "128"
	elif int(size) == 2:
		world_size = "256"
	else:
		world_size = "512"
		
	var n = Label.new()
	var s = Label.new()
	var spaces = Label.new()
	var hbox = HBoxContainer.new()
	var vbox = VBoxContainer.new()
	var button = Button.new()
	button.text = "Load"
	button.connect("pressed",self,"_on_load_pressed",button)
	n.text = name
	s.text = world_size + "x" + world_size
	spaces.text = "    "
	hbox.add_child(n)
	hbox.add_child(spaces)
	hbox.add_child(s)
	hbox.add_child(button)
	vbox.add_child(hbox)
	self.add_child(vbox)


func _on_load_pressed(button):
	AudioManager.get_node("buttonClick").play()
	AudioManager.get_node("mainMenu").stop()
	
	GlobalVariables.load_name = button.text
	GlobalVariables.load_game = true
	get_tree().change_scene("res://scenes/Generator.tscn")
