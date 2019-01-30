extends Node2D

# Screen and game field variables
export var cell_size = 30;
export var height_in_cells = 30;
export var width_in_cells = 10;
export var fall_update_rate_in_fps = 60;
onready var root_node = get_parent();
onready var field_node = root_node.get_node("field");
onready var collision_borders_node = root_node.get_node("collision_borders");
onready var width = cell_size * width_in_cells;
onready var height = cell_size * height_in_cells;
onready var size = Vector2(width, height);
onready var window = get_tree().get_root();
var left_wall_position_x = 0;
var right_wall_position_x = 300;
var bottom_wall_position_y = 900;

# Pieces_matrix variables
var pieces_matrix;
var bottom_line;

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	initialize_walls_and_origin();
	initialize_matrix();
	
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

# Define boundaries of the playing field.
func initialize_walls_and_origin():
	position = Vector2((window.size.x - width) / 2, 0);
	collision_borders_node.position = position;
	left_wall_position_x = position.x;
	right_wall_position_x = position.x + width;
	bottom_wall_position_y = position.y + height;

func initialize_matrix():
	pieces_matrix = Array();
	
	for i in field_node.height_in_cells:
		var tmp_line = Array();
		bottom_line = Array();
		
		for j in field_node.width_in_cells:
			tmp_line.push_back(0);
			bottom_line.push_back(1);
			
		pieces_matrix.insert(i, tmp_line);
	
	pieces_matrix.push_back(bottom_line);

# Place the piece into the board.
func add_piece(piece, rotation_in_degrees):
	piece.position.x = piece.position.x - position.x; #adjust piece coordinates to match field coordinates.
	piece.position.y = piece.position.y - position.y; #adjust piece coordinates to match field coordinates.
	print(rotation_in_degrees);
	#piece.rotation_degrees = rotation_in_degrees; #adjust piece coordinates to match field coordinates.
	add_child(piece);