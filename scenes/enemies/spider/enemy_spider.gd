# Spider.gd
# ─────────────────────────────────────────────
# The Spider enemy.  Owns the CharacterBody2D, exposes all tunable
# stats as @export vars, and wires the StateMachine.
#
# Scene tree expected layout:
#   Spider  (CharacterBody2D)         ← this script
#     ├─ AnimatedSprite2D             ← holds all 32 animations (4 states × 8 dirs)
#     ├─ CollisionShape2D             ← hitbox
#     ├─ DetectionArea (Area2D)       ← optional: area that spots the player
#     └─ StateMachine                 ← StateMachine.gd
#           ├─ Spawn                   ← SpawnState.gd
#           ├─ Idle                    ← IdleState.gd
#           ├─ Walk                    ← WalkState.gd
#           ├─ Attack                  ← AttackState.gd
#           └─ Die                     ← DieState.gd
# ─────────────────────────────────────────────
extends CharacterBody2D
class_name Spider


# ═══════════════════════════════════════════════
# EXPORTS  — tweak everything from the Inspector
# ═══════════════════════════════════════════════

# --- Health ---
@export var max_health: int = 100

# Backing variable — internal code reads/writes this directly.
var _health: int

# Public property — the setter clamps and triggers death if needed.
var health: int:
	get:
		return _health
	set(value):
		_health = clamp(value, 0, max_health)
		if _health == 0 and _state_machine and _state_machine.current_state:
			if _state_machine.current_state.name != "Die":
				_die()

# --- Movement ---
@export var walk_speed: float = 120.0

# --- Ranges (pixels) ---
@export var attack_range: float = 150.0
@export var chase_range: float = 1000.0

# --- Direction ---
# Stored as the snapped angle in degrees.  0 = right.
var current_direction: int = 0


# ═══════════════════════════════════════════════
# INTERNAL
# ═══════════════════════════════════════════════

var _state_machine: Node   # cached reference to the StateMachine child
var _target: Node2D = null # current chase/attack target


# ═══════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════

func _ready() -> void:
	_health = max_health   # write backing var directly — _state_machine isn't ready yet
	_state_machine = $StateMachine

	# Boot the FSM into Spawn — SpawnState transitions to Idle when it's done
	_state_machine.initialize("Spawn")


func _process(delta: float) -> void:
	# Forward to the FSM — states drive per-frame logic
	_state_machine.process(delta)


func _physics_process(delta: float) -> void:
	# Forward to the FSM — states drive movement
	_state_machine.physics_process(delta)


# ═══════════════════════════════════════════════
# TARGETING  — replace with your actual targeting / AI system
# ═══════════════════════════════════════════════

# Returns the current target node (e.g. the Player).
# In a real game you'd update _target via an Area2D body_entered signal
# or a behaviour tree.  This stub just finds the first node in group "Player".
func get_current_target() -> Node2D:
	var players: Array = get_tree().get_nodes_in_group("turret")
	if players.is_empty():
		_target = null
	else:
		_target = players[0]
	return _target


# ═══════════════════════════════════════════════
# DAMAGE / HEALTH
# ═══════════════════════════════════════════════

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		health = 0
		_die()


func _die() -> void:
	# Transition to Die — the DieState handles everything from here
	_state_machine.transition_to("Die")
