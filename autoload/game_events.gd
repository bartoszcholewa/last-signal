extends Node

signal debug_info_changed

var manual_control: bool = true
var debug_info: bool = true: set = set_debug_info


func set_debug_info(value: bool) -> void:
	debug_info = value
	debug_info_changed.emit()
