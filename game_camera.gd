extends Camera2D

const ZOOM_MIN: Vector2 = Vector2(0.5, 0.5)
const ZOOM_MAX: Vector2 = Vector2(1.5, 1.5)
const ZOOM_STEP: Vector2 = Vector2(0.1, 0.1)
const ZOOM_SPEED: float = 10.0
const ZOOM_INIT = Vector2(1.0, 1.0)

var zoom_target: Vector2

func _ready() -> void:
	zoom = ZOOM_MAX
	zoom_target = ZOOM_INIT

func _process(delta: float) -> void:
	_zoom(delta)

func _zoom(delta: float) -> void:
	if Input.is_action_just_pressed("mousewheel_down"):
		if zoom_target > ZOOM_MIN:
			zoom_target -= ZOOM_STEP

	if Input.is_action_just_pressed("mousewheel_up"):
		if zoom_target < ZOOM_MAX:
			zoom_target += ZOOM_STEP

	zoom = zoom.slerp(zoom_target, ZOOM_SPEED * delta)
