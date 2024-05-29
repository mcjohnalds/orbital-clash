class_name Level
extends Node2D

const BULLET_LIFETIME = 6.0
const BULLET_SPEED := 350.0
const PLANET_ENEMY_COLOR := Color("806787")
const PLANET_PLAYER_COLOR := Color("678784")
const GRAVITY := 9.8
const ENEMY_DAMAGE := 0.17
const PLANET_DAMAGE := 0.17
const PLAYER_DAMAGE_COOLDOWN := 8.0
const PLANET_BOUNCE_SPEED := 300.0
@onready var player: Player = $Player
@onready var bullet_scene := preload("res://bullet.tscn")
@onready var planet_scene := preload("res://planet.tscn")
@onready var moon_scene := preload("res://moon.tscn")
@onready var enemy_scene := preload("res://enemy.tscn")
@onready var health_bar: Panel = $CanvasLayer/Health
@onready var health_bar_fill: Panel = $CanvasLayer/Health/Fill
@onready var boost_bar: Panel = $CanvasLayer/Boost
@onready var boost_bar_fill: Panel = $CanvasLayer/Boost/Fill
@onready var enemy_planet_indicator: Control = $CanvasLayer/EnemyPlanetIndicator
@onready var enemy_planet_indicator_text: Control = $CanvasLayer/EnemyPlanetIndicator/Text
@onready var enemy_planet_indicator_label: Label = $CanvasLayer/EnemyPlanetIndicator/Text/Label
@onready var enemy_planet_indicator_arrow: Control = $CanvasLayer/EnemyPlanetIndicator/Arrow


func _ready() -> void:
	var planet_1: Planet = get_tree().get_nodes_in_group("planets")[0]
	var player_planet_r := 4000.0
	player.global_position = planet_1.global_position + Vector2(player_planet_r, 0.0)
	var player_orbital_speed := sqrt(GRAVITY * planet_1.mass / player_planet_r)
	player.linear_velocity = Vector2(0.0, player_orbital_speed)

	for planet: Planet in get_tree().get_nodes_in_group("planets"):
		planet.color_circle.color = PLANET_ENEMY_COLOR
		planet.body_entered.connect(on_planet_body_entered.bind(planet))

		var min_r := 50.0
		var max_r := 1500.0

		var moon: Moon = moon_scene.instantiate()
		moon.planet = planet
		moon.planet_theta = randf_range(0.0, TAU)
		moon.planet_r = planet.circle.radius + randf_range(min_r, max_r)
		moon.position = moon.planet.position + Vector2.from_angle(moon.planet_theta) * moon.planet_r
		moon.body_entered.connect(on_planet_body_entered.bind(moon))
		add_child(moon)
		moon.color_circle.color = PLANET_ENEMY_COLOR
		planet.moon = moon

		for i in 3:
			var enemy: Enemy = enemy_scene.instantiate()
			enemy.planet = planet
			enemy.planet_theta = randf_range(0.0, TAU)
			enemy.planet_r = planet.circle.radius + randf_range(min_r, max_r)
			enemy.position = enemy.planet.position + Vector2.from_angle(enemy.planet_theta) * enemy.planet_r
			add_child(enemy)


func _physics_process(delta: float) -> void:
	physics_process_player(delta)
	physics_process_planets(delta)
	physics_process_bullets(delta)
	physics_process_enemy(delta)
	physics_process_ui()


