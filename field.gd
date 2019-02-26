extends Node2D

# Screen and game field variables
export var cell_size = 30;
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
export var height_in_cells = 30;
export var width_in_cells = 10;
var pieces_matrix; #This matrix has 0 and block_instances path_to.
var clean_matrix; #This matrix is like pieces_matrix, but has 1 instead of Block Nodes.

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	initialize_walls_and_origin();
	initialize_matrix();
	pass

func _process(delta):
	# Called every frame. Delta is time since last frame.
	# Update game logic here.
	clear_completed_lines();
	pass

# Define boundaries of the playing field.
func initialize_walls_and_origin():
	position = Vector2((window.size.x - width) / 2, 0);
	collision_borders_node.position = position;
	left_wall_position_x = position.x;
	right_wall_position_x = position.x + width;
	bottom_wall_position_y = position.y + height;

func initialize_matrix():
	pieces_matrix = Array();
	
	for row in height_in_cells:
		var tmp_line = Array();
		
		for col in width_in_cells:
			tmp_line.push_back(0);
			
		pieces_matrix.insert(row, tmp_line);

func add_to_matrix(x, y, block_instance):
	if(x >= 0 and y >= 0 and x < width_in_cells and y < height_in_cells):
		pieces_matrix[y][x] = field_node.get_path_to(block_instance); #inverted x and y.
	else:
		print("Bad values in add_to_matrix");

func get_matrix():
	return pieces_matrix;

func update_clean_matrix():
	clean_matrix = clean_matrix(pieces_matrix);
	return clean_matrix;

func get_matrix_with_falling_piece(piece):
	return add_falling_piece_to_matrix(piece, pieces_matrix);

func print_fixed_pieces_matrix():
	print_matrix(pieces_matrix);

func print_matrix(matrix):
	var matrix_copy = duplicate_object(matrix);
	
	for row in height_in_cells:
		for col in width_in_cells:
			if(str(matrix_copy[row][col]) != str(0)):
				matrix_copy[row][col] = 1;
		print(matrix_copy[row]);

# Place the piece into the board.
func place_piece(piece, colour):
	place_piece_on_field(piece, colour);
	#print_matrix();

func transform_into_blocks(piece, offset = false):
	var blocks_array = Array();
	
	var children = piece.get_children();
	#var blocks_position = piece.get_blocks_position();
	
	#print(blocks_position);
	#print("piece_rotation " + str(piece_rotation));
	#print("piece_instance.rotation: " + str(piece.current_animation));
	
	for row in children.size():
		if(children[row].get_name().match("*piece*")):
			var tmp_block = children[row];
			var block_instance = load("res://piece.tscn").instance();
			
			block_instance.position.x = piece.position.x + tmp_block.position.x; #adjust piece coordinates to match field coordinates.
			block_instance.position.y = piece.position.y + tmp_block.position.y; #adjust piece coordinates to match field coordinates.
			block_instance.get_node("StaticBody2D/CollisionShape2D").disabled = false;
			
			#print("bloque:")
			#print(pos2cell(block_instance.position));
			
			if(offset):
				block_instance.position.x -= position.x;
				block_instance.position.y -= position.y;
			
			blocks_array.push_back(block_instance); #.duplicate()
	
	return blocks_array;

func get_block_position_in_matrix(block):
	var position_x = block.position.x;
	var position_y = block.position.y;
	
	return pos2cell(Vector2(position_x, position_y));

func place_piece_on_field(piece, colour):
	var blocks_array = transform_into_blocks(piece);
	
	for row in blocks_array.size():
		var current_block = blocks_array[row];
		var block_position_in_matrix = get_block_position_in_matrix(current_block);
		
		print(block_position_in_matrix);
		
		current_block.change_colour(colour);
		current_block.position.x -= position.x;
		current_block.position.y -= position.y;
		add_child(current_block);
		add_to_matrix(block_position_in_matrix.x, block_position_in_matrix.y, current_block);

# Return matrix with the piece as well.
func add_falling_piece_to_matrix(piece, matrix):
	var blocks_array = transform_into_blocks(piece, true);
	var matrix_copy = duplicate_object(matrix);
	
	for i in blocks_array.size():
		var current_block = blocks_array[i];
		var block_position_in_matrix = get_block_position_in_matrix(current_block);
		
		var position_x_in_matrix = block_position_in_matrix.x;
		var position_y_in_matrix = block_position_in_matrix.y;
		
		if(position_x_in_matrix >= 0 and position_y_in_matrix >= 0 and position_x_in_matrix < width_in_cells and position_y_in_matrix < height_in_cells):
			matrix_copy[position_y_in_matrix][position_x_in_matrix] = 1;
	
	return matrix_copy;

