# StateMachine.gd
# ─────────────────────────────────────────────
# Generic reusable FSM node. Attach as a child of any enemy/character.
# Children of THIS node are expected to be State nodes (extend State.gd).
#
# Usage in scene tree:
#   Spider (CharacterBody2D)  ← spider.gd
#     └─ StateMachine          ← this script
#           ├─ Idle             ← idle_state.gd
#           ├─ Walk             ← walk_state.gd
#           ├─ Attack           ← attack_state.gd
#           └─ Die              ← die_state.gd
# ─────────────────────────────────────────────
class_name StateMachine
extends Node

# ── Signals ───────────────────────────────────
signal state_changed(old_state: String, new_state: String)

# ── Public ────────────────────────────────────
# Backing variable holds the actual State reference.
# The public property is read-only: external code must use transition_to().
var _current_state: State

var current_state: State:
	get:
		return _current_state
	set(value):
		push_warning("StateMachine: current_state is read-only. Use transition_to() instead.")

# ── Private ───────────────────────────────────
var _states: Dictionary = {}   # { "Idle": <State node>, ... }
var _owner: CharacterBody2D    # cached reference to the parent enemy


# ═══════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════

func _ready() -> void:
	_owner = get_parent()

	# Register every child State node automatically
	for child in get_children():
		if child is State:
			_states[child.name] = child
			child.state_machine = self
			child.owner_node = _owner

	# No state set yet — caller must call initialize()


# ── initialize() must be called once after scene is ready ──
# @param initial_state_name: the name of the child State node to start in
func initialize(initial_state_name: String) -> void:
	assert(_states.has(initial_state_name),
		"StateMachine: initial state '%s' not found. Available: %s" % [
			initial_state_name, _states.keys()])

	_current_state = _states[initial_state_name]
	_current_state.enter()

	state_changed.emit("", initial_state_name)


# ═══════════════════════════════════════════════
# CORE LOOP  — forwarded from the owner's _process / _physics_process
# ═══════════════════════════════════════════════

func process(delta: float) -> void:
	if _current_state:
		_current_state.process(delta)

func physics_process(delta: float) -> void:
	if _current_state:
		_current_state.physics_process(delta)


# ═══════════════════════════════════════════════
# TRANSITION
# ═══════════════════════════════════════════════

# Call this from any State to switch to another state by name.
# e.g.  state_machine.transition_to("Attack")
func transition_to(new_state_name: String) -> void:
	assert(_states.has(new_state_name),
		"StateMachine: cannot transition to '%s'. Available: %s" % [
			new_state_name, _states.keys()])

	if _current_state and _current_state.name == new_state_name:
		return   # already in that state — no-op

	var old_name: String = _current_state.name if _current_state else ""

	# Exit current
	if _current_state:
		_current_state.exit()

	# Enter new
	_current_state = _states[new_state_name]
	_current_state.enter()

	state_changed.emit(old_name, new_state_name)


# ── Helper: check if a state exists ──────────
func has_state(state_name: String) -> bool:
	return _states.has(state_name)


# ── Helper: get a state node by name (useful for reading flags) ──
func get_state(state_name: String) -> State:
	return _states.get(state_name)
