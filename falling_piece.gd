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
var piece_node;
var piece_position;
var piece_collision_detection_speed = Vector2(0, 1000);

# Field variables.
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
	check_if_piece_will_collide(piece_collision_detection_speed, delta);

# Puts piece at the top.
func reinitialize():
	generate_piece();
	position = origin;
	piece_has_dropped = false;
	current_update_time = fall_update_rate_in_fps;

# Generate a piece for the player.
func generate_piece():
	piece_node = piece_pool_node.generate_random_piece();
	add_child(piece_node);

# Update fall of the piece and check player input.
func movement_checks(delta):
	if(Input.is_action_pressed("ui_down")):
		piece_down_lag -= 1;
		
		if(piece_down_lag < 0):
			piece_down_lag = 0;
		
		if(piece_down_lag == 0):
			position.y = position.y + cell_size;
			piece_down_lag = piece_down_initial_lag;
			piece_down_initial_lag /= 2;
	else:
		piece_down_initial_lag = PIECE_DOWN_MAX_LAG;
		
		current_update_time -= 1;
		
		if(current_update_time == 0):
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
				position.x = position.x - cell_size;
				piece_sides_lag = piece_sides_initial_lag;
				piece_sides_initial_lag /= 2;
				
		if(Input.is_action_pressed("ui_right")):
			if(piece_sides_lag == 0):
				position.x = position.x + cell_size;
				piece_sides_lag = piece_sides_initial_lag;
				piece_sides_initial_lag /= 2;
	else:
		piece_sides_initial_lag = PIECE_SIDES_MAX_LAG;

func rotation_checks(delta):
	if(Input.is_action_just_pressed("rotate_clockwise")):
		rotation_degrees += 90;
	else:
		if(Input.is_action_just_pressed("rotate_anticlockwise")):
			rotation_degrees -= 90;

# Check boundaries, placement of the piece.
func collision_checks(delta):
	if(position.x <= field_node.left_wall_position_x):
		position.x = field_node.left_wall_position_x;
	else:
		if(position.x > field_node.right_wall_position_x - cell_size * piece_pool_node.piece_node.width_in_blocks):
			position.x = field_node.right_wall_position_x - cell_size * piece_pool_node.piece_node.width_in_blocks;
	
	if(position.y > field_node.bottom_wall_position_y - cell_size * piece_pool_node.piece_node.height_in_blocks):
		position.y = field_node.bottom_wall_position_y - cell_size * piece_pool_node.piece_node.height_in_blocks;
		place_piece();

func check_if_piece_will_collide(speed, delta):
	var collision_info = piece_node.test_move(get_transform(), speed * delta);
	
	if(collision_info):
		print(collision_info);
		place_piece();

# Add the piece in field_node as child.
func place_piece():
	piece_node.position = position;
	field_node.add_piece(piece_node.duplicate(true), rotation_degrees);
	remove_child(piece_node);
	reinitialize();