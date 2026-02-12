# AttackState.gd
# ─────────────────────────────────────────────
# ATTACK  — Spider plays its attack animation and deals damage.
#
# Damage is dealt on a specific frame of the animation (hit_frame),
# so the timing matches the visual hit.  After the full animation
# completes one loop the state decides what to do next.
#
# Transitions:
#   → Walk     if target is still alive but moved out of attack range
#   → Idle     if target is lost
#   → (loops)  if target is still in range after the swing
# ─────────────────────────────────────────────
extends State


# ── Exported so designers can tweak per-variant without code changes ──
@export var hit_frame: int = 7          # which animation frame deals damage
@export var damage: int = 10            # damage dealt on hit

# ── Internal bookkeeping ──────────────────────
var _hit_dealt: bool = false            # prevent double-hit per swing
var _sprite: AnimatedSprite2D


# ═══════════════════════════════════════════════
# ENTER / EXIT
# ═══════════════════════════════════════════════

func enter() -> void:
	_sprite = owner_node.get_node("AnimatedSprite2D")

	# Listen for animation_finished to know when the full swing is done
	if not _sprite.animation_finished.is_connected(_on_animation_finished):
		_sprite.animation_finished.connect(_on_animation_finished)

	_swing()   # reset + play — same path used for repeat swings


func exit() -> void:
	# Disconnect so other states don't accidentally receive this signal
	if _sprite and _sprite.animation_finished.is_connected(_on_animation_finished):
		_sprite.animation_finished.disconnect(_on_animation_finished)


# ═══════════════════════════════════════════════
# PROCESS  — watch for the hit frame
# ═══════════════════════════════════════════════

func process(_delta: float) -> void:
	if _hit_dealt:
		return   # already swung this cycle, waiting for animation_finished

	# Check current frame
	if _sprite.frame == hit_frame:
		_deal_damage()


# ═══════════════════════════════════════════════
# SIGNAL CALLBACKS
# ═══════════════════════════════════════════════

# Called when one full loop of the attack animation finishes
func _on_animation_finished() -> void:
	var target: Node2D = owner_node.get_current_target()

	if target == null:
		transition_to("Idle")
		return

	var dist: float = owner_node.global_position.distance_to(target.global_position)

	if dist <= owner_node.attack_range:
		# Target still in range — swing again.
		# We can't use transition_to("Attack") here: StateMachine correctly
		# blocks self-transitions as a no-op.  We're already in this state,
		# so we just reset and replay directly.
		_swing()
	else:
		# Target moved away — go chase it
		transition_to("Walk")


# Resets bookkeeping and replays the attack animation.
# Called both from enter() (first swing) and _on_animation_finished() (repeat swings).
func _swing() -> void:
	_hit_dealt = false
	play_animation("attack", owner_node.current_direction)


# ═══════════════════════════════════════════════
# PRIVATE
# ═══════════════════════════════════════════════

func _deal_damage() -> void:
	_hit_dealt = true

	var target: Node2D = owner_node.get_current_target()
	if target == null:
		return

	# Only damage if target is still within range at the moment of impact
	var dist: float = owner_node.global_position.distance_to(target.global_position)
	if dist > owner_node.attack_range:
		return

	# Call the target's take_damage (adapt to your damage system)
	if target.has_method("take_damage"):
		target.take_damage(damage)
	else:
		push_warning("Target %s does not have method `take_damage`" % target)
