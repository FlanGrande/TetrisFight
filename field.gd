extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
export var cell_size = 30;
export var height_in_cells = 30;
export var width_in_cells = 10;
export var fall_update_rate_in_fps = 60;
var size = Vector2(cell_size * width_in_cells, cell_size * height_in_cells);

onready var window = get_tree().get_root();

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	#window.get_viewport().size = size;
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
