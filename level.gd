class_name Level
extends Node2D

const MUSIC_BPM := 160.0
const MIN_ORBIT_DISTANCE := 50.0
const MAX_ORBIT_DISTANCE := 1500.0
const ENEMY_FIRE_RATE := 2.0
const PLAYER_FIRE_RATE := MUSIC_BPM / 60.0
const HEALTH_PICKUP_AMOUNT := 0.2
const FUEL_PICKUP_AMOUNT := 1.0
const BULLET_LIFETIME = 6.0
const BULLET_SPEED := 350.0
const PLANET_ENEMY_COLOR := Color("806787")
const PLANET_PLAYER_COLOR := Color("678784")
const GRAVITY := 9.8
const ENEMY_DAMAGE := 0.17
const PLANET_DAMAGE := 0.17
const PLAYER_DAMAGE_COOLDOWN := 8.0
const PLANET_BOUNCE_SPEED := 300.0
var planets_captured := 0
var current_time := 0.0
var confirm_restart := false
@onready var player: Player = $Player
@onready var bullet_scene := preload("res://bullet.tscn")
@onready var planet_scene := preload("res://planet.tscn")
@onready var fuel_scene := preload("res://fuel.tscn")
@onready var health_scene := preload("res://health.tscn")
@onready var moon_scene := preload("res://moon.tscn")
@onready var enemy_scene := preload("res://enemy.tscn")
var planet_textures: Array[Texture2D] = [
	preload("res://planet_1.png"),
	preload("res://planet_2.png"),
	preload("res://planet_3.png"),
	preload("res://planet_4.png"),
	preload("res://planet_5.png"),
]
@onready var bars: Control = $CanvasLayer/Bars
@onready var health_bar: Panel = $CanvasLayer/Bars/Health
@onready var health_bar_fill: Panel = $CanvasLayer/Bars/Health/Fill
@onready var boost_bar: Panel = $CanvasLayer/Bars/Boost
@onready var boost_bar_fill: Panel = $CanvasLayer/Bars/Boost/Fill
@onready var enemy_planet_indicator: Control = $CanvasLayer/EnemyPlanetIndicator
@onready var enemy_planet_indicator_text: Control = $CanvasLayer/EnemyPlanetIndicator/Text
@onready var enemy_planet_indicator_label: Label = $CanvasLayer/EnemyPlanetIndicator/Text/Label
@onready var enemy_planet_indicator_arrow: Control = $CanvasLayer/EnemyPlanetIndicator/Arrow
@onready var planets_captured_label_bottom_right: Label = $CanvasLayer/PlanetsCapturedLabelBottomRight
@onready var planets_captured_label_center: Label = $CanvasLayer/PlanetsCapturedLabelCenter
@onready var planet_captured_label: Label = $CanvasLayer/PlanetCapturedLabel
@onready var speed_up_button: Button = $CanvasLayer/SpeedUpButton
@onready var pause_button: Button = $CanvasLayer/PauseButton
@onready var paused_control: Control = $CanvasLayer/Paused
@onready var play_button: Button = $CanvasLayer/Paused/PlayButton
@onready var restart_button: Button = $CanvasLayer/RestartButton
@onready var game_over_label: Label = $CanvasLayer/GameOverLabel
@onready var pause_menu_restart_button: Button = $CanvasLayer/Paused/RestartButton
@onready var bullets: Node2D = $Bullets
@onready var game_over_asp: AudioStreamPlayer = $GameOverASP
@onready var planet_captured_asp: AudioStreamPlayer = $PlanetCapturedASP
@onready var enemy_planet_asp: AudioStreamPlayer = $EnemyPlanetASP
@onready var speed_up_asp: AudioStreamPlayer = $SpeedUpASP


func _ready() -> void:
	speed_up_asp.play()
	var start_planet := create_planet()
	set_planet_to_player(start_planet)

	var player_planet_r := start_planet.circle.radius + 1000.0
	player.global_position = start_planet.global_position + Vector2(player_planet_r, 0.0)
	var player_orbital_speed := sqrt(GRAVITY * start_planet.mass / player_planet_r)
	player.linear_velocity = Vector2(0.0, player_orbital_speed)

	pause_button.button_down.connect(on_pause_button_down)
	play_button.button_down.connect(on_play_button_down)
	restart_button.button_down.connect(on_restart_button_down)
	pause_menu_restart_button.button_down.connect(on_pause_menu_restart_button_down)

	get_tree().create_timer(2.0).timeout.connect(create_enemy_planet)

	update_world_volume()

	for line: Line2D in player.exhaust_lines.get_children():
		line.clear_points()
		line.modulate = Main.PLAYER_COLORS[0]
		line.modulate.a = 0.2


