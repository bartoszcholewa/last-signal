class_name GameCamera
extends Camera2D

static var instance: GameCamera

const ZOOM_MIN: Vector2 = Vector2(0.5, 0.5)
const ZOOM_MAX: Vector2 = Vector2(1.5, 1.5)
const ZOOM_STEP: Vector2 = Vector2(0.1, 0.1)
const ZOOM_SPEED: float = 10.0
const ZOOM_INIT = Vector2(1.0, 1.0)

var zoom_target: Vector2

# Shake
const NOISE_GROWTH: float = 750.0
const SHAKE_DECAY_RATE: float = 10.0
var noise_offset_x: float
var noise_offset_y: float
var current_shake_percentage: float
var shake_strenght: float = 12.0

@export var noise_texture: FastNoiseLite



func _ready() -> void:
	instance = self

	zoom = ZOOM_MAX
	zoom_target = ZOOM_INIT

func _process(delta: float) -> void:
	_zoom(delta)
	_shake(delta)

func _zoom(delta: float) -> void:
	if Input.is_action_just_pressed("mousewheel_down"):
		if zoom_target > ZOOM_MIN:
			zoom_target -= ZOOM_STEP

	if Input.is_action_just_pressed("mousewheel_up"):
		if zoom_target < ZOOM_MAX:
			zoom_target += ZOOM_STEP

	zoom = zoom.slerp(zoom_target, ZOOM_SPEED * delta)


static func shake(percent: float):
	instance.current_shake_percentage = clamp(percent, 0, 1)

func _shake(delta: float):
	if current_shake_percentage == 0:
		return

	noise_offset_x += NOISE_GROWTH * delta
	noise_offset_y += NOISE_GROWTH * delta

	var offset_sample_x := noise_texture.get_noise_2d(noise_offset_x, 0)
	var offset_sample_y := noise_texture.get_noise_2d(0, noise_offset_y)

	offset = Vector2(offset_sample_x, offset_sample_y) \
		* shake_strenght * current_shake_percentage * current_shake_percentage

	current_shake_percentage = max(current_shake_percentage - (SHAKE_DECAY_RATE * delta), 0)
