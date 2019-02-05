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
const PIECE_DOWN_MAX_LAG = 15;
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
var piece_collision_detection_speed = 300;

# Field variables, this values get overrided with the variable defined in the field script.
var fall_update_rate_in_fps = 60;
var cell_size = 30;
var current_update_time = fall_update_rate_in_fps;

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
	if(piece_has_dropped):
		#Code for when a piece drops. Put it in spawn place and reinitialize position.
		reinitialize();
	
	movement_checks(delta);
	rotation_checks(delta);
	collision_checks(delta);
	
	pass

func _physics_process(delta):
	if(current_update_time == 1):
		check_if_piece_will_collide(delta);
	
	#check_if_piece_will_collide_at_sides(Vector2(piece_collision_detection_speed, 0), delta);

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
func movement_checks(delta):	
	if(Input.is_action_pressed("ui_down")):
		piece_down_lag -= 1;
		
		if(piece_down_lag < 0):
			piece_down_lag = 0;
		
		if(piece_down_lag == 0):
			check_if_piece_will_collide(delta);
			position.y = position.y + cell_size;
			piece_down_lag = piece_down_initial_lag;
			piece_down_initial_lag /= 2;
	else:
		piece_down_initial_lag = PIECE_DOWN_MAX_LAG;
		piece_down_lag = piece_down_initial_lag;
		
		current_update_time -= 1;
		
		if(current_update_time == 0):
			position.y = position.y + cell_size;
			current_update_time = fall_update_rate_in_fps;
	
	if(Input.is_action_just_released("ui_down")):
		print(position.y);
		check_if_piece_will_collide(delta);
		position.y = position.y + cell_size;
		current_update_time = fall_update_rate_in_fps;
		
	if(Input.is_action_just_released("ui_left") or Input.is_action_just_released("ui_right")):
		piece_sides_lag = 0;
	
	if(Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right")):
		piece_sides_lag -= 1;
		
		if(piece_sides_lag < 0):
			piece_sides_lag = 0;
			
		if(Input.is_action_pressed("ui_left")):
			if(piece_sides_lag == 0):
				check_if_piece_will_collide_at_left(delta);
				position.x = position.x - cell_size;
				piece_sides_lag = piece_sides_initial_lag;
				piece_sides_initial_lag /= 2;
				
		if(Input.is_action_pressed("ui_right")):
			if(piece_sides_lag == 0):
				check_if_piece_will_collide_at_right(delta);
				position.x = position.x + cell_size;
				piece_sides_lag = piece_sides_initial_lag;
				piece_sides_initial_lag /= 2;
	else:
		piece_sides_initial_lag = PIECE_SIDES_MAX_LAG;
		piece_sides_lag = piece_sides_initial_lag;
	
	if(Input.is_action_just_released("ui_left")):
		check_if_piece_will_collide_at_left(delta);
		position.x = position.x - cell_size;
		piece_sides_lag = 0;
	
	if(Input.is_action_just_released("ui_right")):
		check_if_piece_will_collide_at_right(delta);
		position.x = position.x + cell_size;
		piece_sides_lag = 0;

func rotation_checks(delta):
	if(Input.is_action_just_pressed("rotate_clockwise") or Input.is_action_just_pressed("rotate_anticlockwise")):
		var rotation_in_degrees = 90;
		
		var can_rotate = check_if_piece_can_rotate(delta);
		
		if(can_rotate):
			if(Input.is_action_just_pressed("rotate_clockwise")):
				rotate_piece(rotation_in_degrees, delta);
			else:
				if(Input.is_action_just_pressed("rotate_anticlockwise")):
					rotate_piece(-1 * rotation_in_degrees, delta);
		
		#Prevent piece from being placed after the player rotated it.
		var collide_bottom = check_if_piece_will_collide(delta, false);
		
		if(collide_bottom):
			current_update_time = fall_update_rate_in_fps;

# Check boundaries, placement of the piece.
func collision_checks(delta):
	var left_wall_x = field_node.left_wall_position_x
	var right_wall_x = field_node.right_wall_position_x;
	var bottom_wall_y = field_node.bottom_wall_position_y;
	
	if(position.x <= left_wall_x):
		position.x = left_wall_x;
	else:
		if(position.x > right_wall_x):
			position.x = right_wall_x;
	
	if(position.y > bottom_wall_y):
		position.y = bottom_wall_y;
		#place_piece();

func check_if_piece_will_collide(delta, place_it = true):
	var collision_info = piece_instance.test_move(get_transform(), Vector2(0, piece_collision_detection_speed) * delta);
	
	if(collision_info and place_it):
		place_piece();
	
	return collision_info;

func check_if_piece_will_collide_at_left(delta, move_it = true):
	var collides_with_left = piece_instance.test_move(get_transform(), Vector2(-1 * piece_collision_detection_speed, 0) * delta);
	
	if(collides_with_left):
		#print("LEFT");
		if(move_it):
			position.x = position.x + cell_size;
	
	return collides_with_left;

func check_if_piece_will_collide_at_right(delta, move_it = true):
	var collides_with_right = piece_instance.test_move(get_transform(), Vector2(piece_collision_detection_speed, 0) * delta);
	
	if(collides_with_right):
		#print("RIGHT");
		if(move_it):
			position.x = position.x - cell_size;
	
	return collides_with_right;

func check_if_piece_can_rotate(delta):
	var collide_left = check_if_piece_will_collide_at_left(delta, false); #Check but don't move the piece;
	var collide_right = check_if_piece_will_collide_at_right(delta, false);
	var can_rotate = not (collide_left and collide_right);
	var is_the_piece_thin_enough_to_rotate = piece_instance.width_in_blocks >= piece_instance.height_in_blocks;
	
	if(not can_rotate and is_the_piece_thin_enough_to_rotate):
		can_rotate = true;
	
	return can_rotate;

func rotate_piece(rotation_in_degrees, delta):	
	piece_rotation += rotation_in_degrees;
	
	if(piece_rotation >= 360):
		piece_rotation -= 360;
	else:
		if(piece_rotation < 0):
			piece_rotation += 360;
	
	piece_instance.rotate(piece_rotation);

	var collided_left = false;
	var collided_right = false;
	
	while(check_if_piece_will_collide_at_left(delta, false) == true):
		collided_left = check_if_piece_will_collide_at_left(delta);
		
	while(check_if_piece_will_collide_at_right(delta, false) == true):
		collided_right = check_if_piece_will_collide_at_right(delta);
	
	if(collided_left):
		position.x -= cell_size;
	
	if(collided_right):
		position.x += cell_size;

#func check_if_piece_can_rotate_anticlockwise_then_rotate_it(angle_of_rotation, delta):
	

# Add the piece in field_node as child.
func place_piece():
	piece_instance.position = position;
	#piece_instance.rotation_degrees = rotation_degrees;
	field_node.add_piece(piece_instance);
	remove_child(piece_instance);
	reinitialize();