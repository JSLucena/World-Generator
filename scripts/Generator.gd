extends Node2D


export var size_x : int = 256 #Map size
export var size_y : int = 256 #Map size
export var noise_seed : int = 1
export var octaves  : int = 7
export var period : float = 100.0
export var persistence : float = 0.7
export var lacunarity : float = 2.0

var noise = OpenSimplexNoise.new()
var temperature_noise = OpenSimplexNoise.new()
var rain_noise = OpenSimplexNoise.new()
var tile : int = 0
var rain_tile : int = 0
var temperature_tile : int = 0
export var height_modifier = 1.0 # Variable to increase/decrease peak and valley height
var biome_parameters = {} #Key is position on tilegrid, values are (temperature,rain,type,avg_height)
export var hemisphere : bool = true # false = south , true = north
var rain_standard_deviation : float = 0
var temperature_standard_deviation : float = 0



var air_masses = {} #Dictionary containing each air mais route,speed, temperature and rain values from the starting point
var air_mass_count : int = 0
var speed : int = 0 # the speed will be used to enable air masses to go up
var going_up : bool = false
var empty_count = 0

var game_name = ""
var saves_updated = false
var generated = false

enum biomes{
	DESERT = 0,
	SAVANNA = 1,
	BADLAND = 2,
	FROZEN_SHRUBLAND = 3,
	COLD_DESERT = 4,
	CAATINGA = 5,
	SHRUBLAND = 6,
	PLAINS = 7,
	ROCKS = 8,
	FROZEN = 9,
	BROADLEAF_DRY = 10,
	PINE_TROPICAL = 11,
	BEACH = 12,
	COLD_PLAINS = 13,
	COLD_MEADOW = 14,
	FLOODED_SAVANNA = 15,
	BROADLEAF = 16,
	LAKES = 17,
	MEADOW = 18,
	GROVE = 19,
	RAIN_FOREST = 20,
	SWAMP = 21,
	MIXED_FOREST = 22,
	TAIGA = 23,
	TUNDRA = 24,
	DEEP_WATER = 25,
	AVERAGE_WATER = 26,
	SHALLOW_WATER = 27,
	INLAND_WATER = 28
}
enum sizes{
	SMALL = 1
	MEDIUM = 2
	LARGE = 3
}


class customSort:
	static func sort_second(a,b):
		return a[1] < b[1]
		
class StringHelper:
	static func string_to_vector2(string := "") -> Vector2:
		if string:
			var new_string: String = string
			new_string.erase(0, 1)
			new_string.erase(new_string.length() - 1, 1)
			var array: Array = new_string.split(", ")

			return Vector2(array[0], array[1])

		return Vector2.ZERO

func save(savename):
	var gameData = {
		worldMap = biome_parameters,
		airMasses = air_masses
	}
	var data = gameData
	var saveGame = File.new()
	saveGame.open("user://Saves/"+savename+".sve", File.WRITE)
	saveGame.store_line(to_json(data))
	saveGame.close()
	

func load_game(savename):
	var loadGame = File.new()
	print(savename)
	if !loadGame.file_exists("user://Saves/"+savename+".sve"):
		print ("File not found! Aborting...")
		return -1
	loadGame.open("user://Saves/"+savename+".sve", File.READ)

	var file_text = loadGame.get_as_text()
	var current_line = parse_json(file_text)
	
	var aux_dir = current_line["worldMap"]
	for key in aux_dir.keys():
		biome_parameters[StringHelper.string_to_vector2(key)] = aux_dir[key]
	#biome_parameters = current_line["worldMap"]
	aux_dir = current_line["airMasses"]
	for key in aux_dir.keys():
		air_masses[int(key)] = aux_dir[key]
		
	loadGame.close()
		

func _ready():
	$buttonClick.play(0)
	
	var dir = Directory.new()
	if !dir.dir_exists("user://Saves"):
		dir.open("user://")
		dir.make_dir("user://Saves")
	#debug_generate()



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	mouse_map_information()
	#pass
	

