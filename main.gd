class_name Main
extends Node2D

var level_scene := preload("res://level.tscn")
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var start_button: Button = $CanvasLayer/StartButton


func _ready() -> void:
	start_button.button_down.connect(on_start_button_pressed)


func on_start_button_pressed() -> void:
	canvas_layer.visible = false
	var level := level_scene.instantiate()
	add_child(level)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

