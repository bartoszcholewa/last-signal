# DieState.gd
# ─────────────────────────────────────────────
# DIE  — Spider plays its death animation exactly once, then freezes
#        on the final frame.  The body remains in the scene as a corpse.
#
# This is a TERMINAL state — no transitions out.
# The enemy is effectively "dead" but its visual remains.
#
# Corpse lifetime (optional):
#   Set corpse_duration > 0 to auto-remove after that many seconds.
#   Leave it at 0.0 to keep the corpse forever.
# ─────────────────────────────────────────────
extends State


@export var corpse_duration: float = 0.0   # 0 = permanent corpse

var _sprite: AnimatedSprite2D
var _corpse_timer: float = 0.0
var _animation_done: bool = false


# ═══════════════════════════════════════════════
# ENTER / EXIT
# ═══════════════════════════════════════════════

func enter() -> void:
	_sprite = owner_node.get_node("AnimatedSprite2D")
	_animation_done = false
	_corpse_timer = 0.0

	# Play the die animation.
	# IMPORTANT: make sure all "die_*" animations have the loop button
	# turned OFF in the SpriteFrames editor — that is what controls whether
	# an animation loops.  There is no runtime .loop property on AnimatedSprite2D.
	play_animation("die", owner_node.current_direction)

	# Connect to animation_finished so we know when to freeze
	if not _sprite.animation_finished.is_connected(_on_death_animation_finished):
		_sprite.animation_finished.connect(_on_death_animation_finished)

	# Disable physics — dead spiders don't move or collide as enemies
	owner_node.set_process(false)          # stop the owner's _process
	owner_node.set_physics_process(false)  # stop the owner's _physics_process
	# Disable the enemy's collision shape so it no longer blocks movement
	_disable_shape.call_deferred()



func exit() -> void:
	# Die is terminal — this should never be called, but just in case:
	if _sprite and _sprite.animation_finished.is_connected(_on_death_animation_finished):
		_sprite.animation_finished.disconnect(_on_death_animation_finished)


# ═══════════════════════════════════════════════
# PROCESS  — only active if corpse_duration > 0
# ═══════════════════════════════════════════════

func process(delta: float) -> void:
	if not _animation_done:
		return   # still playing the death animation

	if corpse_duration <= 0.0:
		return   # permanent corpse, nothing to do

	# Count down and remove the corpse node when time is up
	_corpse_timer += delta
	if _corpse_timer >= corpse_duration:
		_remove_corpse()


# ═══════════════════════════════════════════════
# SIGNAL CALLBACKS
# ═══════════════════════════════════════════════

func _on_death_animation_finished() -> void:
	_animation_done = true

	# Freeze on the very last frame of the animation
	_sprite.frame = _sprite.sprite_frames.get_frame_count(_sprite.animation) - 1
	_sprite.pause()

	# Disconnect — we no longer need this signal
	if _sprite.animation_finished.is_connected(_on_death_animation_finished):
		_sprite.animation_finished.disconnect(_on_death_animation_finished)

	# If corpse_duration > 0, re-enable process on the owner so we can count down
	if corpse_duration > 0.0:
		owner_node.set_process(true)


# ═══════════════════════════════════════════════
# PRIVATE
# ═══════════════════════════════════════════════

func _remove_corpse() -> void:
	# Optionally add a fade-out tween here before freeing
	owner_node.queue_free()

func _disable_shape() -> void:
	var shape: CollisionShape2D = owner_node.get_node_or_null("CollisionShape2D")
	if shape:
		shape.disabled = true
