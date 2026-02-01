extends Label

@export var state_machine: StateMachine

func _ready() -> void:
	if not state_machine:
		push_error("No State Machine attached!")
		return
	state_machine.state_changed.connect(_on_state_changed)


func _on_state_changed(_old_state: String, new_state: String) -> void:
	print("%s -> %s" % [_old_state.to_upper(), new_state.to_upper()])
	text = "State: %s" % new_state.to_upper()
