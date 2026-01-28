class_name Bullet
extends Node2D

const SPEED: int = 1600

@onready var life_timer: Timer = $LifeTimer
@onready var hitbox_component: HitboxComponent = $HitboxComponent

var direction: Vector2


func _ready() -> void:
	life_timer.timeout.connect(_on_life_timer_timeout)
	hitbox_component.hit_hurtbox.connect(_on_hit_hurtbox)

func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta

func start(bullet_direction: Vector2) -> void:
	direction = bullet_direction
	rotation = direction.angle()

func register_collision() -> void:
	queue_free()

func _on_life_timer_timeout() -> void:
	queue_free()

func _on_hit_hurtbox(_hurtbox_component: HurtboxComponent) -> void:
	register_collision()
