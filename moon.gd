class_name Moon
extends Area2D

var planet: Planet
var planet_r: float
var planet_theta: float
var circle: CircleShape2D
@onready var color_circle: ColorCircle = $ColorCircle
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	circle = collision_shape.shape
