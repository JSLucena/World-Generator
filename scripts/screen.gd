extends Camera2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var mouse_start_pos
var screen_start_position
var generator
var dragging = false

# Called when the node enters the scene tree for the first time.
func _ready():
	generator = get_parent()
	pass # Replace with function body.




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	get_mouse_input()
	
func get_mouse_input():
	
	if Input.is_action_just_released("mouse_wheel_up"):
		self.zoom -= Vector2(0.1,0.1)
		
	if Input.is_action_just_released("mouse_wheel_down"):
		if (self.zoom.x < 1.5 and generator.size == generator.sizes.SMALL):
			self.zoom += Vector2(0.1,0.1)
		elif(self.zoom.x < 3.0 and generator.size == generator.sizes.MEDIUM):
			self.zoom += Vector2(0.1,0.1)
		elif(self.zoom.x < 6.0 and generator.size == generator.sizes.LARGE):
			self.zoom += Vector2(0.1,0.1)
	#print(self.zoom)
	
func _input(event):
	if event.is_action("drag"):
		if event.is_pressed():
			mouse_start_pos = event.position
			screen_start_position = position
			dragging = true
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		var aux_pos = zoom * (mouse_start_pos - event.position) + screen_start_position
		var aux_x = aux_pos.x
		var aux_y = aux_pos.y
		aux_y = clamp(aux_y,0,get_parent().size_y*8)
		aux_x = clamp(aux_x,0,get_parent().size_x*8)
		aux_pos = Vector2(aux_x,aux_y)
		position = aux_pos
