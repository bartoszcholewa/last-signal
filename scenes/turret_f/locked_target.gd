extends RayCast2D

@onready var line: Line2D = $Line2D


func _process(_delta):
	line.clear_points()
	line.add_point(Vector2.ZERO)

	if is_colliding():
		line.add_point(to_local(get_collision_point()))
		line.default_color = Color.LIGHT_GREEN
	else:
		line.add_point(target_position)
		line.default_color = Color.INDIAN_RED
