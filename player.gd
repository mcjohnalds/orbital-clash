class_name Player
extends RigidBody2D

const COLOR := Color("70b5ae")

@onready var camera: Camera2D = $Camera2D
@onready var exhaust: Node2D = $Exhaust
@onready var thrust_asp: AudioStreamPlayer2D = $ThrustASP
@onready var shoot_asp: AudioStreamPlayer2D = $ShootASP
@onready var alarm_asp: AudioStreamPlayer2D = $AlarmASP
@onready var hit_asp: AudioStreamPlayer2D = $HitASP
@onready var explosion_asp: AudioStreamPlayer2D = $ExplosionASP
var health := 1.0
var alive := true
var boost := 1.0
var last_fired_at := -10000.0
var auto_turret_enabled := false
var auto_turret_last_fired_at := -10000.0
var last_hit_at := -10000.0
