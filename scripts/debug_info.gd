extends Node2D


func _ready() -> void:
	visible = GameEvents.debug_info
	GameEvents.debug_info_changed.connect(_on_debug_info_changed)


func _on_debug_info_changed() -> void:
	visible = GameEvents.debug_info
