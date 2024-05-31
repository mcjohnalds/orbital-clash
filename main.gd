@tool
class_name Main
extends Node2D

var level_scene := preload("res://level.tscn")
var level: Level
@onready var menu: CanvasLayer = $Menu
@onready var start_button: Button = $Menu/StartButton
@onready var level_node: Node2D = $Level
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
	if Engine.is_editor_hint():
		return
	start_button.button_down.connect(on_start_button_pressed)


func on_start_button_pressed() -> void:
	if Engine.is_editor_hint():
		return
	menu.visible = false
	level = level_scene.instantiate()
	level_node.add_child(level)


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0 * 5.0
	if stars_multiply and t - last_stars_multiply_update_time > 1.0:
		stars_multiply.offset = Vector3(t, 0.0, 0.0)
	if level and level.player:
		pass
		# for c: ParallaxLayer in get_node('ParallaxBackground2').get_children():
		# 	var z := get_viewport().get_camera_2d().zoom.x * 0.1
		# 	# scale_around_point(c, z, level.player.global_position)
		# 	# c.motion_offset = get_viewport_rect().size*0.5*pow(1-c.motion_scale.x,1)*(1.0 + 1.0/z)
	# if level and level.player:
	# 	var z := get_viewport().get_camera_2d().zoom.x
	# 	parallax_background.scroll_base_scale = Vector2(z, z)
	# 	for i in parallax_background.get_child_count():
	# 		var layer: ParallaxLayer = parallax_background.get_child(i)
	# 		var s := layer_scales[i] * get_viewport().get_camera_2d().zoom.x
	# 		layer.motion_scale = Vector2(s, s)
# 		space_material.set_shader_parameter("position", level.player.global_position / 100000.0)
# 		space_material.set_shader_parameter("zoom", get_viewport().get_camera_2d().zoom)
# 	else:
# 		var t := Time.get_ticks_msec() / 1000.0
# 		var v := Vector2(t, t) / 100.0
# 		space_material.set_shader_parameter("position", v)
# 		space_material.set_shader_parameter("zoom", 0.8)
# 	var size := get_viewport_rect().size
# 	space_material.set_shader_parameter("aspectRatio", size.y / size.x);


func scale_around_point(node: Node2D, scale_factor: float, pivot: Vector2):
	# Calculate the offset from the pivot to the node's position
	var offset = node.position - pivot

	# Translate the node to the origin relative to the pivot
	node.position -= offset

	# Scale the node
	node.scale = Vector2.ONE * scale_factor

	# Translate the node back to its original position relative to the pivot
	offset *= scale_factor
	node.position += offset