func create_planet() -> Planet:
	var planet: Planet = planet_scene.instantiate()

	var sprite: Sprite2D = planet.get_node("Sprite2D")
	sprite.texture = planet_textures.pick_random()

	add_child(planet)

	var dir := Vector2.from_angle(randf_range(-0.25, 0.25) * TAU)
	var distance := randf_range(15000.0, 20000.0)
	planet.global_position = player.global_position + dir * distance

	planet.body_entered.connect(on_planet_body_entered.bind(planet))

	if planets_captured > 2:
		var moon: Moon = moon_scene.instantiate()
		add_child(moon)
		moon.planet = planet
		moon.planet_theta = randf_range(0.0, TAU)
		moon.planet_r = planet.circle.radius + moon.circle.radius + randf_range(MIN_ORBIT_DISTANCE, MAX_ORBIT_DISTANCE)
		moon.position = moon.planet.position + Vector2.from_angle(moon.planet_theta) * moon.planet_r
		moon.body_entered.connect(on_planet_body_entered.bind(moon))
		planet.moon = moon

	return planet


func create_enemy_planet() -> void:
	var planet := create_planet()

	var enemies := mini(planets_captured + 1, 5)
	for i in enemies:
		var enemy: Enemy = enemy_scene.instantiate()
		enemy.planet = planet
		enemy.planet_theta = randf_range(0.0, TAU)
		enemy.planet_r = planet.circle.radius + randf_range(MIN_ORBIT_DISTANCE, MAX_ORBIT_DISTANCE)
		enemy.position = enemy.planet.position + Vector2.from_angle(enemy.planet_theta) * enemy.planet_r
		add_child(enemy)
		enemy.exhaust_line.clear_points()
		enemy.exhaust_line.modulate = Main.ENEMY_COLORS[0]
		enemy.exhaust_line.modulate.a = 0.2

	var scene: PackedScene = [fuel_scene, health_scene].pick_random()
	var pickup: Area2D = scene.instantiate()
	add_child(pickup)
	var pickup_dir := Vector2.from_angle(randf_range(0.0, TAU))
	var pickup_dist := planet.circle.radius + randf_range(500.0, 2000.0)
	pickup.global_position = planet.global_position + pickup_dir * pickup_dist
	pickup.body_entered.connect(on_pickup_body_entered.bind(pickup))

	update_enemy_planet_indicator()
	enemy_planet_indicator.visible = true


func _physics_process(delta: float) -> void:
	current_time += delta
	physics_process_player(delta)
	physics_process_planets(delta)
	physics_process_bullets(delta)
	physics_process_enemy(delta)
	physics_process_ui()