func physics_process_player(delta) -> void:
	if !player.alive:
		player.visible = false
		return

	var mouse_global_position := player.camera.global_position - player.camera.get_viewport_rect().size / 2.0 + get_viewport().get_mouse_position()
	var max_torque := 200000.0
	var kp := 5.0
	var kd := 2.0
	var angle := player.get_angle_to(mouse_global_position)
	var desired_torque := max_torque * (kp * angle + kd * -player.angular_velocity)
	var actual_torque := clampf(desired_torque, -max_torque, max_torque)
	player.apply_torque(actual_torque)

	var thrust := 200.0
	var thrusting := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and player.boost > 0.0
	if thrusting:
		player.apply_central_force(player.transform.x * thrust)
	player.exhaust.visible = thrusting
	var boost_m := -0.2 if thrusting else 0.1
	player.boost = clampf(player.boost + boost_m * delta, 0.0, 1.0)
	player.boost = 1.0

	for planet: Planet in get_tree().get_nodes_in_group("planets"):
		var v := planet.global_position - player.global_position
		var d := v.normalized()
		var r := v.length()
		player.apply_central_force(d * GRAVITY * player.mass * planet.mass / (r ** 2.0))

	if player.cannon_enabled and get_ticks_sec() - player.cannon_last_fired_at >= 1.0 / Player.CANNON_FIRE_RATE:
		player.cannon_last_fired_at = get_ticks_sec()
		var bullet: Bullet = bullet_scene.instantiate()
		bullet.position = player.position
		bullet.velocity = player.linear_velocity + player.transform.x * BULLET_SPEED
		bullet.body_entered.connect(on_bullet_body_entered.bind(bullet))
		bullet.area_entered.connect(on_bullet_area_entered.bind(bullet))
		bullet.created_at = get_ticks_sec()
		bullet.source = Bullet.Source.PLAYER
		add_child(bullet)
		bullet.color_circle.color = Player.COLOR

	if player.auto_turret_enabled and get_ticks_sec() - player.auto_turret_last_fired_at >= 1.0 / Player.AUTO_TURRET_FIRE_RATE:
		player.auto_turret_last_fired_at = get_ticks_sec()
		var bullet: Bullet = bullet_scene.instantiate()
		bullet.position = player.position

		var nearest_enemy: Enemy = null
		for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
			if not nearest_enemy:
				nearest_enemy = enemy
				continue
			var d1 := enemy.position.distance_to(player.position)
			var d2 := nearest_enemy.position.distance_to(player.position)
			if d1 < d2:
				nearest_enemy = enemy

		var dir := player.transform.x
		if nearest_enemy:
			dir = player.position.direction_to(nearest_enemy.position)

		bullet.velocity = player.linear_velocity + dir * BULLET_SPEED
		bullet.body_entered.connect(on_bullet_body_entered.bind(bullet))
		bullet.area_entered.connect(on_bullet_area_entered.bind(bullet))
		bullet.created_at = get_ticks_sec()
		bullet.source = Bullet.Source.PLAYER
		add_child(bullet)
		bullet.color_circle.color = Player.COLOR

	var damage_cooldown := get_ticks_sec() - player.last_hit_at < PLAYER_DAMAGE_COOLDOWN
	if damage_cooldown:
		if fmod(get_ticks_sec(), 0.2) < 0.1:
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
		if get_ticks_sec() - bullet.created_at > BULLET_LIFETIME:
			bullet.queue_free()


func physics_process_enemy(delta: float) -> void:
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		# Speed is velocity required for circular orbit
		var speed := sqrt(GRAVITY * enemy.planet.mass / enemy.planet_r)
		enemy.planet_theta += atan2(enemy.planet_r, 0.0) - atan2(enemy.planet_r, speed * delta)
		var last_position := enemy.position
		enemy.position = enemy.planet.position + Vector2.from_angle(enemy.planet_theta) * enemy.planet_r
		var velocity := (enemy.position - last_position) / delta

		if player.alive:
			var fire_rate := 4.0
			if get_ticks_sec() - enemy.last_fired_at >= 1.0 / fire_rate:
				enemy.last_fired_at = get_ticks_sec()
				var bullet: Bullet = bullet_scene.instantiate()
				bullet.position = enemy.position
				var player_angle := enemy.position.angle_to_point(player.position)
				var spray := 0.05 * sin(get_ticks_sec()) * TAU
				var spread := 0.02 * randf_range(-1.0, 1.0) * TAU
				var bullet_angle := player_angle + spray + spread
				enemy.rotation = bullet_angle
				var bullet_dir := Vector2.from_angle(bullet_angle)
				bullet.velocity = velocity + bullet_dir * BULLET_SPEED
				bullet.body_entered.connect(on_bullet_body_entered.bind(bullet))
				bullet.area_entered.connect(on_bullet_area_entered.bind(bullet))
				bullet.created_at = get_ticks_sec()
				bullet.source = Bullet.Source.ENEMY
				add_child(bullet)
				bullet.color_circle.color = Enemy.COLOR