func game_generate():
	$biomeMap.clear()
	randomize()
	noise_seed = randi()
	noise.seed = noise_seed
	noise.octaves = octaves
	noise.period = period
	noise.persistence = persistence
	noise.lacunarity = lacunarity
	
	temperature_noise.seed = randi()
	temperature_noise.octaves = octaves
	temperature_noise.period = period
	temperature_noise.persistence = persistence/2
	temperature_noise.lacunarity = lacunarity
	
	rain_noise.seed = randi()
	rain_noise.octaves = octaves/2
	rain_noise.period = period*1.25
	rain_noise.persistence = persistence/2
	rain_noise.lacunarity = lacunarity-0.5
	
	#First map generation
	for x in range(0,size_x):
		for y in range(0,size_y):
				var height = noise.get_noise_2d(x,y) * height_modifier
				var adjusted_temperature = modify_temperature(temperature_noise.get_noise_2d(x,y), height,y)
				var adjusted_rain = modify_rain(rain_noise.get_noise_2d(x,y),height)
				var biome = set_biome(height,adjusted_rain,adjusted_temperature)
				biome_parameters[Vector2(x,y)] = [adjusted_temperature,adjusted_rain,biome,height]
	
	#generate 10 air masses
	for i in range(0,10):
		game_generate_air_mass()
	#draw biome map
	draw_biomes()
	generated = true
func game_generate_air_mass():
	randomize()
	
	var start_quadrant = generate_quadrant() # start and end quadrants used to calculate the trajectory the wind may travel
	var end_quadrant = generate_quadrant() 
	var start_point = generate_quadrant_point(start_quadrant)
	var directions = get_air_direction(start_quadrant,end_quadrant)
	
	
	
	
	# Individual air mass configuration
	var air_mass = Line2D.new()
	var temp_point : Vector2 = Vector2(0,0)
	air_mass.add_point(start_point*4)
	air_mass.set_begin_cap_mode(1) #square
	air_mass.set_end_cap_mode(2) #round
	air_mass.set_default_color(Color( 1,1, 1, 1 ))
	air_mass.set_width(4.0)
	air_mass.set_position(Vector2(0,0))
	air_mass.set_visible(true)
	var points = []
	speed = size_x/2 + randi() % size_x #Speed is the max amount of points each air mass may have. Could the variable be named distance? Yes, but Im lazy so....
	going_up = true
	empty_count = 0
	while(temp_point != Vector2(-1,-1)): #While there are still valid options to travel to
		
		temp_point = get_lowest_point(air_mass.get_point_position(air_mass.get_point_count()-1),air_mass, directions) #Is this better, IDK
		if temp_point == Vector2(-1,-1):
			break
		air_mass.add_point(temp_point)
		points.append(temp_point)
	air_masses[air_mass_count] = [temp_point, biome_parameters[start_point][0],biome_parameters[start_point][1]] #This may be used later so I'll store it
	apply_airmass(air_mass)
	air_mass.queue_free()
	#redraw_climate_maps()

func debug_generate():
	$TileMap.clear()
	$rainMap.clear()
	$TemperatureMap.clear()
	randomize()
	noise.seed = noise_seed
	noise.octaves = octaves
	noise.period = period
	noise.persistence = persistence
	noise.lacunarity = lacunarity
	
	temperature_noise.seed = noise_seed +1
	temperature_noise.octaves = octaves
	temperature_noise.period = period
	temperature_noise.persistence = persistence/2
	temperature_noise.lacunarity = lacunarity
	
	rain_noise.seed = noise_seed + 2
	rain_noise.octaves = octaves/2
	rain_noise.period = period*1.25
	rain_noise.persistence = persistence/2
	rain_noise.lacunarity = lacunarity-0.5
	

	
	for x in range(0,size_x):
		for y in range(0,size_y):
				var height = noise.get_noise_2d(x,y) * height_modifier
				var adjusted_temperature = modify_temperature(temperature_noise.get_noise_2d(x,y), height,y)
				var adjusted_rain = modify_rain(rain_noise.get_noise_2d(x,y),height)
				var biome = set_biome(height,adjusted_rain,adjusted_temperature)
				tile = get_tile_color(height) #This will probably be changed to include more biomes
				rain_tile = get_rain_color(adjusted_rain)
				
				
				temperature_tile = get_temperature_color(adjusted_temperature)
				randomize()
				biome_parameters[Vector2(x,y)] = [adjusted_temperature,adjusted_rain,biome,height] #values are (temperature,rain,type,avg_height)
				#print(biome_parameters[Vector2(x,y)])
				$TileMap.set_cell(x,y-size_y,tile)
				$TemperatureMap.set_cell(x-size_x,y-size_y,temperature_tile)
				$rainMap.set_cell(x-size_x,y,rain_tile)
	redraw_climate_maps()

