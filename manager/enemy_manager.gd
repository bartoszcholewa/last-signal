extends Node

const SPAWN_RADIUS: int = 1500

@onready var spawn_timer: Timer = %SpawnTimer

var entities_scene: Node2D

# Enemies
const ENEMY_SPIDER_SCENE: PackedScene = preload("uid://c50cfbvm3867o")


func _ready() -> void:
	entities_scene = get_tree().get_first_node_in_group("entities")
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)


func _on_spawn_timer_timeout():
	var turret: StaticBody2D = get_tree().get_first_node_in_group("turret")
	if not turret:
		push_error("No turret found!")
		return

	var random_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
	var spawn_position = turret.global_position + (random_direction * SPAWN_RADIUS)

	var enemy: Spider = ENEMY_SPIDER_SCENE.instantiate()
	enemy.global_position = spawn_position
	entities_scene.add_child(enemy)
