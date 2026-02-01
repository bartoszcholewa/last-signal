# SpawnState.gd
# ─────────────────────────────────────────────
# SPAWN  — plays the one-shot spawn animation, then holds for a
# configurable duration before handing off to Idle.
#
# This is the initial state of every spider.  It runs exactly once
# at the start of the enemy's lifetime and is never re-entered.
#
# Transitions:
#   → Idle     when the hold timer expires
# ─────────────────────────────────────────────
extends State


# ═══════════════════════════════════════════════
# EXPORTS
# ═══════════════════════════════════════════════

# How long (seconds) to stay idle AFTER the spawn animation finishes,
# before transitioning to Idle and becoming reactive.
# Set to 0.0 to transition immediately when the animation ends.
@export var hold_duration: float = 5.0


# ═══════════════════════════════════════════════
# INTERNAL
# ═══════════════════════════════════════════════

# Two phases — no need for more:
#   ANIMATING → waiting for the one-shot spawn animation to finish
#   HOLDING   → animation done, counting down hold_duration
enum Phase { ANIMATING, HOLDING }

var _phase: Phase = Phase.ANIMATING
var _hold_timer: float = 0.0
var _sprite: AnimatedSprite2D


# ═══════════════════════════════════════════════
# ENTER / EXIT
# ═══════════════════════════════════════════════

func enter() -> void:
	_sprite = owner_node.get_node("AnimatedSprite2D")
	_phase = Phase.ANIMATING
	_hold_timer = 0.0

	# Play spawn animation once.  This MUST be called only here, never
	# again per frame — calling play() every frame resets the animation
	# and breaks one-shot playback in Godot 4.
	# Make sure all "spawn_*" animations have the loop button turned
	# OFF in the SpriteFrames editor.
	play_animation("spawn", owner_node.current_direction)

	if not _sprite.animation_finished.is_connected(_on_spawn_finished):
		_sprite.animation_finished.connect(_on_spawn_finished)


func exit() -> void:
	if _sprite and _sprite.animation_finished.is_connected(_on_spawn_finished):
		_sprite.animation_finished.disconnect(_on_spawn_finished)


# ═══════════════════════════════════════════════
# PROCESS
# ═══════════════════════════════════════════════

func process(delta: float) -> void:
	match _phase:
		Phase.ANIMATING:
			# Waiting for animation_finished — nothing to do.
			pass

		Phase.HOLDING:
			_hold_timer += delta
			if _hold_timer >= hold_duration:
				transition_to("Idle")


# ═══════════════════════════════════════════════
# SIGNAL CALLBACKS
# ═══════════════════════════════════════════════

func _on_spawn_finished() -> void:
	if _sprite.animation_finished.is_connected(_on_spawn_finished):
		_sprite.animation_finished.disconnect(_on_spawn_finished)

	# If hold_duration is 0 we can skip straight to Idle.
	if hold_duration <= 0.0:
		transition_to("Idle")
	else:
		_phase = Phase.HOLDING
		play_animation("idle", owner_node.current_direction)
