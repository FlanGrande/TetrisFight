extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
onready var root_node = get_parent();
onready var field_node = root_node.get_node("field");
onready var piece_pool_node = root_node.get_node("piece_pool");

# Piece variables.
const PIECE_SIDES_MAX_LAG = 12;
const PIECE_SIDES_MIN_LAG = 4;
const PIECE_DOWN_MAX_LAG = 12;
const PIECE_DOWN_MIN_LAG = 4;
var piece_sides_initial_lag = PIECE_SIDES_MAX_LAG;
var piece_sides_lag = piece_sides_initial_lag;
var piece_down_initial_lag = PIECE_SIDES_MIN_LAG;
var piece_down_lag = piece_down_initial_lag;
var origin = Vector2(150, 0);
var piece_has_dropped = true;
var piece_instance;
var piece_position = Vector2(0, 0);
var piece_rotation = 0;
var piece_was_rotated = false;
var piece_collision_detection_speed = 300;

# Field variables, this values get overrided with the variable defined in the field script.
var fall_update_rate_in_fps = 60;
var cell_size = 30;
var current_update_time = fall_update_rate_in_fps;
var deltaTime;

func _ready():
	randomize(true);
	# Called every time the node is added to the scene.
	# Initialization here
	origin = Vector2(field_node.position.x + (field_node.size.x / 2 - cell_size), 0);
	fall_update_rate_in_fps = field_node.fall_update_rate_in_fps;
	cell_size = field_node.cell_size;
	reinitialize();
	pass

func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
	deltaTime = delta;
	piece_was_rotated = false;
	
	if(piece_has_dropped):
		#Code for when a piece drops. Put it in spawn place and reinitialize position.
		reinitialize();
	
	movement_checks();
	rotation_checks();
	collision_checks();
	
	pass

func _physics_process():
	if(current_update_time == 1):
		if(get_collisions()["bottom"]):
			place_piece();

# Puts piece at the top.
func reinitialize():
	generate_piece();
	position = origin;
	rotation_degrees = 0;
	piece_instance.rotate(0);
	piece_rotation = 0;
	piece_has_dropped = false;
	current_update_time = fall_update_rate_in_fps;
	piece_sides_initial_lag = PIECE_SIDES_MAX_LAG;
	piece_down_initial_lag = PIECE_DOWN_MAX_LAG;

# Generate a piece for the player.
func generate_piece():
	piece_instance = piece_pool_node.generate_random_piece();
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
	
	return can_rotate;

func rotate_piece(rotation_in_degrees):
	piece_rotation += rotation_in_degrees;
	
	if(piece_rotation >= 360):
		piece_rotation -= 360;
	else:
		if(piece_rotation < 0):
			piece_rotation += 360;
	
	piece_instance.rotate(piece_rotation);
	piece_was_rotated = true;
	
	#if(piece_was_rotated):
	print(piece_rotation);
	check_left_after_rotation(piece_rotation);

# Check boundaries, placement of the piece.
func collision_checks():
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
	
	#TO DO improve collisions.
	#if(piece_was_rotated):
	#	check_left_after_rotation();
	#	do_collision_right_behaviour();

func up_pressed_checks():
	if(Input.is_action_just_pressed("ui_up")):
		while(not get_collisions()["bottom"]):
			move_down();
		
		current_update_time = 0;
		place_piece();

