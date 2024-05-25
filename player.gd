class_name Player
extends RigidBody2D

const COLOR := Color("70b5ae")

@onready var camera: Camera2D = $Camera2D
@onready var exhaust: Node2D = $Exhaust
var last_fired_at := -10000.0
var health := 1.0
var alive := true
var boost := 1.0
