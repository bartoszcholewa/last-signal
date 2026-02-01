# direction_util.gd
# ─────────────────────────────────────────────
# Autoload singleton.  Centralises ALL direction logic so every state
# and every enemy variant uses exactly the same math.
#
# Register in Project → Autoload:
#   Name: DirectionUtil   Path: res://autoload/direction_util.gd
# ─────────────────────────────────────────────
extends Node


# ═══════════════════════════════════════════════
# CONSTANTS  — the 8 canonical angles (degrees, 0 = right, CCW positive)
# ═══════════════════════════════════════════════
const ANGLES: Array = [0, 45, 90, 135, 180, 225, 270, 315]

# Half-step used for snapping (360 / 8 / 2 = 22.5°)
const HALF_STEP: float = 22.5


# ═══════════════════════════════════════════════
# CORE API
# ═══════════════════════════════════════════════

# Takes a continuous angle (degrees, 0 = right) and snaps it
# to the nearest of the 8 canonical directions.
# Returns an int in {0, 45, 90, 135, 180, 225, 270, 315}.
func snap_angle(angle_deg: float) -> int:
	# Normalise into [0, 360)
	var a: float = fmod(angle_deg, 360.0)
	if a < 0.0:
		a += 360.0

	# Snap: add half-step, integer-divide by step, multiply back
	var step: float = 45.0
	var snapp: int = int((a + HALF_STEP) / step) % 8
	return snapp * int(step)


# Takes a 2D velocity / direction vector and returns the snapped angle.
# Returns 0 if the vector is zero (fallback to last known direction).
func vector_to_angle(direction: Vector2) -> int:
	if direction.is_zero_approx():
		return -1   # sentinel: "no direction info"
	# atan2 gives radians; convert to degrees.
	# Godot's atan2 convention: angle_of(Vector2.RIGHT) == 0
	var rad: float = direction.angle()
	var deg: float = rad_to_deg(rad)
	return snap_angle(deg)


# Converts a snapped angle back to a unit Vector2.
# Useful if a state needs to move the body in the stored direction.
func angle_to_vector(angle_deg: int) -> Vector2:
	return Vector2.RIGHT.rotated(deg_to_rad(float(angle_deg)))
