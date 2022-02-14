extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	AudioManager.get_node("mainMenu").play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_exit_pressed():
	AudioManager.get_node("mainMenu").stop()
	get_tree().quit()


func _on_newGame_pressed():
	AudioManager.get_node("mainMenu").stop()
	get_tree().change_scene("res://scenes/Generator.tscn")


func _on_loadGame_pressed():
	
	AudioManager.get_node("buttonClick").play()
	get_tree().change_scene("res://scenes/LoadMenu.tscn")
	
