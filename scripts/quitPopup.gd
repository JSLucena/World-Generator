extends Node2D


func _ready():
	$Control/ConfirmationDialog.add_button("Options",true,"options")


func _on_ConfirmationDialog_confirmed():
	AudioManager.stop_all_soundtracks()
	AudioManager.get_node("mainMenu").play()
	get_tree().change_scene("res://scenes/MainMenu.tscn")


func _on_ConfirmationDialog_custom_action(action):
	if action == "options":
		AudioManager.stop_all_soundtracks()
		AudioManager.get_node("mainMenu").play()
		get_tree().change_scene("res://scenes/Options.tscn")
		$Control/ConfirmationDialog.set_visible(false)