func down_pressed_checks():
	#if you keep pressing, the piece starts falling faster.
	if(Input.is_action_pressed("ui_down")):
		piece_down_lag -= 1;
		
		if(piece_down_lag < 0):
			piece_down_lag = 0;
		
		if(piece_down_lag == 0):
			do_collision_bottom_behaviour();
			move_down();
			piece_down_lag = piece_down_initial_lag;
			piece_down_initial_lag /= 2;
	else:
		piece_down_initial_lag = PIECE_DOWN_MAX_LAG;
		piece_down_lag = piece_down_initial_lag;
		
		current_update_time -= 1;
		
		if(current_update_time == 0):
			do_collision_bottom_behaviour();
			move_down();
			current_update_time = fall_update_rate_in_fps;
	
	if(Input.is_action_just_released("ui_down")):
		do_collision_bottom_behaviour();
		move_down();
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
				do_collision_left_behaviour();
				move_left();
				piece_sides_lag = piece_sides_initial_lag;
				piece_sides_initial_lag /= 2;
				
		if(Input.is_action_pressed("ui_right")):
			if(piece_sides_lag == 0):
				do_collision_right_behaviour();
				move_right();
				piece_sides_lag = piece_sides_initial_lag;
				piece_sides_initial_lag /= 2;
	else:
		piece_sides_initial_lag = PIECE_SIDES_MAX_LAG;
		piece_sides_lag = piece_sides_initial_lag;
	
	if(Input.is_action_just_released("ui_left")):
		do_collision_left_behaviour();
		move_left();
		piece_sides_lag = 0;
	
	if(Input.is_action_just_released("ui_right")):
		do_collision_right_behaviour();
		move_right();
		piece_sides_lag = 0;

func move_down():
	position.y += cell_size;

func move_left():
	position.x -= cell_size;

func move_right():
	position.x += cell_size;

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

func do_collision_bottom_behaviour():
	if(get_collisions()["bottom"]):
		place_piece();

func do_collision_left_behaviour():
	if(get_collisions()["left"]):
		position.x += cell_size;

func do_collision_right_behaviour():
	if(get_collisions()["right"]):
		position.x -= cell_size;

func check_if_piece_will_collide(speed):
	var collision_info = piece_instance.test_move(get_transform(), speed * deltaTime);	
	return collision_info;

func check_if_piece_collides_after_rotation(move_it = true):
	var rotation_in_degrees = 90;
	
	var was_moved = check_left_after_rotation(rotation_in_degrees);
	
	if(not was_moved):
		check_right_after_rotation(rotation_in_degrees);

#TO DO: check rotation BEFORE rotating, rather than correcting afterwards.
###
func test_rotation(rotation_in_degrees):
	pass

func check_left_after_rotation(rotation_in_degrees):
	move_right();
	var collisions_dict_moved_to_right_cell = get_collisions();
	move_left();
	
	var collisions_dict_now = get_collisions();
	
	if(collisions_dict_now["left"]):
		if(collisions_dict_moved_to_right_cell["left"] and not collisions_dict_moved_to_right_cell["right"]):
			if(Input.is_action_just_pressed("rotate_clockwise")):
				rotate_piece(-1 * rotation_in_degrees);
				move_right();
				rotate_piece(rotation_in_degrees);
			else:
				if(Input.is_action_just_pressed("rotate_anticlockwise")):
					rotate_piece(rotation_in_degrees);
					move_right();
					rotate_piece(-1 * rotation_in_degrees);
			
			move_right();
			
			#Fix for Piece_I
			if(piece_instance.width_in_blocks > 3 and piece_rotation == 270):
				move_right();

func check_right_after_rotation(rotation_in_degrees):
	move_left();
	var collisions_dict_moved_to_left_cell = get_collisions();
	move_right();
	
	var collisions_dict_now = get_collisions();
	
	if(collisions_dict_now["right"]):
		if(collisions_dict_moved_to_left_cell["right"] and not collisions_dict_moved_to_left_cell["left"]):
			if(Input.is_action_just_pressed("rotate_clockwise")):
				rotate_piece(-1 * rotation_in_degrees);
				position.x -= cell_size;
				rotate_piece(rotation_in_degrees);
			else:
				if(Input.is_action_just_pressed("rotate_anticlockwise")):
					rotate_piece(rotation_in_degrees);
					position.x -= cell_size;
					rotate_piece(-1 * rotation_in_degrees);
			
			move_left();
			
			#Fix for Piece_I
			if(piece_instance.width_in_blocks > 3 and piece_rotation == 90):
				move_left();

# Add the piece in field_node as child.
func place_piece():
	piece_instance.position = position;
	#piece_instance.rotation_degrees = rotation_degrees;
	field_node.add_piece(piece_instance);
	remove_child(piece_instance);
	reinitialize();