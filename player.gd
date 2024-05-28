class_name Player
extends RigidBody2D

const COLOR := Color("70b5ae")
const CANNON_FIRE_RATE := 2.0
const AUTO_TURRET_FIRE_RATE := 10.0

@onready var camera: Camera2D = $Camera2D
@onready var exhaust: Node2D = $Exhaust
var health := 1.0
var alive := true
var boost := 1.0
var cannon_enabled := true
var cannon_last_fired_at := -10000.0
var auto_turret_enabled := false
var auto_turret_last_fired_at := -10000.0
var last_hit_at := -10000.0
