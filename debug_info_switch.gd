extends CheckButton

func _ready() -> void:
	button_pressed = GameEvents.debug_info
	toggled.connect(_on_button_toggled)

func _on_button_toggled(toggled_on: bool):
	GameEvents.debug_info = toggled_on
