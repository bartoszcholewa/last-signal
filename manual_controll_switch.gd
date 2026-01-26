extends CheckButton

func _ready() -> void:
	toggled.connect(_on_button_toggled)

func _on_button_toggled(toggled_on: bool):
	GameEvents.manual_control = toggled_on
