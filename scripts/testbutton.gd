extends TextureButton


export var size_x = 30
export var size_y = 30
export var text = "[center]Joca's World Generator[/center]"

# Called when the node enters the scene tree for the first time.
func _ready():
	self.set_size(Vector2(size_x,size_y))
	$CenterContainer/text.set_bbcode(text)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
