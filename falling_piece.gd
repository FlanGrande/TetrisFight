extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
onready var root_node = get_parent();
onready var piece_pool_node = root_node.get_node("piece_pool");

var origin = Vector2(150, 0);
var piece_has_dropped = true;
var piece_node;

export var cell_size = 30;
export var update_rate_in_fps = 60;
var current_update_time = update_rate_in_fps;

func _ready():
	randomize(true)
	# Called every time the node is added to the scene.
	# Initialization here
	reinitialize();
	pass

func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
	if(piece_has_dropped):
		#Code for when a piece drops. Putting it in place and reinitialize position.
		reinitialize();
	else:
		current_update_time -= 1;
		print(current_update_time);
		
		if(current_update_time == 0):
			position.y = position.y + cell_size;
			current_update_time = update_rate_in_fps;
		
	pass

#Puts piece at the top
func reinitialize():
	generate_piece();
	position = origin;
	piece_has_dropped = false;
	current_update_time = update_rate_in_fps;

func generate_piece():
	piece_node = piece_pool_node.generate_random_piece();
	print(visible);
	add_child(piece_node);