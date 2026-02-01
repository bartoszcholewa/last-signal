# State.gd
# ─────────────────────────────────────────────
# Abstract base class for every state in the FSM.
# Each concrete state overrides what it needs.
#
# Subclasses MUST override:
#   - enter()   → called once when entering the state
#   - exit()    → called once when leaving the state
#
# Subclasses MAY override:
#   - process(delta)          → per-frame logic (timers, animation checks)
#   - physics_process(delta)  → per-physics-frame (movement, collision)
# ─────────────────────────────────────────────
class_name State
extends Node

# ── Injected by StateMachine on _ready() ──────
var state_machine: Node    # reference back to the StateMachine node
var owner_node: CharacterBody2D  # the enemy CharacterBody2D


# ═══════════════════════════════════════════════
# VIRTUAL METHODS — override in subclasses
# ═══════════════════════════════════════════════

func enter() -> void:
	pass

func exit() -> void:
	pass

func process(_delta: float) -> void:
	pass

func physics_process(_delta: float) -> void:
	pass


# ═══════════════════════════════════════════════
# SHARED HELPERS — available to every state
# ═══════════════════════════════════════════════

# Shortcut: play an animation on the owner's AnimatedSprite2D
# Animation name is built automatically:  "{state_prefix}_{angle_str}"
#   e.g.  play_animation("walk", 135)  →  "walk_135"
#
# @param prefix  : base name like "idle", "walk", "attack", "die"
# @param angle   : current direction in degrees (snapped to 8-dir by caller)
func play_animation(prefix: String, angle: int) -> void:
	var sprite: AnimatedSprite2D = owner_node.get_node("AnimatedSprite2D")
	# Build the animation name.  Angles are stored as 3-digit zero-padded:
	#   0 → "000",  45 → "045",  315 → "315"
	var anim_name: String = "%s_%03d" % [prefix, angle]

	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	else:
		push_warning("State: animation '%s' not found in SpriteFrames." % anim_name)


# Shortcut to stop the sprite (used in Die to freeze on the last frame)
func stop_animation() -> void:
	var sprite: AnimatedSprite2D = owner_node.get_node("AnimatedSprite2D")
	sprite.stop()


# Shortcut: transition to another state
func transition_to(state_name: String) -> void:
	state_machine.transition_to(state_name)
