extends KinematicBody2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
onready var root_node = get_parent();
onready var field_node = root_node.get_node("field");
onready var piece_pool_node = root_node.get_node("piece_pool");

# Piece variables.
const PIECE_SIDES_MAX_LAG = 8;
const PIECE_SIDES_MIN_LAG = 2;
const PIECE_DOWN_MAX_LAG = 2;
const PIECE_DOWN_MIN_LAG = 0;
var piece_sides_initial_lag = PIECE_SIDES_MAX_LAG;
var piece_sides_lag = piece_sides_initial_lag;
var piece_down_initial_lag = PIECE_SIDES_MIN_LAG;
var piece_down_lag = piece_down_initial_lag;
var spawn = Vector2(150, 0);
var piece_has_dropped = true;
var piece_instance;
var piece_position = Vector2(0, 0);
var piece_rotation = 0;
var piece_was_rotated = false;
var piece_collision_detection_speed = 300;
var piece_colour = "#ffffff";
var colours = ["#fff500", "#ffffff", "#00f3ff", "#1cffff", "#ff5600"];

# Field variables, this values get overrided with the variable defined in the field script.
var fall_update_rate_in_fps = 60;
var cell_size = 30;
var current_update_time = fall_update_rate_in_fps;
var deltaTime;
var current_matrix_state = Array();

func _ready():
	set_physics_process(true);
	randomize(true);
	# Called every time the node is added to the scene.
	# Initialization here
	spawn = Vector2(field_node.position.x + (field_node.size.x / 2), 0);
	fall_update_rate_in_fps = field_node.fall_update_rate_in_fps;
	cell_size = field_node.cell_size;
	initialize();
	pass

func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
	
	deltaTime = delta;
	
	if(piece_has_dropped):
		#When a piece drops. Put it in spawn place and reinitialize position.
		initialize();
	
	movement_checks();
	rotation_checks();
	
	update_current_matrix_state();
	
	pass

func _physics_process(delta):
	#if(current_update_time == 1):
	#	if(get_collisions()["bottom"]):
	#		place_piece();
	collision_checks();
	
	pass

# Puts piece at the top.
func initialize():
	generate_piece();
	position = spawn;
	rotation_degrees = 0;
	piece_instance.rotate(0);
	piece_rotation = 0;
	piece_has_dropped = false;
	
	current_update_time = fall_update_rate_in_fps;
	piece_sides_initial_lag = PIECE_SIDES_MAX_LAG;
	piece_down_initial_lag = PIECE_DOWN_MAX_LAG;
	
	update_current_matrix_state();

# Generate a piece for the player.
func generate_piece():
	piece_colour = Color(colours[randi() % colours.size()]);
	piece_instance = piece_pool_node.generate_random_piece();
	piece_instance.change_colour(piece_colour);
	add_child(piece_instance);

# Update fall of the piece and check player input.
func movement_checks():
	up_pressed_checks();
	down_pressed_checks();
	left_or_right_pressed_checks();

func rotation_checks():
	if(Input.is_action_just_pressed("rotate_clockwise") or Input.is_action_just_pressed("rotate_anticlockwise")):
		var rotation_in_degrees = 90;
		var can_rotate = check_if_piece_can_rotate();
		
		if(can_rotate):
			if(Input.is_action_just_pressed("rotate_clockwise")):
				rotate_piece(rotation_in_degrees);
			else:
				if(Input.is_action_just_pressed("rotate_anticlockwise")):
					rotate_piece(-1 * rotation_in_degrees);
		
		#Prevent piece from being placed after the player rotated it.
		var collide_bottom = get_collisions()["bottom"];
		
		if(collide_bottom):
			current_update_time = fall_update_rate_in_fps;

func check_if_piece_can_rotate():
	var collide_left = get_collisions()["left"];
	var collide_right = get_collisions()["right"];
	var can_rotate = not (collide_left and collide_right);
	var is_the_piece_thin_enough_to_rotate = piece_instance.width_in_blocks >= piece_instance.height_in_blocks;
	
	if(not can_rotate and is_the_piece_thin_enough_to_rotate):
		can_rotate = true;
	
	#TO DO fix this
	#return can_rotate;
	return true;