func physics_process_ui() -> void:
	if player.alive:
		health_bar_fill.size.x = health_bar.size.x * player.health
		boost_bar_fill.size.x = boost_bar.size.x * player.boost
	else:
		health_bar_fill.visible = false
		boost_bar_fill.visible = false

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
		enemy_planet_indicator.visible = true
		var dir := player.global_position.direction_to(nearest_enemy_planet.global_position)
		var ellipse_size := get_viewport_rect().size * Vector2(0.7, 0.8)
		var theta := dir.angle()
		var r := get_ellipse_r(theta, ellipse_size)
		var viewport_center := get_viewport_rect().size / 2.0
		enemy_planet_indicator_text.position = viewport_center + dir * r
		var dist := player.global_position.distance_to(nearest_enemy_planet.global_position)
		enemy_planet_indicator_label.text = "Enemy planet %s Mm" % round(dist / 1000.0)

		var ellipse_2_size := enemy_planet_indicator_label.size * Vector2(1.2, 3.0)
		var r_2 := get_ellipse_r(theta, ellipse_2_size)
		var p := enemy_planet_indicator_text.position
		enemy_planet_indicator_arrow.position = p + dir * r_2
		enemy_planet_indicator_arrow.rotation = theta
	else:
		enemy_planet_indicator.visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

	var z := player.camera.zoom.x
	if event.is_action("scroll_up"):
		z *= 0.8
	if event.is_action("scroll_down"):
		z *= 1.2
	z = maxf(z, 0.001)
	player.camera.zoom = Vector2(z, z)

	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed:
			if k.keycode == KEY_1:
				player.cannon_enabled = !player.cannon_enabled
			if k.keycode == KEY_2:
				player.auto_turret_enabled = !player.auto_turret_enabled


func get_ticks_sec() -> float:
	return Time.get_ticks_msec() / 1000.0


func on_bullet_area_entered(area: Area2D, bullet: Bullet) -> void:
	if area is Planet or area is Moon:
		bullet.queue_free()

	if area is Enemy and bullet.source == Bullet.Source.PLAYER:
		var enemy: Enemy = area
		enemy.queue_free()
		bullet.queue_free()

		var planet_has_enemy := false
		for enemy2: Enemy in get_tree().get_nodes_in_group("enemies"):
			if not enemy2.is_queued_for_deletion() and enemy2.planet == enemy.planet:
				planet_has_enemy = true
		if not planet_has_enemy:
			enemy.planet.enemy = false
			enemy.planet.color_circle.color = PLANET_PLAYER_COLOR
			enemy.planet.moon.color_circle.color = PLANET_PLAYER_COLOR


func on_bullet_body_entered(body: Node2D, bullet: Bullet) -> void:
	if body is Player and bullet.source == Bullet.Source.ENEMY :
		var damage_cooldown := get_ticks_sec() - player.last_hit_at < PLAYER_DAMAGE_COOLDOWN
		if not damage_cooldown:
			player.last_hit_at = get_ticks_sec()
			player.health = maxf(player.health - ENEMY_DAMAGE, 0.0)
			if player.health == 0.0:
				player.alive = false
				player.process_mode = Node.PROCESS_MODE_DISABLED
		bullet.queue_free()


func on_planet_body_entered(body: Node2D, planet: Node2D) -> void:
	if body is Player:
		var damage_cooldown := get_ticks_sec() - player.last_hit_at < PLAYER_DAMAGE_COOLDOWN
		if not damage_cooldown:
			player.last_hit_at = get_ticks_sec()
			player.health = maxf(player.health - PLANET_DAMAGE, 0.0)
			if player.health == 0.0:
				player.alive = false
				player.process_mode = Node.PROCESS_MODE_DISABLED
		var dir := planet.global_position.direction_to(player.global_position)
		player.linear_velocity = dir * PLANET_BOUNCE_SPEED


# https://en.wikipedia.org/wiki/Ellipse#Polar_form_relative_to_center
func get_ellipse_r(theta: float, size: Vector2) -> float:
	var a := size.x / 2.0
	var b := size.y / 2.0
	return a * b / sqrt((b * cos(theta)) ** 2.0 + (a * sin(theta)) ** 2.0)