func mouse_map_information():
	var mousePosition = $biomeMap.world_to_map(get_global_mouse_position())
	if generated == true:
		if(mousePosition.x >= 0 and mousePosition.x < size_x and mousePosition.y >= 0 and mousePosition.y < size_y):
			var biome = print_biome(biome_parameters[Vector2(mousePosition.x,mousePosition.y)][2])
			var color = biome_color_code(biome_parameters[Vector2(mousePosition.x,mousePosition.y)][2])
			var bbcode = "[center][color=" + color + "]" + biome + "," + "(" + String(mousePosition.x) +"," + String(mousePosition.y)+")"+ "[/color][/center]"
			$tileInformation/Control/MarginContainer/VBoxContainer/biomeXY.bbcode_text = bbcode



func generate_quadrant():
	return randi() % 4 #0 = top-left, 1 = top-right, 2 = bottom-left, 3 = bottom-right
	
func generate_quadrant_point(quadrant):  #Generates a random point inside chosen quadrant
	match quadrant:
		0: return Vector2(randi()%size_x/2,randi()%size_y/2)
		1: return Vector2(randi()%size_x/2 + size_x/2,randi()%size_y/2)
		2: return Vector2(randi()%size_x/2,randi()%size_y/2 + size_y/2)
		3: return Vector2(randi()%size_x/2 + size_x/2,randi()%size_y/2 + size_y/2)

func get_air_direction(start,end):
	var direction_dictionary = { #Little Gambiarra I did, it works
	Vector2(0,0):[Vector2(1,-1),Vector2(1,0),Vector2(1,1)],
	Vector2(0,1):[Vector2(1,-1),Vector2(1,0),Vector2(1,1)],
	Vector2(0,2):[Vector2(0,1),Vector2(-1,1),Vector2(1,1)],
	Vector2(0,3):[Vector2(1,1),Vector2(0,1),Vector2(1,0)],
	Vector2(1,0):[Vector2(-1,-1),Vector2(-1,0),Vector2(-1,1)],
	Vector2(1,1):[Vector2(0,1),Vector2(-1,1),Vector2(1,1)],
	Vector2(1,2):[Vector2(-1,1),Vector2(0,1),Vector2(-1,0)],
	Vector2(1,3):[Vector2(0,1),Vector2(-1,1),Vector2(1,1)],
	Vector2(2,0):[Vector2(0,-1),Vector2(1,-1),Vector2(-1,-1)],
	Vector2(2,1):[Vector2(1,-1),Vector2(0,-1),Vector2(1,0)],
	Vector2(2,2):[Vector2(0,-1),Vector2(1,-1),Vector2(-1,-1)],
	Vector2(2,3):[Vector2(1,-1),Vector2(1,0),Vector2(1,1)],
	Vector2(3,0):[Vector2(-1,-1),Vector2(0,-1),Vector2(-1,0)],
	Vector2(3,1):[Vector2(0,-1),Vector2(-1,-1),Vector2(1,-1)],
	Vector2(3,2):[Vector2(-1,-1),Vector2(-1,0),Vector2(-1,1)],
	Vector2(3,3):[Vector2(1,-1),Vector2(1,0),Vector2(1,1)],
	}
	return direction_dictionary[Vector2(start,end)]
	
