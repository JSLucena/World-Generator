extends Node2D

func _ready():
	AudioManager.get_node("mainMenu").play()

func _on_exit_pressed():
	AudioManager.get_node("mainMenu").stop()
	get_tree().quit()


func _on_newGame_pressed():
	AudioManager.get_node("mainMenu").stop()
	get_tree().change_scene("res://scenes/Generator.tscn")


func _on_loadGame_pressed():
	
	AudioManager.get_node("buttonClick").play()
	get_tree().change_scene("res://scenes/LoadMenu.tscn")
	


func _on_options_pressed():
	AudioManager.get_node("buttonClick").play()
	get_tree().change_scene("res://scenes/Options.tscn")
