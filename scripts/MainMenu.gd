extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_exit_pressed():
	get_tree().quit()


func _on_newGame_pressed():
	
	get_tree().change_scene("res://scenes/Generator.tscn")


func _on_loadGame_pressed():
	$buttonClick.play(0)
	pass # Replace with function body.
