extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
export var width_in_blocks = 3;
export var height_in_blocks = 2;
onready var animation_player_node = get_node("AnimationPlayer");

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	rotate(0);
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func rotate(rotation_degrees):
	var tmp = width_in_blocks;
	width_in_blocks = height_in_blocks;
	height_in_blocks = tmp;
	
	animation_player_node.play("rotate" + str(rotation_degrees));
	
	pass

func change_colour(colour):
	modulate = colour;