func physics_process_player(delta) -> void:
	if player.alive:
		var mouse_global_position := player.camera.global_position - player.camera.get_viewport_rect().size / 2.0 + get_viewport().get_mouse_position()
		var max_torque := 200000.0
		var kp := 5.0
		var kd := 2.0
		var angle := player.get_angle_to(mouse_global_position)
		var desired_torque := max_torque * (kp * angle + kd * -player.angular_velocity)
		var actual_torque := clampf(desired_torque, -max_torque, max_torque)
		player.apply_torque(actual_torque)

	var thrust := 200.0
	var thrusting := player.alive and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not speed_up_button.button_pressed
	if thrusting:
		player.apply_central_force(player.transform.x * thrust)

	for p: GPUParticles2D in player.exhaust.get_children():
		p.emitting = thrusting

	var boost_m := -0.01 if thrusting else 0.0

	player.boost = clampf(player.boost + boost_m * delta, 0.0, 1.0)

	if player.boost == 0.0 and player.alive:
		kill_player()

	player.thrust_asp.stream_paused = not thrusting

	if player.visible:
		for planet: Planet in get_tree().get_nodes_in_group("planets"):
			var v := planet.global_position - player.global_position
			var d := v.normalized()
			var r := v.length()
			player.apply_central_force(d * GRAVITY * player.mass * planet.mass / (r ** 2.0))

		for i in player.exhaust_lines.get_child_count():
			var line: Line2D = player.exhaust_lines.get_child(i)
			var point: Node2D = player.exhaust_points.get_child(i)
			line.add_point(point.global_position)
			if line.points.size() > 200:
				line.remove_point(0)

	if current_time - player.last_fired_at >= 1.0 / PLAYER_FIRE_RATE and player.alive:
		player.last_fired_at = current_time
		var bullet: Bullet = bullet_scene.instantiate()
		bullet.position = player.position
		bullet.velocity = player.linear_velocity + player.transform.x * BULLET_SPEED
		bullet.body_entered.connect(on_bullet_body_entered.bind(bullet))
		bullet.area_entered.connect(on_bullet_area_entered.bind(bullet))
		bullet.created_at = current_time
		bullet.source = Bullet.Source.PLAYER
		bullets.add_child(bullet)

		bullet.line.clear_points()
		bullet.line.modulate = Main.PLAYER_COLORS[0]
		bullet.line.modulate.a = 0.1
		bullet.sprite.modulate = Main.PLAYER_COLORS[0]

		player.shoot_asp.play()

	var damage_cooldown := current_time - player.last_hit_at < PLAYER_DAMAGE_COOLDOWN
	if damage_cooldown and player.alive:
		if fmod(current_time, 0.2) < 0.1:
			player.modulate.a = 0.3
		else:
			player.modulate.a = 1.0
	else:
		player.modulate.a = 1.0


func physics_process_planets(delta: float) -> void:
	for planet: Planet in get_tree().get_nodes_in_group("planets"):
		planet.rotation += delta * TAU / 100.0


func physics_process_bullets(delta: float) -> void:
	for bullet: Bullet in get_tree().get_nodes_in_group("bullets"):
		for planet: Planet in get_tree().get_nodes_in_group("planets"):
			var v := planet.global_position - bullet.global_position
			var d := v.normalized()
			var r := v.length()
			bullet.velocity += d * GRAVITY * planet.mass / (r ** 2.0) * delta

		bullet.position += bullet.velocity * delta
		if current_time - bullet.created_at > BULLET_LIFETIME:
			bullet.queue_free()

		bullet.line.add_point(bullet.global_position)
		if bullet.line.points.size() > 30:
			bullet.line.remove_point(0)


func physics_process_enemy(delta: float) -> void:
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.alive:
			continue
		# Speed is velocity required for circular orbit
		var speed := sqrt(GRAVITY * enemy.planet.mass / enemy.planet_r)
		enemy.planet_theta += atan2(enemy.planet_r, 0.0) - atan2(enemy.planet_r, speed * delta)
		var last_position := enemy.position
		enemy.position = enemy.planet.position + Vector2.from_angle(enemy.planet_theta) * enemy.planet_r
		var velocity := (enemy.position - last_position) / delta

		enemy.exhaust_line.add_point(enemy.global_position)
		if enemy.exhaust_line.points.size() > 200:
			enemy.exhaust_line.remove_point(0)

		if player.visible:
			var fire_rate := ENEMY_FIRE_RATE
			if current_time - enemy.last_fired_at >= 1.0 / fire_rate:
				enemy.shoot_asp.play()
				enemy.last_fired_at = current_time
				var bullet: Bullet = bullet_scene.instantiate()
				bullet.position = enemy.position
				var player_angle := enemy.position.angle_to_point(player.position)
				var spray := 0.05 * sin(current_time) * TAU
				var spread := 0.02 * randf_range(-1.0, 1.0) * TAU
				var bullet_angle := player_angle + spray + spread
				enemy.rotation = bullet_angle
				var bullet_dir := Vector2.from_angle(bullet_angle)
				bullet.velocity = velocity + bullet_dir * BULLET_SPEED
				bullet.body_entered.connect(on_bullet_body_entered.bind(bullet))
				bullet.area_entered.connect(on_bullet_area_entered.bind(bullet))
				bullet.created_at = current_time
				bullet.source = Bullet.Source.ENEMY
				bullets.add_child(bullet)

				bullet.line.clear_points()
				bullet.line.modulate = Main.ENEMY_COLORS[0]
				bullet.line.modulate.a = 0.1
				bullet.sprite.modulate = Main.ENEMY_COLORS[0]
				bullet.line.visible = true


