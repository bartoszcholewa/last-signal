extends Node2D

signal died

const BULLET_SCENE: PackedScene = preload("uid://d35rd07yoeys4")

@onready var ray_cast_2d: RayCast2D = %RayCast2D
@onready var reload_timer: Timer = %ReloadTimer
@onready var barrel: Node2D = %Barrel
@onready var barrel_position: Marker2D = $Visuals/Barrel/BarrelPosition
@onready var health_component: HealthComponent = $HealthComponent


var target: Node2D = null

func _ready() -> void:
	reload_timer.timeout.connect(_on_reload_timer_timeout)
	health_component.died.connect(_on_died)


func _physics_process(_delta: float) -> void:
	target = find_target()

	if not target:
		print("Target not found!")
		return

	var angle_to_target: float = global_position.direction_to(target.global_position).angle()
	ray_cast_2d.global_rotation = angle_to_target

	if ray_cast_2d.is_colliding():
		var collider: Node2D = ray_cast_2d.get_collider()
		if collider and collider.is_in_group("enemy"):
			barrel.rotation = angle_to_target
			if reload_timer.is_stopped():
				shoot()


func shoot() -> void:
	ray_cast_2d.enabled = false

	var bullet: Bullet = BULLET_SCENE.instantiate()
	bullet.global_position = barrel_position.global_position
	var bullet_direction: Vector2 = bullet.global_position.direction_to(target.global_position)
	bullet.start(bullet_direction)
	get_parent().add_child(bullet)

	reload_timer.start()


func find_target() -> Node2D:
	var new_target: Node2D = null

	if get_tree().has_group("enemy"):
		new_target = get_tree().get_first_node_in_group("enemy")

	return new_target


func _on_reload_timer_timeout() -> void:
	ray_cast_2d.enabled = true


func _on_died() -> void:
	print("Turret Died")
	died.emit()
