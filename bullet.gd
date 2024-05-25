class_name Bullet
extends Area2D

enum Source { PLAYER, ENEMY }

var velocity: Vector2
var created_at: float
var source: Source
@onready var color_circle: ColorCircle = $ColorCircle
