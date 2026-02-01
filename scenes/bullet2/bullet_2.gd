# Bullet.gd
class_name Bullet2
extends Area2D

@export var speed: float = 400.0
@export var damage: int = 25
@export var lifetime: float = 3.0   # auto-remove if it hits nothing

var _timer: float = 0.0
var _direction: Vector2 = Vector2.RIGHT


func _ready() -> void:
	# Connect the collision signal once, here — not every frame
	body_entered.connect(_on_body_entered)


func fire(direction: Vector2) -> void:
	_direction = direction.normalized()


func _process(delta: float) -> void:
	# Move the bullet
	position += _direction * speed * delta
	rotation = _direction.angle()

	# Safety timeout — free the bullet if it flies off into nothing
	_timer += delta
	if _timer >= lifetime:
		queue_free()


func _on_body_entered(body: CollisionObject2D) -> void:
	# Only care about things that can take damage
	if body.has_method("take_damage"):
		body.take_damage(damage)

	# Bullet is consumed on any hit — remove it
	queue_free()
