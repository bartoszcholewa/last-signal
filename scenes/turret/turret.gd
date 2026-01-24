extends Node2D

signal died

const BULLET_SCENE: PackedScene = preload("uid://d35rd07yoeys4")

@onready var ray_cast_2d: RayCast2D = %RayCast2D
@onready var reload_timer: Timer = %ReloadTimer
@onready var barrel: Node2D = %Barrel
@onready var barrel_position: Marker2D = $Visuals/Barrel/BarrelPosition
@onready var health_component: HealthComponent = $HealthComponent

## Current selected target
var target: Node2D = null

## Turret speed RAD/s
var max_rotation_speed: float = 5.0

## How fast it reaches max speed
var acceleration: float = 15.0

## How fast it brakes when close
var deceleration: float = 30.0

## The current speed of the barrel
var current_velocity: float = 0.0

func _ready() -> void:
	# Connect to signals
	reload_timer.timeout.connect(_on_reload_timer_timeout)
	health_component.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	target = find_target()

	if not target:
		# Slow the barrel to a stop if no target is found
		current_velocity = move_toward(current_velocity, 0, deceleration * delta)
		barrel.rotation += current_velocity * delta
		return

	var angle: float = lock_target()

	if is_target_in_range():
		rotate_barrel_to_target(angle, delta)
		if is_barrel_aligned(angle):
			try_to_shoot()


func lock_target() -> float:
	## Get angle to selected target
	var angle_to_target: float = global_position.direction_to(target.global_position).angle()
	ray_cast_2d.global_rotation = angle_to_target
	return angle_to_target


func is_target_in_range() -> bool:
	## Check if target is already in shooting range
	if ray_cast_2d.is_colliding():
		var collider: Node2D = ray_cast_2d.get_collider()
		if collider and collider.is_in_group("enemy"):
			return true
	return false


func rotate_barrel_to_target(target_angle: float, delta: float) -> void:
	## Accelerate rotation to match target angle

	# Calculate the shortest distance to the target angle
	# (Prevents the barrel from spinning 350 degrees to reach -10 degrees)
	var diff = angle_difference(barrel.rotation, target_angle)

	# Determine the "Desired Velocity"
	# If the difference is positive, we want to go clockwise, if negative, counter-clockwise
	var direction = sign(diff)

	# If we are within 0.2 radians, start slowing down
	var braking_threshold = 0.5
	var speed_multiplier = clamp(abs(diff) / braking_threshold, 0.0, 1.0)
	var target_velocity = direction * max_rotation_speed * speed_multiplier

	# Accelerate or Decelerate towards that target velocity
	var accel_rate = acceleration if abs(current_velocity) < abs(target_velocity) else deceleration
	current_velocity = move_toward(current_velocity, target_velocity, accel_rate * delta)

	# Apply the velocity to the rotation
	barrel.rotation += current_velocity * delta


func is_barrel_aligned(target_angle: float) -> bool:
	## Returns true if the barrel is within 5 degrees of the target
	## and almost steady

	return abs(angle_difference(barrel.rotation, target_angle)) < 0.05\
		and current_velocity < 0.1\
		and current_velocity > -0.1

func try_to_shoot() -> void:
	## Check if reload time passed and create bullet

	if not reload_timer.is_stopped():
		return

	ray_cast_2d.enabled = false

	var bullet: Bullet = BULLET_SCENE.instantiate()
	bullet.global_position = barrel_position.global_position
	var bullet_direction: Vector2 = bullet.global_position.direction_to(target.global_position)
	bullet.start(bullet_direction)
	get_parent().add_child(bullet)

	reload_timer.start()


func find_target() -> Node2D:
	## Target detection system based on distance

	var targets = get_tree().get_nodes_in_group("enemy")

	if targets.is_empty():
		return

	# Sort by closest to player
	targets.sort_custom(
		func(a: Node2D, b: Node2D):
			var a_distance = a.global_position.distance_squared_to(global_position)
			var b_distance = b.global_position.distance_squared_to(global_position)
			return a_distance < b_distance
	)

	# Return closest target
	return targets[0]


func _on_reload_timer_timeout() -> void:
	## Activate range on bullet reload
	ray_cast_2d.enabled = true


func _on_died() -> void:
	print("Turret Died")
	died.emit()
