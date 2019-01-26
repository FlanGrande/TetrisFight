extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
onready var root_node = get_parent();
onready var field_node = root_node.get_node("field");
var pieces_matrix;
var bottom_line;

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	pieces_matrix = Array();
	
	for i in field_node.height_in_cells:
		var tmp_line = Array();
		bottom_line = Array();
		
		for j in field_node.width_in_cells:
			tmp_line.push_back(0);
			bottom_line.push_back(1);
			
		pieces_matrix.insert(i, tmp_line);
	
	pieces_matrix.push_back(bottom_line)
	
	print(pieces_matrix);
	
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
