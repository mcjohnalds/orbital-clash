class_name Planet
extends Area2D

var mass := 50000000.0
var circle: CircleShape2D
var moon: Moon
var enemy := true
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	circle = get_node("CollisionShape2D").shape
