extends Node2D

func _on_masterSlider_value_changed(value):
	var label = (value + 49) * 2
	AudioManager.change_master_volume(value)
	$MarginContainer/VBoxContainer/HBoxContainer/value.text = String(label)


func _on_soundtrackSlider_value_changed(value):
	var label = (value + 49) * 2
	AudioManager.change_soundtrack_volume(value)
	$MarginContainer/VBoxContainer/HBoxContainer3/value.text = String(label)


func _on_sfxSlider_value_changed(value):
	var label = (value + 49) * 2
	AudioManager.change_sfx_volume(value)
	$MarginContainer/VBoxContainer/HBoxContainer2/value.text = String(label)
