extends Camera2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var mouse_start_pos
var screen_start_position

var dragging = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	get_mouse_input()
	
func get_mouse_input():
	
	if Input.is_action_just_released("mouse_wheel_up"):
		#zoom_pos = get_global_mouse_position()
		self.zoom -= Vector2(0.1,0.1)
	if Input.is_action_just_released("mouse_wheel_down"):
		#zoom_pos = get_global_mouse_position()
		self.zoom += Vector2(0.1,0.1)
	
func _input(event):
	if event.is_action("drag"):
		if event.is_pressed():
			mouse_start_pos = event.position
			screen_start_position = position
			dragging = true
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		position = zoom * (mouse_start_pos - event.position) + screen_start_position
