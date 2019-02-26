extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
export var width_in_blocks = 2;
export var height_in_blocks = 3;
onready var animation_player_node = get_node("AnimationPlayer");
var current_animation = "rotate0";
var blocks_position = Array();

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	rotate(0);
	pass

func _process(delta):
	# Called every frame. Delta is time since last frame.
	# Update game logic here.
	#blocks_position = set_blocks_position();
	#print(get_blocks_position());
	pass

func rotate(rotation_degrees):
	var tmp = width_in_blocks;
	width_in_blocks = height_in_blocks;
	height_in_blocks = tmp;
	
	#print("CHILDREN ANTES");
	#print(current_animation);
	#print(get_children()[2].position);
	
	set_animation(rotation_degrees);
	
	#print("CHILDREN DESPUES");
	#print(current_animation);
	#print(get_children()[2].position);
	
	return get_blocks_position();

func set_animation(rotation_degrees):
	current_animation = "rotate" + str(rotation_degrees);
	animation_player_node.play(current_animation);

func change_colour(colour):
	modulate = colour;

func get_blocks_position():
	var children = get_children();
	blocks_position = Array();
	
	for i in children.size():
		if(children[i].get_name().match("*piece*")):
			blocks_position.push_back(children[i].position);
			
	return blocks_position;