func rotate_piece(rotation_in_degrees):
	piece_rotation += rotation_in_degrees;
	
	if(piece_rotation >= 360):
		piece_rotation -= 360;
	else:
		if(piece_rotation < 0):
			piece_rotation += 360;
	
	piece_instance.rotate(piece_rotation);
	piece_was_rotated = true;
	
	var collisions = get_collisions();
	
	update_current_matrix_state();

# Check boundaries, placement of the piece.
func collision_checks():
	if(piece_was_rotated):
		var collisions = get_collisions();
		
		print("position antes: " + str(field_node.pos2cell(position)));
		#brute_force_reposition(free_spaces_array);
		brute_force_reposition_alt();
		print("position después: " + str(field_node.pos2cell(position)));
		piece_was_rotated = false;
	
	var left_wall_x = field_node.left_wall_position_x;
	var right_wall_x = field_node.right_wall_position_x;
	var bottom_wall_y = field_node.bottom_wall_position_y;
	
	if(position.x <= left_wall_x):
		position.x = left_wall_x;
	else:
		if(position.x > right_wall_x):
			position.x = right_wall_x;
	
	if(position.y > bottom_wall_y):
		position.y = bottom_wall_y;

func up_pressed_checks():
	if(Input.is_action_just_pressed("ui_up")):
		while(not get_collisions()["bottom"]):
			move("down");
		
		current_update_time = 0;
		place_piece();

func down_pressed_checks():
	#if you keep pressing, the piece starts falling faster.
	if(Input.is_action_pressed("ui_down")):
		piece_down_lag -= 1;
		
		if(piece_down_lag == 0):
			if(get_collisions()["bottom"]):
				place_piece();
			move("down");
			piece_down_lag = PIECE_DOWN_MAX_LAG;
	else:
		piece_down_lag = PIECE_DOWN_MAX_LAG;
		
		current_update_time -= 1;
		
		if(current_update_time == 0):
			if(get_collisions()["bottom"]):
				place_piece();
			move("down");
			current_update_time = fall_update_rate_in_fps;
	
	if(Input.is_action_just_released("ui_down")):
		if(get_collisions()["bottom"]):
			place_piece();
		move("down");
		current_update_time = fall_update_rate_in_fps;

