extends AnimatedSprite2D

var shader_tween: Tween

func _ready() -> void:
	if owner.has_signal("damaged"):
		owner.damaged.connect(_on_damaged)


func _on_damaged():
	if shader_tween != null and shader_tween.is_valid():
		shader_tween.kill()

	shader_tween = create_tween()
	shader_tween.tween_property(material, "shader_parameter/percent", 0, 0.4)\
	.from(1)\
	.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