func physics_process_ui() -> void:
	health_bar_fill.size.x = health_bar.size.x * player.health
	boost_bar_fill.size.x = boost_bar.size.x * player.boost
	update_enemy_planet_indicator()

	speed_up_asp.stream_paused = not speed_up_button.button_pressed
	if speed_up_button.button_pressed and player.alive:
		Engine.time_scale = 10.0
		Engine.physics_ticks_per_second = 600
		Engine.max_physics_steps_per_frame = 80
	else:
		Engine.time_scale = 1.0
		Engine.physics_ticks_per_second = 60
		Engine.max_physics_steps_per_frame = 8


func _input(event: InputEvent) -> void:
	var z := player.camera.zoom.x
	if event is InputEventPanGesture:
		var g := event as InputEventPanGesture
		z += z * g.delta.y * 0.05
	elif event.is_action("scroll_up"):
		z *= 0.8
	elif event.is_action("scroll_down"):
		z *= 1.2
	z = clampf(z, 0.1, 2.0)
	player.camera.zoom = Vector2(z, z)
	update_world_volume()


func update_world_volume() -> void:
	var vol := remap(player.camera.zoom.x, 0.1, 2.0, -5.0, 0.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("World"), vol)


func on_bullet_area_entered(area: Area2D, bullet: Bullet) -> void:
	if area is Planet or area is Moon:
		bullet.queue_free()

	if area is Enemy and bullet.source == Bullet.Source.PLAYER:
		var enemy: Enemy = area
		if not enemy.alive:
			return

		bullet.queue_free()
		enemy.alive = false
		enemy.visible = false
		enemy.explosion_asp.finished.connect(enemy.queue_free)
		enemy.explosion_asp.play()

		if planet_has_living_enemy(enemy.planet):
			return

		# Need to get a reference to the planet because the enemy will be freed
		var planet = enemy.planet

		if not player.alive:
			return
		enemy_planet_indicator.visible = false
		planet_captured_asp.play()
		# It takes 1.7 seconds to reach the "climax" of the planet captured
		# sound effect
		await get_tree().create_timer(1.7).timeout
		if not player.alive:
			return
		set_planet_to_player(planet)
		planets_captured += 1
		planet_captured_label.visible = true
		planets_captured_label_bottom_right.text = "PLANETS CAPTURED: %s" % planets_captured
		planets_captured_label_bottom_right.visible = true
		await get_tree().create_timer(2.0).timeout
		if not player.alive:
			return
		create_enemy_planet()
		planet_captured_label.visible = false


func planet_has_living_enemy(planet: Planet) -> bool:
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.alive and enemy.planet == planet:
			return true
	return false


func on_bullet_body_entered(body: Node2D, bullet: Bullet) -> void:
	if body is Player and bullet.source == Bullet.Source.ENEMY and player.visible:
		player.hit_asp.play()
		var damage_cooldown := current_time - player.last_hit_at < PLAYER_DAMAGE_COOLDOWN
		if not damage_cooldown and player.alive:
			player.last_hit_at = current_time
			player.health = maxf(player.health - ENEMY_DAMAGE, 0.0)
			if player.health == 0.0:
				kill_player()
		bullet.queue_free()


func on_planet_body_entered(body: Node2D, planet: Node2D) -> void:
	if body is Player and player.visible:
		player.hit_asp.play()
		var damage_cooldown := current_time - player.last_hit_at < PLAYER_DAMAGE_COOLDOWN
		if not damage_cooldown and player.alive:
			player.last_hit_at = current_time
			player.health = maxf(player.health - PLANET_DAMAGE, 0.0)
			if player.health == 0.0:
				kill_player()
		var dir := planet.global_position.direction_to(player.global_position)
		player.linear_velocity = dir * PLANET_BOUNCE_SPEED


