extends Marker2D

@export var color: Color = Color.RED
@export var size: float = 10.0
@export var thickness: float = 2.0

func _draw():
	# Draw a crosshair similar to the editor icon
	draw_line(Vector2(-size, 0), Vector2(size, 0), color, thickness)
	draw_line(Vector2(0, -size), Vector2(0, size), color, thickness)

func _ready():
	# Force the node to call _draw()
	queue_redraw()