func debug_generate_air_mass():
	randomize()
	
	var start_quadrant = generate_quadrant() # start and end quadrants used to calculate the trajectory the wind may travel
	var end_quadrant = generate_quadrant() 
	var start_point = generate_quadrant_point(start_quadrant)
	var directions = get_air_direction(start_quadrant,end_quadrant)
	
	
	
	
	# Individual air mass configuration
	var air_mass = Line2D.new()
	var temp_point : Vector2 = Vector2(0,0)
	air_mass.add_point(start_point*4)
	air_mass.set_begin_cap_mode(1) #square
	air_mass.set_end_cap_mode(2) #round
	air_mass.set_default_color(Color( 1,1, 1, 1 ))
	air_mass.set_width(4.0)
	air_mass.set_position(Vector2(0,0))
	air_mass.set_visible(true)
	
	speed = size_x/2 + randi() % size_x #Speed is the max amount of points each air mass may have. Could the variable be named distance? Yes, but Im lazy so....
	going_up = true
	empty_count = 0
	while(temp_point != Vector2(-1,-1)): #While there are still valid options to travel to
		
		temp_point = get_lowest_point(air_mass.get_point_position(air_mass.get_point_count()-1),air_mass, directions) #Is this better, IDK
		if temp_point == Vector2(-1,-1):
			break
		air_mass.add_point(temp_point)
	
	
	#print("###########################")
	add_child(air_mass)
	air_masses[air_mass_count] = [air_mass, biome_parameters[start_point][0],biome_parameters[start_point][1]] #This may be used later so I'll store it
	#print(air_masses[air_mass_count])
	
	
	
	var temp_array =[]
	var rain_array = []
	var acc1 = 0
	var acc2 = 0
	for key in biome_parameters.keys():
		temp_array.append(biome_parameters[key][0])
		acc1 += biome_parameters[key][0]
		rain_array.append(biome_parameters[key][1])
		acc2 = biome_parameters[key][1]
		

	
	
	
	
	#######DEBUGGING#####
	
	temp_array.sort()
	rain_array.sort()
	print("temp:",temp_array[0], " " ,acc1/temp_array.size()," " ,temp_array[-1])
	print("rain:",rain_array[0], " " , acc2/rain_array.size(), " ",rain_array[-1])
	####################
	apply_airmass(air_mass)
	redraw_climate_maps()
func get_lowest_point(current_point, air_mass, directions): #Find lowest point from its neighbours. This creates the air mass flow
	#Current point is divided by 4 so that we can get height informations from the tilemap, which has 4 pixel tiles
	
	var cur_by4 = current_point/4
	
	var neighbour_list = []
	for point in directions: #We use that direction dictionary here.
		var neighbour = cur_by4 + point
		if neighbour.x >= 0 and neighbour.y >= 0 and neighbour.x < size_x and neighbour.y < size_y:
			if(!find_point(neighbour,air_mass)):
				neighbour_list.append([neighbour,biome_parameters[neighbour][3]])
	
	neighbour_list.sort_custom(customSort,"sort_second") #All neighbours that are not already on the line are added and sorted by height	
	if(neighbour_list.empty()):
		return Vector2(-1,-1)
	if speed > 0:
		speed -= 1
		return neighbour_list[0][0]*4
	else:
		return Vector2(-1,-1)

func find_point(point,line):
	for i in line.get_point_count():
		if point == line.get_point_position(i):
			return true
	return false
	

