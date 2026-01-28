extends RayCast2D

@onready var line: Line2D = $Line2D

@export var turret_range: int = 500
@export var ray_active_color: Color = Color.LIGHT_GREEN
@export var ray_inactive_color: Color = Color.INDIAN_RED
@export var ray_range_color: Color = Color(1, 1, 0, 0.3)

func _ready() -> void:
	target_position = Vector2(turret_range, 0)


func _process(_delta):

	line.clear_points()
	line.add_point(Vector2.ZERO)

	if is_colliding():
		line.add_point(to_local(get_collision_point()))
		line.default_color = ray_active_color
	else:
		line.add_point(target_position)
		line.default_color = ray_inactive_color

	queue_redraw()


func _draw():
	# Calculate the radius based on target_position length
	var radius = target_position.length()

	# Draw an unfilled circle (arc)
	# draw_arc(center, radius, start_angle, end_angle, point_count, color, width)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, ray_range_color, 2.0)