func kill_player() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), -40.0)

	player.alive = false
	planets_captured_label_bottom_right.visible = false
	planet_captured_label.visible = false
	pause_button.visible = false
	speed_up_button.visible = false
	player.health = 0.0
	player.boost = 0.0
	player.alarm_asp.play()
	player.angular_velocity = TAU * 0.6
	await get_tree().create_timer(0.5).timeout

	player.explosion_asp.play()
	# It takes 1.65 seconds for the explosion sound effect to reach the climax
	await get_tree().create_timer(1.65).timeout

	bars.visible = false
	player.visible = false
	player.alarm_asp.stop()
	# Slow down camera to a stop
	player.linear_damp = 2.0

	await get_tree().create_timer(1.0).timeout
	game_over_label.visible = true
	restart_button.visible = true
	planets_captured_label_center.text = "PLANETS CAPTURED: %s" % planets_captured
	planets_captured_label_center.visible = true
	game_over_asp.play()

# https://en.wikipedia.org/wiki/Ellipse#Polar_form_relative_to_center
func get_ellipse_r(theta: float, size: Vector2) -> float:
	var a := size.x / 2.0
	var b := size.y / 2.0
	return a * b / sqrt((b * cos(theta)) ** 2.0 + (a * sin(theta)) ** 2.0)


func on_pickup_body_entered(body: RigidBody2D, pickup: Variant):
	if not body is Player or not player.alive:
		return
	if pickup is Health:
		player.health_pickup_asp.play()
		player.health += HEALTH_PICKUP_AMOUNT
		player.health = clampf(player.health, 0.0, 1.0)
	else:
		player.fuel_pickup_asp.play()
		player.boost += FUEL_PICKUP_AMOUNT
		player.boost = clampf(player.boost, 0.0, 1.0)
	pickup.queue_free()


func on_pause_button_down() -> void:
	get_tree().paused = true
	paused_control.visible = true
	global.interface_asp.play()


func on_play_button_down() -> void:
	get_tree().paused = false
	paused_control.visible = false
	confirm_restart = false
	pause_menu_restart_button.text = "RESTART"
	global.interface_asp.play()


func on_restart_button_down() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), -20.0)
	global.interface_asp.play()


func on_pause_menu_restart_button_down() -> void:
	global.interface_asp.play()
	if confirm_restart:
		get_tree().paused = false
		get_tree().reload_current_scene()
	else:
		confirm_restart = true
		pause_menu_restart_button.text = "REALLY?"


func set_planet_to_player(planet: Planet) -> void:
	planet.enemy = false
	set_color_to_player(planet)
	if planet.moon:
		set_color_to_player(planet.moon)


func set_color_to_player(node: Node) -> void:
	var sprite: Sprite2D = node.get_node("Sprite2D")
	var shader: ShaderMaterial = sprite.material
	shader.set_shader_parameter("shiftHue", -0.26)


func update_enemy_planet_indicator() -> void:
	var nearest_enemy_planet: Planet
	for planet: Planet in get_tree().get_nodes_in_group("planets"):
		if not planet.enemy:
			continue
		if not nearest_enemy_planet:
			nearest_enemy_planet = planet
			continue
		var d1 := planet.global_position.distance_to(player.global_position)
		var d2 := nearest_enemy_planet.global_position.distance_to(player.global_position)
		if d1 < d2:
			nearest_enemy_planet = planet

	if nearest_enemy_planet:
		var dir := player.global_position.direction_to(nearest_enemy_planet.global_position)
		var ellipse_size := get_viewport_rect().size * Vector2(0.7, 0.8)
		var theta := dir.angle()
		var r := get_ellipse_r(theta, ellipse_size)
		var viewport_center := get_viewport_rect().size / 2.0
		enemy_planet_indicator_text.position = viewport_center + dir * r
		var dist := player.global_position.distance_to(nearest_enemy_planet.global_position)
		enemy_planet_indicator_label.text = "ENEMY PLANET %s Mm" % round(dist / 1000.0)

		var ellipse_2_size := enemy_planet_indicator_label.size * Vector2(1.2, 3.0)
		var r_2 := get_ellipse_r(theta, ellipse_2_size)
		var p := enemy_planet_indicator_text.position
		enemy_planet_indicator_arrow.position = p + dir * r_2
		enemy_planet_indicator_arrow.rotation = theta