func set_biome(height,rain,temperature):
	var t_step = temperature_standard_deviation
	var r_step = rain_standard_deviation
	#var temperature_steps = [0 - 2*t_step,0 - t_step,0, 0 + t_step, 0+t_step*2]
	#var rain_steps = [0 - 2*r_step,0 - r_step,0, 0 + r_step, 0+r_step*2]
	var temperature_steps = [-0.5,-0.25,0,0.25, 0.5]
	var rain_steps = [-0.5,-0.25,0,0.25, 0.5]
	if(height < 0):
		if height > -0.05:
			return biomes.SHALLOW_WATER
		elif height > -0.1:
			return biomes.AVERAGE_WATER
		else:
			return biomes.DEEP_WATER
	else:
		if(temperature >= temperature_steps[4]):
			if rain >= rain_steps[4]:
				return biomes.RAIN_FOREST
			elif rain >= rain_steps[3]:
				return biomes.FLOODED_SAVANNA
			elif rain >= rain_steps[2]:
				return biomes.BROADLEAF_DRY
			elif rain >= rain_steps[1]:
				return biomes.CAATINGA
			else:
				return biomes.DESERT
		elif(temperature >= temperature_steps[3]):
			if rain >= rain_steps[4]:
				return biomes.SWAMP
			elif rain >= rain_steps[3]:
				return biomes.BROADLEAF
			elif rain >= rain_steps[2]:
				return biomes.PINE_TROPICAL
			elif rain >= rain_steps[1]:
				return biomes.SHRUBLAND
			else:
				return biomes.SAVANNA
		elif(temperature >= temperature_steps[2]):
			if rain >= rain_steps[4]:
				return biomes.MIXED_FOREST
			elif rain >= rain_steps[3]:
				return biomes.LAKES
			elif rain >= rain_steps[2]:
				return biomes.BEACH
			elif rain >= rain_steps[1]:
				return biomes.PLAINS
			else:
				return biomes.BADLAND
		elif(temperature >= temperature_steps[1]):
			if rain >= rain_steps[4]:
				return biomes.TAIGA
			elif rain >= rain_steps[3]:
				return biomes.MEADOW
			elif rain >= rain_steps[2]:
				return biomes.COLD_PLAINS
			elif rain >= rain_steps[1]:
				return biomes.ROCKS
			else:
				return biomes.FROZEN_SHRUBLAND
		else:
			if rain >= rain_steps[4]:
				return biomes.TUNDRA
			elif rain >= rain_steps[3]:
				return biomes.GROVE
			elif rain >= rain_steps[2]:
				return biomes.COLD_MEADOW
			elif rain >= rain_steps[1]:
				return biomes.FROZEN
			else:
				return biomes.COLD_DESERT
				
func draw_biomes():
	for x in range(0,size_x):
		for y in range(0,size_y):
			$biomeMap.set_cell(x,y,biome_parameters[Vector2(x,y)][2])

func get_tile_color(perlin): #Tile color is chosen by its height, using its noise value
	if perlin > 0.8:
		return 5
	elif perlin > 0.6:
		return 1
	elif perlin > 0.4:
		return 4
	elif perlin > 0.3:
		return 13
	elif perlin > 0.15:
		return 12
	elif perlin > 0.03:
		return 11
	elif perlin > 0:
		return 8
	elif perlin > -0.05:
		return 17
	elif perlin > -0.1:
		return 15
	else:
		return 16
func get_rain_color(perlin):
	if perlin > 0.8:
		return 0
	elif perlin > 0.6:
		return 1
	elif perlin > 0.4:
		return 2
	elif perlin > 0.3:
		return 3
	elif perlin > 0.20:
		return 4
	elif perlin > 0.15:
		return 5
	elif perlin > 0.1:
		return 6
	elif perlin > 0.05:
		return 7
	elif perlin > 0:
		return 8
	elif perlin > -0.05:
		return 9
	elif perlin > -0.1:
		return 10
	elif perlin > -0.15:
		return 11
	elif perlin > -0.20:
		return 12
	elif perlin > -0.3:
		return 13
	elif perlin > -0.4:
		return 14
	elif perlin > -0.6:
		return 15
	else:
		return 16
