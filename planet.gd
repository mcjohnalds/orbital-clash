class_name Planet
extends StaticBody2D

var mass := 8000.0
var circle: CircleShape2D
@onready var color_circle: ColorCircle = $ColorCircle
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	circle = collision_shape.shape
