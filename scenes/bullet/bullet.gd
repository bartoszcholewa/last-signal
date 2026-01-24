class_name Bullet
extends Node2D

const SPEED: int = 1200

@onready var life_timer: Timer = $LifeTimer

var direction: Vector2


func _ready() -> void:
	life_timer.timeout.connect(_on_life_timer_timeout)

func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta

func start(bullet_direction: Vector2) -> void:
	direction = bullet_direction
	rotation = direction.angle()

func _on_life_timer_timeout() -> void:
	queue_free()
