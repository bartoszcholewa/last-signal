# WalkState.gd
# ─────────────────────────────────────────────
# WALK  — Spider moves toward its target.
#
# Transitions:
#   → Attack   when target is within attack_range
#   → Idle     when target is lost (null) or out of chase_range
# ─────────────────────────────────────────────
extends State


# ═══════════════════════════════════════════════
# ENTER / EXIT
# ═══════════════════════════════════════════════

func enter() -> void:
	play_animation("walk", owner_node.current_direction)


func exit() -> void:
	# Zero out velocity so the spider doesn't slide when switching to Attack/Idle
	owner_node.velocity = Vector2.ZERO


# ═══════════════════════════════════════════════
# PHYSICS PROCESS  — movement lives here
# ═══════════════════════════════════════════════

func physics_process(_delta: float) -> void:
	var target: Node2D = owner_node.get_current_target()

	# ── Lost target? ──────────────────────────
	if target == null:
		transition_to("Idle")
		return

	var to_target: Vector2 = target.global_position - owner_node.global_position
	var dist: float = to_target.length()

	# ── Out of chase range? ───────────────────
	if dist > owner_node.chase_range:
		transition_to("Walk")
		return

	# ── Close enough to attack? ───────────────
	if dist <= owner_node.attack_range:
		transition_to("Attack")
		return

	# ── Move toward target ────────────────────
	var direction: Vector2 = to_target.normalized()

	# Update facing — only re-play animation if direction actually changed
	var new_angle: int = DirectionUtil.vector_to_angle(direction)
	if new_angle != -1 and new_angle != owner_node.current_direction:
		owner_node.current_direction = new_angle
		play_animation("walk", owner_node.current_direction)

	# Apply speed
	owner_node.velocity = direction * owner_node.walk_speed
	owner_node.move_and_slide()
