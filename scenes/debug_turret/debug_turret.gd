extends StaticBody2D

@export var max_health: int = 1

var health: int

func _ready() -> void:
	health = max_health

# ═══════════════════════════════════════════════
# DAMAGE / HEALTH
# ═══════════════════════════════════════════════

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		health = 0
		_die()


func _die() -> void:
	queue_free()
