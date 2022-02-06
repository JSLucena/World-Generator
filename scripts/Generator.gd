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
export var hemisphere : bool = false # false = south , true = north

var air_masses = {} #Dictionary containing each air mais route,speed, temperature and rain values from the starting point
var air_mass_count : int = 0
var speed : int = 0 # the speed will be used to enable air masses to go up
var going_up : bool = false
var empty_count = 0


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



class customSort:
	static func sort_second(a,b):
		return a[1] < b[1]



func _ready():
	debug_generate()



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	mouse_map_information()
	#pass
	



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
				$TileMap.set_cell(x,y,tile)
				$TemperatureMap.set_cell(x+size_x,y,temperature_tile)
				$rainMap.set_cell(x-size_x,y,rain_tile)
	

func mouse_map_information():
	var mousePosition = $TileMap.world_to_map(get_global_mouse_position())
	if(mousePosition.x >= 0 and mousePosition.x < size_x and mousePosition.y >= 0 and mousePosition.y < size_y):
		$GUI/BiomeInfo/VBoxContainer/height.set_text("average height : " + String(biome_parameters[mousePosition][3]) )
		$GUI/BiomeInfo/VBoxContainer/position.set_text(String(mousePosition) )
		$GUI/BiomeInfo/VBoxContainer/type.set_text(print_biome(biome_parameters[mousePosition][2]))
		$GUI/BiomeInfo/VBoxContainer/temp.set_text("temperature : " + String(biome_parameters[mousePosition][0]) )
		$GUI/BiomeInfo/VBoxContainer/rain.set_text("rain : " + String(biome_parameters[mousePosition][1]) )



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
	
func generate_air_mass():
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
	print(air_masses[air_mass_count])
	apply_airmass(air_mass)
	var temp_array =[]
	var rain_array = []
	for key in biome_parameters.keys():
		temp_array.append(biome_parameters[key][0])
		rain_array.append(biome_parameters[key][1])
	temp_array.sort()
	rain_array.sort()
	print("temp:",temp_array[0], " " , temp_array[-1])
	print("rain:",rain_array[0], " " , rain_array[-1])
	
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
	if(height < 0):
		if height > -0.05:
			return biomes.SHALLOW_WATER
		elif height > -0.1:
			return biomes.AVERAGE_WATER
		else:
			return biomes.DEEP_WATER
	else:
		if(temperature >= 1.0):
			if rain >= 1.0:
				return biomes.RAIN_FOREST
			elif rain >= 0.5:
				return biomes.FLOODED_SAVANNA
			elif rain >= 0:
				return biomes.BROADLEAF_DRY
			elif rain >= -0.5:
				return biomes.CAATINGA
			else:
				return biomes.DESERT
		elif(temperature >= 0.5):
			if rain >= 1.0:
				return biomes.SWAMP
			elif rain >= 0.5:
				return biomes.BROADLEAF
			elif rain >= 0:
				return biomes.PINE_TROPICAL
			elif rain >= -0.5:
				return biomes.SHRUBLAND
			else:
				return biomes.SAVANNA
		elif(temperature >= 0):
			if rain >= 1.0:
				return biomes.MIXED_FOREST
			elif rain >= 0.5:
				return biomes.LAKES
			elif rain >= 0:
				return biomes.BEACH
			elif rain >= -0.5:
				return biomes.PLAINS
			else:
				return biomes.BADLAND
		elif(temperature >= -0.5):
			if rain >= 1.0:
				return biomes.TAIGA
			elif rain >= 0.5:
				return biomes.MEADOW
			elif rain >= 0:
				return biomes.COLD_PLAINS
			elif rain >= -0.5:
				return biomes.ROCKS
			else:
				return biomes.FROZEN_SHRUBLAND
		else:
			if rain >= 1.0:
				return biomes.TUNDRA
			elif rain >= 0.5:
				return biomes.GROVE
			elif rain >= 0:
				return biomes.COLD_MEADOW
			elif rain >= -0.5:
				return biomes.FROZEN
			else:
				return biomes.COLD_DESERT
				
func draw_biomes():
	for x in range(0,size_x):
		for y in range(0,size_y):
			$biomeMap.set_cell(x-size_x,y-size_y,biome_parameters[Vector2(x,y)][2])
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
		for x in range(0,16):
			for y in range(0,16):
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
	redraw_climate_maps()
	
	
func calculate_new_tile_parameters(current_value,modifier,distance): #damn hahaha, is there a better way to do this?
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
				$TemperatureMap.set_cell(x+size_x,y,temperature_tile)
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
	debug_generate()

func _on_flatter_pressed():
	height_modifier = 0.8
func _on_normal_pressed():
	height_modifier = 1.0
func _on_peaks_pressed():
	height_modifier = 1.2


func _on_lacunarity_box_value_changed(value):
	lacunarity = value


func _on_generateAirMass_pressed():
	generate_air_mass()


func _on_Hemisphere_item_selected(index):
	if index == 0:
		hemisphere = false
	elif index == 1:
		hemisphere = true
