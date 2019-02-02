extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
export var width_in_blocks = 2;
export var height_in_blocks = 3;

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func rotate():
	var tmp = width_in_blocks;
	width_in_blocks = height_in_blocks;
	height_in_blocks = tmp;
	pass