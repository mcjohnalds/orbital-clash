class_name Enemy
extends Area2D

const COLOR := Color("a570b5")
var planet: Planet
var planet_r: float
var planet_theta: float
var last_fired_at := -10000.0
var alive: bool = true
@onready var shoot_asp: AudioStreamPlayer2D = $ShootASP
@onready var explosion_asp: AudioStreamPlayer2D = $ExplosionASP
@onready var exhaust_line: Line2D = $ExhaustLine
@onready var explosion_particles: Node2D = $ExplosionParticles
@onready var sprite: Sprite2D = $Sprite2D
@onready var shoot_particles: GPUParticles2D = $ShootParticles
