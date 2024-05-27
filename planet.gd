class_name Planet
extends Area2D

var mass := 50000000.0
var circle: CircleShape2D
var moon: Moon
@onready var color_circle: ColorCircle = $ColorCircle
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	circle = collision_shape.shape
