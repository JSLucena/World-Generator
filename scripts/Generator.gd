extends Node2D


export var size_x : int = 256
export var size_y : int = 256
export var noise_seed : int = 1
export var octaves  : int = 4
export var period : float = 100.0
export var persistence : float = 0.5

var noise = OpenSimplexNoise.new()


var tile :int = 0
pass

export var height_modifier = 1.0
export var raiser = 2.0
# Called when the node enters the scene tree for the first time.
func _ready():
	generate()


func get_tile_color(perlin):
	if perlin > 0.9:
		return 5
	elif perlin > 0.8:
		return 5
	elif perlin > 0.6:
		return 4
	elif perlin > 0.5:
		return 13
	elif perlin > 0.4:
		return 12
	elif perlin > 0.2:
		return 11
	elif perlin > 0.15:
		return 8
	elif perlin > 0.1:
		return 17
	elif perlin > 0.05:
		return 15
	else:
		return 16
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#i
	#pass
func generate():
	$TileMap.clear()
	noise.seed = noise_seed
	noise.octaves = octaves
	noise.period = period
	noise.persistence = persistence
	
	
	
	
	for x in range(0,size_x):
		for y in range(0,size_y):
				tile = get_tile_color(noise.get_noise_2d(x,y) * height_modifier)
				$TileMap.set_cell(x,y,tile)


func _input(event):
	if Input.is_key_pressed(KEY_R):
		generate()


func _on_small_pressed():
	size_x = 128
	size_y = 128


func _on_medium_pressed():
	size_x = 256
	size_y = 256


func _on_large_pressed():
	size_x = 512
	size_y = 512

func _on_persistence_value_value_changed(value):
	persistence = value
	$GUI/MarginContainer/PanelContainer/VBoxContainer/persistence/persistence.set_text("Persistence : " +  String(value))

func _on_octave_slider_value_changed(value):
	octaves = value
	$GUI/MarginContainer/PanelContainer/VBoxContainer/octaves/octave.set_text("Octaves : " +  String(value))

func _on_periodSpin_value_changed(value):
	period = value
	
func _on_seed_box_value_changed(value):
	noise_seed = value
	
func _on_generate_pressed():
	generate()
	
func _on_flatter_pressed():
	height_modifier = 1.0
	
func _on_normal_pressed():
	height_modifier = 1.5

func _on_peaks_pressed():
	height_modifier = 2.0
