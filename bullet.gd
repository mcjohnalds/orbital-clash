class_name Bullet
extends Area2D

enum Source { PLAYER, ENEMY }

var velocity: Vector2
var created_at: float
var source: Source
@onready var sprite: Sprite2D = $Sprite2D
@onready var line: Line2D = $Line2D
