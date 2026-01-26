extends Node2D

signal died

const BULLET_SCENE: PackedScene = preload("uid://d35rd07yoeys4")

@onready var turret_sprite: Sprite2D = $Sprite2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var reload_timer: Timer = $ReloadTimer
@onready var muzzle: Marker2D = $Muzzle

# Configuration
var frames_count: int = 64
var rotation_offset_degrees: float = 90.0
var current_rotation: float = deg_to_rad(-90)

## Turret speed RAD/s
var max_rotation_speed: float = 5.0 #5.0

## How fast it reaches max speed
var acceleration: float = 15.0 #15.0

## How fast it brakes when close
var deceleration: float = 30.0 # 30.0

## The current speed of the barrel
var current_velocity: float = 0.0

# Calculate the size of a single "slice" of rotation (360 / 32 = 11.25 degrees)
var angle_step: float = 360.0 / float(frames_count)

## Current selected target
var target_position: Vector2 = Vector2.ZERO

## Distance from center to barrel tip (in pixels)
var barrel_offset_distance: float = 55.0 #55.0

## 0.5 is standard 2:1 Isometric. Adjust if needed.
var iso_squash_ratio: float = 0.75 # 0.75

func _ready() -> void:
	# Connect to signals
	reload_timer.timeout.connect(_on_reload_timer_timeout)
	health_component.died.connect(_on_died)

func _process(delta):

	if GameEvents.manual_control:
		target_position = get_global_mouse_position()

	else:
		target_position = find_target_position()

	if not target_position:
		return

	var target_angle: float = lock_target()

	if is_target_in_range():
		set_rotation_to_target(target_angle, delta)
		set_turret_rotation_frame()
		if is_barrel_aligned(target_angle):
			if GameEvents.manual_control:
				if Input.is_action_just_pressed("manual_shoot"):
					print("PEW!")
					try_to_shoot()
			else:
				try_to_shoot()


func find_target_position() -> Vector2:
	## Target detection system based on distance
	var targets = get_tree().get_nodes_in_group("enemy")

	if targets.is_empty():
		return Vector2.ZERO

	# Sort by closest to player
	targets.sort_custom(
		func(a: Node2D, b: Node2D):
			var a_distance = a.global_position.distance_squared_to(global_position)
			var b_distance = b.global_position.distance_squared_to(global_position)
			return a_distance < b_distance
	)

	# Return closest target
	return targets[0].global_position


func is_target_in_range() -> bool:
	if GameEvents.manual_control:
		return true
	## Check if target is already in shooting range
	if ray_cast_2d.is_colliding():
		var collider: Node2D = ray_cast_2d.get_collider()
		if collider and collider.is_in_group("enemy"):
			return true
	return false

func set_rotation_to_target(target_angle: float, delta: float) -> void:
	## Accelerate rotation to match target angle

	# Calculate the shortest distance to the target angle
	# (Prevents the barrel from spinning 350 degrees to reach -10 degrees)
	var diff = angle_difference(current_rotation, target_angle)

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
	current_rotation += current_velocity * delta

	# Wrap the actual physics rotation to keep it between -PI and PI
	current_rotation = wrapf(current_rotation, -PI, PI)


func set_turret_rotation_frame():
	# 1. Convert accumulated rotation to degrees
	var angle_deg = rad_to_deg(current_rotation)
	var logic_angle = angle_deg

	# 2. Apply offset
	angle_deg += rotation_offset_degrees

	# 3. Normalize angle to always be between 0.0 and 360.0
	# fposmod floats the modulo wrapping correctly for negative numbers.
	# e.g. fposmod(-400, 360) becomes 320.
	angle_deg = fposmod(angle_deg, 360.0)

	# 4. Calculate frame index
	var frame_index = int(round(angle_deg / angle_step))

	# 5. Set frame (Wrap 64 back to 0 using standard modulo)
	turret_sprite.frame = frame_index % frames_count
	var rads = deg_to_rad(logic_angle)

	# Muzzle position
	muzzle.position.x = cos(rads) * barrel_offset_distance
	muzzle.position.y = sin(rads) * barrel_offset_distance * iso_squash_ratio


func lock_target() -> float:
	## Get angle to selected target
	var angle_to_target: float = global_position.direction_to(target_position).angle()
	ray_cast_2d.global_rotation = angle_to_target
	return angle_to_target


func is_barrel_aligned(target_angle: float) -> bool:
	## Returns true if the barrel is within 5 degrees of the target
	## and almost steady

	return abs(angle_difference(current_rotation, target_angle)) < 0.05\
		and current_velocity < 0.1\
		and current_velocity > -0.1


func try_to_shoot() -> void:
	## Check if reload time passed and create bullet

	if not reload_timer.is_stopped():
		return

	ray_cast_2d.enabled = false

	var bullet: Bullet = BULLET_SCENE.instantiate()
	bullet.global_position = muzzle.global_position
	var bullet_direction: Vector2 = bullet.global_position.direction_to(target_position)
	bullet.start(bullet_direction)
	get_parent().add_child(bullet)

	reload_timer.start()

func get_iso_angle_to_target(target_pos: Vector2) -> float:
	# Get vector from turret to target
	var vector_to_target = target_pos - global_position

	# UN-SQUASH: Multiply Y by 2 to turn the isometric ellipse back into a circle
	# This creates the "True Ground Angle"
	vector_to_target.y *= 2.0

	return vector_to_target.angle()

func _on_reload_timer_timeout() -> void:
	## Activate range on bullet reload
	ray_cast_2d.enabled = true


func _on_died() -> void:
	print("Turret Died")
	died.emit()