func get_temperature_color(temperature):
	if temperature > 0.8:
		return 16
	elif temperature > 0.6:
		return 15
	elif temperature > 0.4:
		return 14
	elif temperature > 0.3:
		return 13
	elif temperature > 0.20:
		return 12
	elif temperature > 0.15:
		return 11
	elif temperature > 0.1:
		return 10
	elif temperature > 0.05:
		return 9
	elif temperature > 0:
		return 8
	elif temperature > -0.05:
		return 7
	elif temperature > -0.1:
		return 6
	elif temperature > -0.15:
		return 5
	elif temperature > -0.20:
		return 4
	elif temperature > -0.3:
		return 3
	elif temperature > -0.4:
		return 2
	elif temperature > -0.6:
		return 1
	else:
		return 0


func apply_airmass(airmass):
	var point_dict = {}
	var start_point = airmass.get_point_position(0)/4
	for i in range(0,airmass.get_point_count()): #Need a better solution. Im not sure if storing all points in a list and searching it is viable
		var current_point = airmass.get_point_position(i)/4
		for x in range(-16,16):
			for y in range(-16,16):
				#We look for the closest tiles in range 10 near our point
				var new_point = current_point + Vector2(x,y)
				if new_point.x >= 0 and new_point.y >= 0 and new_point.x < size_x and new_point.y < size_y: #boundary check
					if !(point_dict.has(new_point)):
						var old_temperature = biome_parameters[new_point][0]
						var old_rain = biome_parameters[new_point][1]
						var height = biome_parameters[new_point][3]
						var new_temperature = calculate_new_tile_parameters(old_temperature,biome_parameters[start_point][0],max(x,y))
						var new_rain = calculate_new_tile_parameters(old_rain,biome_parameters[start_point][1],max(x,y))
						var new_type = set_biome(height,new_rain,new_temperature) # replace
						biome_parameters[new_point] = [new_temperature,new_rain,new_type,biome_parameters[new_point][3]] #After all calculations are ready, we update the values
						point_dict[new_point] = 1
	
	
	
func calculate_new_tile_parameters(current_value,modifier,distance): #damn hahaha, is there a better way to do this?
	distance = abs(distance)
	match distance:
		0: return current_value + modifier * 0.8
		1: return current_value + modifier * 0.75
		2: return current_value + modifier * 0.65
		3: return current_value + modifier * 0.5
		4: return current_value + modifier * 0.4
		5: return current_value + modifier * 0.3
		6: return current_value + modifier * 0.2
		7: return current_value + modifier * 0.1
		8: return current_value + modifier * 0.08
		9: return current_value + modifier * 0.07
		10: return current_value + modifier * 0.06
		11: return current_value + modifier * 0.05
		12: return current_value + modifier * 0.03
		13: return current_value + modifier * 0.01
		14: return current_value + modifier * 0.008
		15: return current_value + modifier * 0.004
		16: return current_value + modifier * 0.002
		


func redraw_climate_maps(): #debug function, probably not needed after
	for x in range(0,size_x):
		for y in range(0,size_y):
				
				rain_tile = get_rain_color(biome_parameters[Vector2(x,y)][1])
				temperature_tile = get_temperature_color(biome_parameters[Vector2(x,y)][0])
				$TemperatureMap.set_cell(x-size_x,y-size_y,temperature_tile)
				$rainMap.set_cell(x-size_x,y,rain_tile)
				
	draw_biomes()
func modify_temperature(temperature, height,y):
	
	var exponent : float
	if hemisphere == true:
		exponent = float(y)/size_y
	else:
		exponent = float(-y)/size_y
	if height > 0:
		return temperature + exponent/8 - abs(pow(height,1))
	else:
		 return temperature + exponent/8
func modify_rain(rain, height):
	if height < 0:
		return rain + pow(height,2)*2
	else:
		return rain

