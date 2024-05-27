class_name Enemy
extends Area2D

const COLOR := Color("a570b5")
var planet: Planet
var planet_r: float
var planet_theta: float
var last_fired_at := -10000.0
