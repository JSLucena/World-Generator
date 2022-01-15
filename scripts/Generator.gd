extends Node2D


export var size_x : int = 256
export var size_y : int = 256


var noise = OpenSimplexNoise.new()
var tile :int = 0
pass

export var test = 1.0
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
	randomize()
	noise.seed = randi()
	noise.octaves = 4
	noise.period = 100.0
	noise.persistence = 0.5
	
	
	
	for x in range(0,size_x):
		for y in range(0,size_y):
				tile = get_tile_color(noise.get_noise_2d(x,y) * test)
				$TileMap.set_cell(x,y,tile)


func _input(event):
	if Input.is_key_pressed(KEY_R):
		generate()
