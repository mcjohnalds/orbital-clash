@tool
class_name ColorCircle
extends Control


@export var color := Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		color = value
		queue_redraw()


@export var radius := 10.0:
	set(value):
		radius = value
		queue_redraw()


func _draw() -> void:
	size = Vector2(1.0, 1.0) * radius * 2.0
	var center := size / 2.0
	draw_circle(center, radius, color)
