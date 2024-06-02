class_name Main
extends Node2D

var level_scene := preload("res://level.tscn")
var level: Level
@onready var menu: CanvasLayer = $Menu
@onready var start_button: Button = $Menu/StartButton
@onready var level_node: Node2D = $Level
@onready var parallax_background: ParallaxBackground = $ParallaxBackground
var stars_multiply: FastNoiseLite = preload("res://stars_multiply.tres")
var last_stars_multiply_update_time := -1000.0

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
	start_button.button_down.connect(on_start_button_pressed)


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
	if stars_multiply and t - last_stars_multiply_update_time > 1.0:
		stars_multiply.offset = Vector3(t, 0.0, 0.0)
	if not level:
		parallax_background.scroll_base_offset += Vector2.ONE * delta * 100.0
