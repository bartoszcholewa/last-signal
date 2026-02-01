# IdleState.gd
# ─────────────────────────────────────────────
# IDLE  — Spider stands still, scanning for targets.
#
# Transitions:
#   → Walk     if a target enters detection range
#   → Attack   if a target is already in attack range
# ─────────────────────────────────────────────
extends State


# ═══════════════════════════════════════════════
# ENTER / EXIT
# ═══════════════════════════════════════════════

func enter() -> void:
	# idle_* animations should have loop turned ON in SpriteFrames.
	play_animation("idle", owner_node.current_direction)


func exit() -> void:
	pass


# ═══════════════════════════════════════════════
# PROCESS
# ═══════════════════════════════════════════════

func process(_delta: float) -> void:
	var target: Node2D = owner_node.get_current_target()

	if target == null:
		return   # stay idle, looping animation keeps playing

	var dist: float = owner_node.global_position.distance_to(target.global_position)
	_update_facing(target)

	if dist <= owner_node.attack_range:
		transition_to("Attack")
	else:
		transition_to("Walk")


# ═══════════════════════════════════════════════
# PRIVATE
# ═══════════════════════════════════════════════

func _update_facing(target: Node2D) -> void:
	var dir_vec: Vector2 = (target.global_position - owner_node.global_position).normalized()
	var new_angle: int = DirectionUtil.vector_to_angle(dir_vec)
	if new_angle != -1:
		owner_node.current_direction = new_angle
