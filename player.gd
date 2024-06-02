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
@onready var fuel_pickup_asp: AudioStreamPlayer2D = $FuelPickupASP
@onready var health_pickup_asp: AudioStreamPlayer2D = $HealthPickupASP
@onready var exhaust_lines: Node2D = $ExhaustLines
@onready var exhaust_points: Node2D = $ExhaustPoints
@onready var shoot_particles: GPUParticles2D = $ShootParticles
@onready var explosion_particles: Node2D = $ExplosionParticles
@onready var sprite: Sprite2D = $Sprite2D
var exploded := false
var health := 1.0
var alive := true
var boost := 1.0
var last_fired_at := -10000.0
var auto_turret_enabled := false
var auto_turret_last_fired_at := -10000.0
var last_hit_at := -10000.0
