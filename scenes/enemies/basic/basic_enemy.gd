extends CharacterBody2D

@onready var velocity_component: Node = $VelocityComponent
@onready var health_component: HealthComponent = $HealthComponent

const BASE_SPEED: int = 200

func _ready() -> void:
	health_component.died.connect(_on_died)

func _physics_process(_delta: float) -> void:
	velocity_component.accelerate_to_turret()
	velocity_component.move(self)

func _on_died() -> void:
	print("Enemy Died")
	queue_free()
