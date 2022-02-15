extends Node2D

var master_muted = false
var soundtrack_muted = false
var sfx_muted = false

func change_master_volume(value):
	if value == -49:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"),true)
		master_muted = true
	else:
		master_muted = false
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"),false)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value)

func change_soundtrack_volume(value):
	if value == -49:
		get_tree().call_group("Soundtrack","set_volume_db",-100) # I think this does not work, but I dont know how to do it
		sfx_muted = true
	else:
		sfx_muted = false
		get_tree().call_group("Soundtrack","set_volume_db",value)

func change_sfx_volume(value):
	if value == -49:
		get_tree().call_group("SFX","set_volume_db",-100) # I think this does not work, but I dont know how to do it
		soundtrack_muted = true
	else:
		soundtrack_muted = false
		get_tree().call_group("SFX","set_volume_db",value)

func stop_all_soundtracks():
	get_tree().call_group("Soundtrack","stop")