func left_or_right_pressed_checks():
	if(Input.is_action_just_released("ui_left") or Input.is_action_just_released("ui_right")):
		piece_sides_lag = 0;
	
	if(Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right")):
		piece_sides_lag -= 1;
		
		if(piece_sides_lag < 0):
			piece_sides_lag = 0;
			
		if(Input.is_action_pressed("ui_left")):
			if(piece_sides_lag == 0):
				if(not get_collisions()["left"]):
					move("left");
				piece_sides_lag = piece_sides_initial_lag;
				piece_sides_initial_lag /= 2;
				
		if(Input.is_action_pressed("ui_right")):
			if(piece_sides_lag == 0):
				if(not get_collisions()["right"]):
					move("right");
				piece_sides_lag = piece_sides_initial_lag;
				piece_sides_initial_lag /= 2;
	else:
		piece_sides_initial_lag = PIECE_SIDES_MAX_LAG;
		piece_sides_lag = piece_sides_initial_lag;
	
	if(Input.is_action_just_released("ui_left")):
		if(not get_collisions()["left"]):
			move("left");
		piece_sides_lag = 0;
	
	if(Input.is_action_just_released("ui_right")):
		if(not get_collisions()["right"]):
			move("right");
		piece_sides_lag = 0;

func move(direction):
	if(direction == "up"):
		position.y -= cell_size;
	
	if(direction == "right"):
		position.x += cell_size;
	
	if(direction == "down"):
		position.y += cell_size;
	
	if(direction == "left"):
		position.x -= cell_size;
	
	if(not Input.is_action_just_pressed("ui_up")):
		update_current_matrix_state();

func move_to_position_in_matrix(target_position):
	position = target_position;

func get_collisions():
	var collision_dict = {
		"top": false,
		"right": false,
		"bottom": false,
		"left": false
	}
	
	collision_dict["top"] = check_if_piece_will_collide(Vector2(0, -1 * piece_collision_detection_speed));
	collision_dict["right"] = check_if_piece_will_collide(Vector2(piece_collision_detection_speed, 0));
	collision_dict["bottom"] = check_if_piece_will_collide(Vector2(0,  piece_collision_detection_speed));
	collision_dict["left"] = check_if_piece_will_collide(Vector2(-1 * piece_collision_detection_speed, 0));
	
	return collision_dict;

func check_if_piece_will_collide(speed):
	var collision_info = piece_instance.test_move(get_transform(), speed * deltaTime);
	return collision_info;

# Returns an array of Vector2 containing all free positions.
# A free position means a square of the size of the piece that's completely empty (including the empty blocks).
func search_free_spaces(piece):
	update_current_matrix_state();
	var free_spaces = Array();
	var piece_height = piece.height_in_blocks;
	var piece_width = piece.width_in_blocks;
	
	var position_x = position.x - field_node.position.x;
	var position_y = position.y - field_node.position.y;
	
	# These are used to make sure the block will be in a position aligned to the grid.
	var piece_offset_x = int(position_x) % cell_size;
	var piece_offset_y = int(position_y) % cell_size;
	
	# Dividing by cell_size gives us the position in the matrix.
	var column_in_matrix = (position_x - piece_offset_x) / cell_size;
	var row_in_matrix = (position_y - piece_offset_y) / cell_size;
	
	var search_size = Vector2(2, 2);
	
	var search_x_min = max(0, column_in_matrix - search_size.x);
	var search_x_max = min(column_in_matrix + search_size.x, field_node.width_in_cells);
	
	var search_y_min = max(0, row_in_matrix - search_size.y);
	var search_y_max = min(row_in_matrix + search_size.y, field_node.height_in_cells);
	
	#TO DO: try row and col changes.
	for row in range(search_y_min, search_y_max):
		for col in range(search_x_min, search_x_max):
			var is_free_space = is_this_free_space(row, col, piece);
			#print(is_free_space);
			
			if(is_free_space):
				free_spaces.push_back(is_free_space);
	
	return free_spaces;

func is_this_free_space(row, col, piece):
	var free_space = false;
	var is_free = true;
	
	var search_x_min = max(0, col);
	var search_x_max = min(col + piece.width_in_blocks, field_node.width_in_cells);
	
	var search_y_min = max(0, row);
	var search_y_max = min(row + piece.height_in_blocks, field_node.height_in_cells);
	
	for i in range(search_x_min, search_x_max):
		for j in range(search_y_min, search_y_max):
			if(current_matrix_state[j][i] != 0):
				is_free = false;
				break;
			
			if(is_free):
				free_space = Vector2(col, row);
	
	return free_space;

func get_closest_free_space(free_spaces_array):
	var closest_free_space = Vector2();
	
	if(free_spaces_array.size() > 0):
		var piece_current_position = field_node.pos2cell(position);
		closest_free_space = free_spaces_array[0];
		
		for i in free_spaces_array.size() - 1:
			var piece_to_A_distance = piece_current_position.distance_to(closest_free_space);
			var piece_to_B_distance = piece_current_position.distance_to(free_spaces_array[i + 1]);
			
			if(piece_to_A_distance <= piece_to_B_distance):
				closest_free_space = closest_free_space;
			else:
				closest_free_space = free_spaces_array[i + 1];
	
	closest_free_space = field_node.cell2pos(closest_free_space);
	#print(closest_free_space + Vector2(field_node.left_wall_position_x, 0));
	
	return closest_free_space;

func find_Vector2_in_array(what, array):
	if(array.size() > 0):
		for i in array.size():
			if(array[i] == what):
				return i;

func sort_array_by_distance_to_origin(free_spaces_array):
	var free_spaces_array_copy = field_node.duplicate_object(free_spaces_array);
	var sorted_array = Array();
	
	if(free_spaces_array_copy.size() > 0):
		for i in free_spaces_array_copy.size():
			var closest_space = get_closest_free_space(free_spaces_array_copy);
			var closest_space_pos = find_Vector2_in_array(field_node.pos2cell(closest_space), free_spaces_array_copy);
			sorted_array.push_back(free_spaces_array_copy[closest_space_pos]);
			free_spaces_array_copy.remove(closest_space_pos);
	
	return sorted_array;

func brute_force_reposition(free_spaces_array):
	var sorted_free_spaces_array = sort_array_by_distance_to_origin(free_spaces_array);
	var is_colliding = true;
	
	#sorted_free_spaces_array.pop_front();
	#print(sorted_free_spaces_array);
	update_current_matrix_state();
	
	if(sorted_free_spaces_array.size() > 0):
		var tmp_pieces_instance_position = piece_instance.position;
		var pos = field_node.cell2pos(sorted_free_spaces_array[0]);
		piece_instance.position = pos;
		is_colliding = field_node.is_piece_colliding(piece_instance, current_matrix_state);
	
		piece_instance.position = tmp_pieces_instance_position;
		
		for i in sorted_free_spaces_array.size():
			tmp_pieces_instance_position = piece_instance.position;
			pos = field_node.cell2pos(sorted_free_spaces_array[i]);
			piece_instance.position = pos;
			
			if(field_node.is_piece_colliding(piece_instance, current_matrix_state)):
				move_to_position_in_matrix(field_node.cell2pos(sorted_free_spaces_array[i]));
				update_current_matrix_state();
				piece_instance.position = pos;
				break;
			piece_instance.position = tmp_pieces_instance_position;
	
	#field_node.print_matrix(current_matrix_state);

func brute_force_reposition_alt():
	update_current_matrix_state();
	var found_space = false;
	var piece_height = piece_instance.height_in_blocks;
	var piece_width = piece_instance.width_in_blocks;
	
	var original_position = field_node.pos2cell(position);
	#print(original_position);
	
	var search_size = Vector2(3, 2);
	
	var search_x_min = max(0, original_position.x - search_size.x);
	var search_x_max = min(original_position.x + search_size.x, field_node.width_in_cells);
	
	var search_y_min = max(0, original_position.y - search_size.y);
	var search_y_max = min(original_position.y + search_size.y, field_node.height_in_cells);
	
	#print("HOLA");
	#print(Vector2(search_x_min, search_x_max));
	#print(Vector2(search_y_min, search_y_max));
	
	var tmp_pieces_instance_position = piece_instance.position;
	var previous_position = Vector2(search_x_min, search_y_min);
	#print(previous_position);
	
	piece_instance.position = position;
	
	print(field_node.is_piece_colliding(piece_instance));
	var closest_distance = original_position.distance_to(field_node.pos2cell(previous_position));
	
	if(field_node.is_piece_colliding(piece_instance)):
		for i in range(search_x_min, search_x_max):
			for j in range(search_y_min, search_y_max):
				var new_position = field_node.cell2pos(Vector2(i, j));
				move_to_position_in_matrix(new_position);
				piece_instance.position = new_position;
				
				if(field_node.is_piece_colliding(piece_instance)):
					var distance_to_new_pos = original_position.distance_to(field_node.pos2cell(new_position));
					var distance_to_prev_pos = original_position.distance_to(field_node.pos2cell(previous_position));
					
					#print("HEY");
					#print(new_position);
					#print(previous_position);
					#print(closest_distance);
					
					if(distance_to_new_pos == closest_distance):
						move_to_position_in_matrix(new_position);
					else:
						move_to_position_in_matrix(previous_position);
						new_position = previous_position;
					
					found_space = true;
				
				#if(not found_space):
				#	move_to_position_in_matrix(original_position);
				
				previous_position = new_position;
	
	piece_instance.position = tmp_pieces_instance_position;
	
	#if(not found_space):
	#	move_to_position_in_matrix(original_position);
	
	pass

func update_current_matrix_state():
	#piece_instance.position = position;
	
	#if(current_update_time == 0): 
	#	print("matrix:");
	#	field_node.print_matrix(field_node.get_clean_matrix());
	
	#current_matrix_state = field_node.get_matrix_with_falling_piece(piece_instance);
	current_matrix_state = field_node.update_clean_matrix();
	#piece_instance.position = Vector2(0, 0);

# Add the piece in field_node as child.
func place_piece():
	piece_instance.position = position;
	field_node.place_piece(piece_instance, piece_colour);
	#field_node.print_fixed_pieces_matrix();
	remove_child(piece_instance);
	initialize();