extends Node2D

signal died

#const BULLET_SCENE: PackedScene = preload("uid://d35rd07yoeys4")
const BULLET2_SCENE: PackedScene = preload("uid://crb4d4tdeduu6")

const MUZZLE_FLASH_SCENE: PackedScene = preload("uid://3ncbiuqnbnnb")

@onready var turret_sprite: Sprite2D = %Sprite2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var reload_timer: Timer = $ReloadTimer
@onready var barrel_tip: Marker2D = %BarrelTip
@onready var frame_label: Label = %FrameLabel
@onready var angle_label: Label = %AngleLabel
@onready var velocity_label: Label = %VelocityLabel
@onready var state_label: Label = %StateLabel
@onready var shoot_range: RayCast2D = %ShootRange

var effects_scene: Node2D

# Configuration
var turret_pivot_offset: Vector2
var frames_count: int = 64
var rotation_offset_degrees: float = 0
var current_rotation: float = deg_to_rad(0)
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
var barrel_offset_distance: float = 92.0

## 0.5 is standard 2:1 Isometric. Adjust if needed.
var iso_squash_ratio: float = 0.75

## How many pixels to pull the muzzle back at 45/135/225/315 degrees
var diagonal_shrink_amount: float = 2.0

func _ready() -> void:
	# Connect to signals
	reload_timer.timeout.connect(_on_reload_timer_timeout)
	health_component.died.connect(_on_died)
	GameEvents.debug_info_changed.connect(_on_debug_info_changed)

	turret_pivot_offset = $Visuals.position
	print(turret_pivot_offset)

	# Cache visual scene node
	effects_scene = get_tree().get_first_node_in_group("effects")

	set_debug_info_display()

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
	if shoot_range.is_colliding():
		var collider: Node2D = shoot_range.get_collider()
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
	var accel_rate: float
	if abs(current_velocity) <= abs(target_velocity):
		accel_rate = acceleration
		state_label.text = "State: ACCELERATE"
	else:
		accel_rate = deceleration
		state_label.text = "State: DECELERATE"

	current_velocity = move_toward(current_velocity, target_velocity, accel_rate * delta)

	velocity_label.text = "Velocity: %.02f" % current_velocity

	# Apply the velocity to the rotation
	current_rotation += current_velocity * delta

	# Wrap the actual physics rotation to keep it between -PI and PI
	current_rotation = wrapf(current_rotation, -PI, PI)

func set_turret_rotation_frame():
	# --- FRAME CALCULATION (Using Projected 3D Angle) ---

	# 1. Create a vector from the current Screen Space rotation
	var vector = Vector2.RIGHT.rotated(current_rotation)


	# 2. "Un-squash" the vector.
	# Since the sprite sheet is rendered in Isometric (where Y is squashed),
	# we must stretch Y back out to find the "True 3D Angle" that this frame represents.
	if iso_squash_ratio != 0:
		vector.y /= iso_squash_ratio

	# 3. Get the angle for the sprite lookup
	var sprite_angle_deg = rad_to_deg(vector.angle())
	var logic_angle = sprite_angle_deg

	# 4. Apply offset and normalize
	sprite_angle_deg += rotation_offset_degrees
	sprite_angle_deg = fposmod(sprite_angle_deg, 360.0)

	# 5. Set the frame based on the CORRECTED angle
	var frame_index = int(round(sprite_angle_deg / angle_step))
	var turret_sprite_frame: int = frame_index % frames_count
	turret_sprite.frame = turret_sprite_frame

	frame_label.text = "Frame: %d" % turret_sprite_frame
	angle_label.text = "Angle: %d°" % int(rad_to_deg(current_rotation)) # Keep debug showing real screen angle

	var rads = deg_to_rad(logic_angle)

	# Calculate a "Wobble" factor.
	# sin(angle * 2) is 0.0 at 0, 90, 180, 270.
	# sin(angle * 2) is 1.0 (or -1.0) at 45, 135, 225, 315.
	var diagonal_intensity = abs(sin(rads * 2))

	# Dynamically adjust the radius.
	# At cardinal directions, offset is 0. At diagonals, it subtracts the full shrink amount.
	var current_barrel_length = barrel_offset_distance - (diagonal_shrink_amount * diagonal_intensity)

	# Apply position
	barrel_tip.position.x = cos(rads) * current_barrel_length
	barrel_tip.position.y = sin(rads) * current_barrel_length * iso_squash_ratio


func lock_target() -> float:
	## Get angle to selected target
	var true_pivot_global_position = global_position + turret_pivot_offset
	var angle_to_target: float = true_pivot_global_position.direction_to(target_position).angle()
	shoot_range.global_rotation = angle_to_target
	return angle_to_target


func is_barrel_aligned(target_angle: float) -> bool:
	## Returns true if the barrel is within 5 degrees of the target
	## and almost steady

	var is_aligned = abs(angle_difference(current_rotation, target_angle)) < 0.05\
		and current_velocity < 0.5\
		and current_velocity > -0.5

	if is_aligned:
		current_velocity = 0
		state_label.text = "State: ALIGNED"

	return is_aligned


func try_to_shoot() -> void:
	## Check if reload time passed and create bullet
	state_label.text = "State: SHOOTING"
	if not reload_timer.is_stopped():
		return

	shoot_range.enabled = false

	var bullet: Bullet2 = BULLET2_SCENE.instantiate()
	bullet.global_position = barrel_tip.global_position
	var bullet_direction: Vector2 = bullet.global_position.direction_to(target_position)
	bullet.fire(bullet_direction)
	#get_parent().add_child(bullet)
	effects_scene.add_child(bullet)

	var muzzle_flash: Node2D = MUZZLE_FLASH_SCENE.instantiate()
	muzzle_flash.global_position = barrel_tip.global_position
	muzzle_flash.global_rotation = (muzzle_flash.global_position.direction_to(target_position)).angle()
	#get_parent().add_child(muzzle_flash)
	effects_scene.add_child(muzzle_flash)

	reload_timer.start()
	state_label.text = "State: RELOADING"

func get_iso_angle_to_target(target_pos: Vector2) -> float:
	# Get vector from turret to target
	var vector_to_target = target_pos - global_position

	# UN-SQUASH: Multiply Y by 2 to turn the isometric ellipse back into a circle
	# This creates the "True Ground Angle"
	vector_to_target.y *= 2.0

	return vector_to_target.angle()


func set_debug_info_display() -> void:
	barrel_tip.visible = GameEvents.debug_info
	shoot_range.visible = GameEvents.debug_info


func _on_debug_info_changed() -> void:
	set_debug_info_display()

func _on_reload_timer_timeout() -> void:
	## Activate range on bullet reload
	shoot_range.enabled = true


func _on_died() -> void:
	print("Turret Died")
	died.emit()