func is_piece_colliding(piece):
	var collision = false;
	var blocks_array = transform_into_blocks(piece);
	#clean_matrix = update_clean_matrix();
	
	#print_matrix(pieces_matrix);
	
	for i in blocks_array.size():
		#blocks_array[i].position += position;
		var block_position_in_matrix = get_block_position_in_matrix(blocks_array[i]);
		var out_of_boundaries = false;
		
		#block_position_in_matrix = Vector2(block_position_in_matrix.x, block_position_in_matrix.y);
		#print(block_position_in_matrix);
		#print(pos2cell(tmp_block.position));
		
		if(block_position_in_matrix.x < 0 or block_position_in_matrix.x >= width_in_cells or block_position_in_matrix.y >= height_in_cells):
			out_of_boundaries = true;
		
			#if(block_position_in_matrix.x < 0):
			#	block_position_in_matrix.x = max(0, block_position_in_matrix.x);
			
			#if(block_position_in_matrix.x >= width_in_cells):
			#	block_position_in_matrix.x = min(block_position_in_matrix.x, width_in_cells - 1);
			
			#if(block_position_in_matrix.y < 0):
			#	block_position_in_matrix.y = max(0, block_position_in_matrix.y);
			
			#if(block_position_in_matrix.y >= height_in_cells):
			#	block_position_in_matrix.y = min(block_position_in_matrix.y, height_in_cells - 1);
		
		#print(block_position_in_matrix.x);
		#print(matrix_copy[block_position_in_matrix.y][block_position_in_matrix.x]);
		if(out_of_boundaries or clean_matrix[block_position_in_matrix.y][block_position_in_matrix.x] == 1):
			#print("hola");
			collision = true;
			break;
	
	return collision;

func clean_matrix(matrix):
	var matrix_copy = duplicate_object(matrix);
	
	for row in matrix_copy.size():
		for col in matrix_copy[row].size():
			if(typeof(matrix[row][col]) == TYPE_NODE_PATH):
				matrix_copy[row][col] = 1;
	
	#print("matrix");
	#print_matrix(matrix_copy);
	
	return matrix_copy;

func slide_lines_from_row(row_number):
	for row in range (row_number, -1, -1):
		for col in width_in_cells:
			if(typeof(pieces_matrix[row][col]) == TYPE_NODE_PATH):
				var tmp_copy = pieces_matrix[row][col];
				get_node(pieces_matrix[row][col]).position.y += cell_size;
				pieces_matrix[row + 1][col] = tmp_copy;
				pieces_matrix[row][col] = 0;

func clear_line(row_number):
	#First we empty the line.
	for col in width_in_cells:
		get_node(pieces_matrix[row_number][col]).queue_free();
		pieces_matrix[row_number][col] = 0;
	
	#Then we move the blocks above the line down.
	slide_lines_from_row(row_number);

func clear_completed_lines():
	for row in height_in_cells:
		var line_is_full = true;
		var row_to_clear = 0;
		
		for col in width_in_cells:
			var pieces_matrix_cell = pieces_matrix[row][col];
			
			if(typeof(pieces_matrix_cell) != TYPE_NODE_PATH):
				line_is_full = false;
			else:
				row_to_clear = row;
		
		if(line_is_full):
			clear_line(row_to_clear);

func duplicate_object(object):
	return str2var(var2str(object));

func pos2cell(position):
	# These are used to make sure the final variables will be in a position aligned to the grid.
	var position_x = position.x - left_wall_position_x;
	var position_y = position.y - 0;
	
	var piece_offset_x = int(position_x) % cell_size;
	var piece_offset_y = int(position_y) % cell_size;
	
	# Dividing by cell_size gives us the position in the matrix.
	var position_x_in_matrix = (position_x - piece_offset_x) / cell_size;
	var position_y_in_matrix = (position_y - piece_offset_y) / cell_size;
	
	return Vector2(position_x_in_matrix, position_y_in_matrix);

func cell2pos(position_in_matrix):
	return Vector2(position_in_matrix.x * cell_size, position_in_matrix.y * cell_size) + position;