func print_biome(value):
	value = int(value)
	match value:
		biomes.AVERAGE_WATER : return "Average ocean"
		biomes.BADLAND : return "Badlands"
		biomes.BEACH : return "Beach"
		biomes.BROADLEAF : return "Broadleaf forest"
		biomes.BROADLEAF_DRY : return "Broadleaf dry"
		biomes.CAATINGA : return "Caatinga"
		biomes.COLD_DESERT : return "Frozen Desert"
		biomes.COLD_MEADOW : return "Cold Meadow"
		biomes.COLD_PLAINS : return "Cold Plains"
		biomes.DEEP_WATER : return "Deep ocean"
		biomes.DESERT : return "Desert"
		biomes.FLOODED_SAVANNA : return "Flooded Savanna"
		biomes.FROZEN : return "Frozen land"
		biomes.FROZEN_SHRUBLAND : return "Frozen shrubland"
		biomes.GROVE : return "Grove"
		biomes.INLAND_WATER : return "Inland water"
		biomes.LAKES : return "Lakes"
		biomes.MEADOW :return "Meadow"
		biomes.MIXED_FOREST : return "Mixed forest"
		biomes.PINE_TROPICAL : return "Pine Forest"
		biomes.PLAINS : return "Plains"
		biomes.RAIN_FOREST : return "Rain Forest"
		biomes.ROCKS : return "Rocky"
		biomes.SAVANNA : return "Savanna"
		biomes.SHALLOW_WATER : return "shallow ocean"
		biomes.SHRUBLAND :return "Shrubland"
		biomes.SWAMP : return "Swamp"
		biomes.TAIGA : return "Taiga"
		biomes.TUNDRA : return "Tundra"

func biome_color_code(value):
	match value:
		biomes.AVERAGE_WATER : return "teal"
		biomes.BADLAND : return "#ff7200"
		biomes.BEACH : return "#ffff99"
		biomes.BROADLEAF : return "#198c19"
		biomes.BROADLEAF_DRY : return "#578c19"
		biomes.CAATINGA : return "#cca667"
		biomes.COLD_DESERT : return "#d0e0e3"
		biomes.COLD_MEADOW : return "#a5d5dc" 
		biomes.COLD_PLAINS : return "#a4ffdf"
		biomes.DEEP_WATER : return "navy"
		biomes.DESERT : return "yellow"
		biomes.FLOODED_SAVANNA : return "#b5f575"
		biomes.FROZEN : return "#9fc5e8"
		biomes.FROZEN_SHRUBLAND : return "#aecad2"
		biomes.GROVE : return "#d9ead3"
		biomes.INLAND_WATER : return "#0688d1"
		biomes.LAKES : return "#0688d1"
		biomes.MEADOW : return "#90cdc3"
		biomes.MIXED_FOREST : return "green"
		biomes.PINE_TROPICAL : return "#327a32"
		biomes.PLAINS : return "lime"
		biomes.RAIN_FOREST : return "#005900"
		biomes.ROCKS : return "#999999"
		biomes.SAVANNA : return "#d8f08b"
		biomes.SHALLOW_WATER : return "aqua"
		biomes.SHRUBLAND : return "#e79616"
		biomes.SWAMP : return "#78975e"
		biomes.TAIGA : return "#a1e2c0"
		biomes.TUNDRA : return "white"
		
func get_save_files():
	var files = []
	var dir = Directory.new()
	dir.open("user://Saves")
	dir.list_dir_begin(true)
	
	var file = dir.get_next()
	while file != '':
		files += [file]
		file = dir.get_next()
	return files
func _input(event):
	if event is InputEventMouseMotion:
		mouse_map_information()






func _on_save_pressed():
	var save_files = get_save_files()
	if save_files.size() == 0:
		save("world0")
	else:
		var savename = "world" + String(save_files.size())
		save(savename)
	pass # Replace with function body.


func _on_load_pressed():
	print(game_name)
	var err = load_game(game_name)
	if err == -1:
		"Error opening save"
	else:
		redraw_climate_maps()
	

func _on_worlds_pressed():
	if saves_updated == false:
		var existing_games = get_save_files()
		if existing_games.size() != 0:
			for game in existing_games:
				game = game.left(game.length()-4)
				$GUI/saveLoad/VBoxContainer/HBoxContainer/worlds.add_item(game)
		saves_updated = true


