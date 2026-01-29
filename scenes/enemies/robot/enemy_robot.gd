extends CharacterBody2D

@export var speed: float = 200.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var velocity_component: Node = $VelocityComponent


func _ready() -> void:
	health_component.died.connect(_on_died)


func _physics_process(_delta: float) -> void:
	# 1. Get Input Direction
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# 2. Apply Movement
	velocity = direction * speed
	move_and_slide()

	# 3. Handle Animation
	update_animation(direction)

func update_animation(dir: Vector2):
	if dir == Vector2.ZERO:
		sprite.stop() # Or play an "idle" animation
		return

	# Get the angle in degrees (Godot: Right is 0, Down is 90, Left is 180, Up is 270)
	var angle = rad_to_deg(dir.angle())

	# Ensure the angle is positive (0 to 360)
	if angle < 0:
		angle += 360

	# Round to the nearest 45 degrees
	# snapped(46, 45) becomes 45; snapped(80, 45) becomes 90
	var rounded_angle = int(snapped(angle, 45))

	# Wrap 360 back to 0 (since 360 is the same as 0)
	if rounded_angle == 360:
		rounded_angle = 0

	# Format the string to match your names: "walk_" + angle padded to 3 digits
	# Example: 45 becomes "walk_045", 0 becomes "walk_000"
	var anim_name = "walk_" + str(rounded_angle).pad_zeros(3)

	sprite.play(anim_name)


func _on_died() -> void:
	print("Enemy Died")
	queue_free()
