@tool
class_name ImageExporter
extends Node

@export var input: Texture2D
@export_file var output: String

@export var export: bool:
	set(value):
		input.get_image().save_png(output)
		print("Image saved to %s" % output)
