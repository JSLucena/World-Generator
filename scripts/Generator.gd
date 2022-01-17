extends Node2D


export var size_x : int = 256 #Map size
export var size_y : int = 256 #Map size
export var noise_seed : int = 1
export var octaves  : int = 4
export var period : float = 100.0
export var persistence : float = 0.5
export var lacunarity : float = 2.0

var noise = OpenSimplexNoise.new()
var tile :int = 0
export var height_modifier = 1.0 # Variable to increase/decrease peak and valley height

var biome_parameters = {} #Key is position on tilegrid, values are (temperature,rain,type,avg_height)


func _ready():
	generate()


func get_tile_color(perlin): #Tile color is chosen by its height, using its noise value
	if perlin > 0.8:
		return 5
	elif perlin > 0.6:
		return 1
	elif perlin > 0.4:
		return 4
	elif perlin > 0.3:
		return 13
	elif perlin > 0.2:
		return 12
	elif perlin > 0.1:
		return 11
	elif perlin > 0:
		return 8
	elif perlin > -0.05:
		return 17
	elif perlin > -0.2:
		return 15
	else:
		return 16
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	mouse_map_information()
	#pass
func generate():
	$TileMap.clear()
	noise.seed = noise_seed
	noise.octaves = octaves
	noise.period = period
	noise.persistence = persistence
	noise.lacunarity = lacunarity
	
	
	
	for x in range(0,size_x):
		for y in range(0,size_y):
				var height = noise.get_noise_2d(x,y) * height_modifier
				tile = get_tile_color(height) #This will probably be changed to include more biomes
				
				
				randomize()
				biome_parameters[Vector2(x,y)] = [randf(),randf(),"test",height] #values are (temperature,rain,type,avg_height)
				#print(biome_parameters[Vector2(x,y)])
				$TileMap.set_cell(x,y,tile)
func mouse_map_information():
	var mousePosition = $TileMap.world_to_map(get_global_mouse_position())
	$GUI/BiomeInfo/VBoxContainer/height.set_text("average height : " + String(biome_parameters[mousePosition][3]) )
	$GUI/BiomeInfo/VBoxContainer/position.set_text(String(mousePosition) )
	$GUI/BiomeInfo/VBoxContainer/type.set_text(biome_parameters[mousePosition][2])
	$GUI/BiomeInfo/VBoxContainer/temp.set_text("temperature : " + String(biome_parameters[mousePosition][0]) )
	$GUI/BiomeInfo/VBoxContainer/rain.set_text("rain : " + String(biome_parameters[mousePosition][1]) )
	#print(mousePosition)

func _input(event):
	if event is InputEventMouseMotion:
		mouse_map_information()

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
	height_modifier = 0.8
func _on_normal_pressed():
	height_modifier = 1.0
func _on_peaks_pressed():
	height_modifier = 1.2


func _on_lacunarity_box_value_changed(value):
	lacunarity = value
	pass # Replace with function body.
