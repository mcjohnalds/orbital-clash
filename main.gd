class_name Main
extends Node2D

var level_scene := preload("res://level.tscn")
var level: Level
@onready var menu: CanvasLayer = $Menu
@onready var start_button: Button = $Menu/StartButton
@onready var level_node: Node2D = $Level
@onready var parallax_background: ParallaxBackground = $ParallaxBackground
@onready var graphics_low_button: Button = $Menu/Settings/Graphics/Low
@onready var graphics_high_button: Button = $Menu/Settings/Graphics/High
@onready var film_grain: CanvasLayer = $FilmGrain
@onready var barrel: CanvasLayer = $Barrel
@onready var nebula_1: Node2D = $ParallaxBackground/ParallaxLayer2
@onready var nebula_2: Node2D = $ParallaxBackground/ParallaxLayer3
@onready var nebula_3: CanvasLayer = $ParallaxBackground2
var stars_multiply: FastNoiseLite = preload("res://stars_multiply.tres")
var graphics_high := true

const ENEMY_COLORS: Array[Color] = [
	Color("A570B5"),
	Color("8E70B5"),
	Color("B570A9"),
	Color("7870B5"),
	Color("B57080")
]

const PLAYER_COLORS: Array[Color] = [
	Color("70AAB5"),
	Color("70B5AA"),
	Color("7094B5"),
	Color("70B593"),
	Color("707EB5")
]


func _ready() -> void:
	global.main = self
	start_button.button_down.connect(on_start_button_pressed)
	graphics_low_button.button_down.connect(on_graphics_low_button_pressed)
	graphics_high_button.button_down.connect(on_graphics_high_button_pressed)

	if graphics_high:
		graphics_low_button.modulate.v = 0.6
		graphics_high_button.modulate.v = 1.0
	else:
		graphics_low_button.modulate.v = 1.0
		graphics_high_button.modulate.v = 0.6


func on_start_button_pressed() -> void:
	menu.visible = false
	level = level_scene.instantiate()
	level_node.add_child(level)
	global.interface_asp.play()
	parallax_background.scroll_base_offset = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() and event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0 * 5.0
	if stars_multiply and graphics_high:
		stars_multiply.offset = Vector3(t, 0.0, 0.0)
	if not level:
		parallax_background.scroll_base_offset += Vector2.ONE * delta * 100.0


func on_graphics_low_button_pressed() -> void:
	global.interface_asp.play()
	graphics_low_button.modulate.v = 1.0
	graphics_high_button.modulate.v = 0.6
	graphics_high = false
	film_grain.visible = false
	barrel.visible = false
	nebula_1.visible = false
	nebula_2.visible = false
	nebula_3.visible = false


func on_graphics_high_button_pressed() -> void:
	global.interface_asp.play()
	graphics_low_button.modulate.v = 0.6
	graphics_high_button.modulate.v = 1.0
	graphics_high = true
	film_grain.visible = true
	barrel.visible = true
	nebula_1.visible = true
	nebula_2.visible = true
	nebula_3.visible = true