func _on_worlds_item_selected(index):
	game_name = $GUI/saveLoad/VBoxContainer/HBoxContainer/worlds.get_item_text(index)
	pass # Replace with function body.


#########################################USER INTERFACE SIGNALS##########################
func _on_generate_pressed():
	game_generate()

func _on_Small_toggled(button_pressed):
	$buttonToggle.play()
	if button_pressed == true:
		size_x = 128
		size_y = 128
		$HUD/UI/buttons/VBoxContainer/SizeButtons/Medium.pressed = false
		$HUD/UI/buttons/VBoxContainer/SizeButtons/Large.pressed = false


func _on_Medium_toggled(button_pressed):
	$buttonToggle.play()
	if button_pressed == true:
		size_x = 256
		size_y = 256
		$HUD/UI/buttons/VBoxContainer/SizeButtons/Small.pressed = false
		$HUD/UI/buttons/VBoxContainer/SizeButtons/Large.pressed = false


func _on_Large_toggled(button_pressed):
	$buttonToggle.play()
	if button_pressed == true:
		size_x = 512
		size_y = 512
		$HUD/UI/buttons/VBoxContainer/SizeButtons/Medium.pressed = false
		$HUD/UI/buttons/VBoxContainer/SizeButtons/Small.pressed = false


func _on_Jagged_toggled(button_pressed):
	
	$buttonToggle.play()
	if button_pressed == true:
		persistence = 0.75
		octaves = 8
		$HUD/UI/buttons/VBoxContainer/coastButtons/Normal.pressed = false
		$HUD/UI/buttons/VBoxContainer/coastButtons/Smooth.pressed = false



func _on_Normal_toggled(button_pressed):
	$buttonToggle.play()
	if button_pressed == true:
		persistence = 0.7
		octaves = 6
		$HUD/UI/buttons/VBoxContainer/coastButtons/Jagged.pressed = false
		$HUD/UI/buttons/VBoxContainer/coastButtons/Smooth.pressed = false


func _on_Smooth_toggled(button_pressed):
	$buttonToggle.play()
	if button_pressed == true:
		persistence = 0.6
		octaves = 5
		$HUD/UI/buttons/VBoxContainer/coastButtons/Normal.pressed = false
		$HUD/UI/buttons/VBoxContainer/coastButtons/Jagged.pressed = false


func _on_Archipelago_toggled(button_pressed):
	$buttonToggle.play()
	if button_pressed == true:
		if size_x == 128:
			period = 25
		elif size_x == 256:
			period = 50
		else:
			period = 150
		lacunarity = 2.2
		$HUD/UI/buttons/VBoxContainer/landButtons/Continental.pressed = false



func _on_Continental_toggled(button_pressed):
	$buttonToggle.play()
	if button_pressed == true:
		if size_x == 128:
			period = 50
		elif size_x == 256:
			period = 100
		else:
			period = 300
		lacunarity = 2
		$HUD/UI/buttons/VBoxContainer/landButtons/Archipelago.pressed = false


func _on_Flatter_toggled(button_pressed):
	$buttonToggle.play()
	if button_pressed == true:
		height_modifier = 0.8
		$HUD/UI/buttons/VBoxContainer/heightButtons/Average.pressed = false
		$HUD/UI/buttons/VBoxContainer/heightButtons/Peaks.pressed = false

func _on_Average_toggled(button_pressed):
	$buttonToggle.play()
	if button_pressed == true:
		height_modifier = 1
		$HUD/UI/buttons/VBoxContainer/heightButtons/Flatter.pressed = false
		$HUD/UI/buttons/VBoxContainer/heightButtons/Peaks.pressed = false

func _on_Peaks_toggled(button_pressed):
	$buttonToggle.play()
	if button_pressed == true:
		height_modifier = 1.3
		$HUD/UI/buttons/VBoxContainer/heightButtons/Average.pressed = false
		$HUD/UI/buttons/VBoxContainer/heightButtons/Flatter.pressed = false
