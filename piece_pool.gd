extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
onready var number_of_possible_pieces = get_child_count();
var piece_to_use = 0;
var piece_node_name;
var piece_instance;


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
	pass

func generate_random_piece():
	#generate number based on root's children pieces number.
	piece_to_use = randi() % number_of_possible_pieces;
	
	#use that number to obtain a random piece node. Then get an instance of the node to use it elsewhere.
	piece_node_name = get_children()[piece_to_use].name;
	piece_instance = load("res://" + piece_node_name + ".tscn").instance();
	
	return piece_instance;