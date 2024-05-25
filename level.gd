class_name Level
extends Node2D

const PLAYER_FIRE_RATE := 2.0
const GRAVITY := 98
@onready var player: Player = $Player
@onready var bullet_scene := preload("res://bullet.tscn")
@onready var enemy_scene := preload("res://enemy.tscn")
@onready var health_bar: Panel = $CanvasLayer/Health
@onready var health_bar_fill: Panel = $CanvasLayer/Health/Fill
@onready var boost_bar: Panel = $CanvasLayer/Boost
@onready var boost_bar_fill: Panel = $CanvasLayer/Boost/Fill


func _ready() -> void:
	player.linear_velocity = Vector2(-500.0, 1000.0)
	for planet: Planet in get_tree().get_nodes_in_group("planets"):
		planet.color_circle.color = Enemy.COLOR
		for i in 3:
			var enemy: Enemy = enemy_scene.instantiate()
			enemy.planet = planet
			enemy.planet_theta = randf_range(0.0, TAU)
			enemy.planet_r = planet.circle.radius + randf_range(800.0, 3000.0)
			enemy.planet_speed = 0.5
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
	var max_torque := 100000.0
	var kp := 1.0
	var kd := 0.3
	var angle := player.get_angle_to(mouse_global_position)
	var desired_torque := max_torque * (kp * angle + kd * -player.angular_velocity)
	var actual_torque := clampf(desired_torque, -max_torque, max_torque)
	player.apply_torque(actual_torque)

	var thrust := 600.0
	var thrusting := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and player.boost > 0.0
	if thrusting:
		player.apply_central_force(player.transform.x * thrust)
	player.exhaust.visible = thrusting
	var boost_m := -1.0 if thrusting else 1.0
	player.boost = clampf(player.boost + boost_m * delta, 0.0, 1.0)

	for planet: Planet in get_tree().get_nodes_in_group("planets"):
		var v := planet.global_position - player.global_position
		var r := v.length()
		player.apply_central_force(v * GRAVITY * player.mass * planet.mass / (r ** 2.0))

	if get_ticks_sec() - player.last_fired_at >= 1.0 / PLAYER_FIRE_RATE:
		player.last_fired_at = get_ticks_sec()
		var bullet: Bullet = bullet_scene.instantiate()
		bullet.position = player.position
		var bullet_speed := 5000.0
		bullet.velocity = player.linear_velocity + player.transform.x * bullet_speed
		bullet.body_entered.connect(on_bullet_body_entered.bind(bullet))
		bullet.created_at = get_ticks_sec()
		bullet.source = Bullet.Source.PLAYER
		add_child(bullet)
		bullet.color_circle.color = Player.COLOR


func physics_process_planets(delta: float) -> void:
	for planet: Planet in get_tree().get_nodes_in_group("planets"):
		planet.rotation += delta * TAU / 100.0


func physics_process_bullets(delta: float) -> void:
	for bullet: Bullet in get_tree().get_nodes_in_group("bullets"):
		bullet.position += bullet.velocity * delta
		var lifetime := 3.0
		if get_ticks_sec() - bullet.created_at > lifetime:
			bullet.queue_free()


func physics_process_enemy(delta: float) -> void:
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.planet_theta += enemy.planet_speed * delta
		var last_position := enemy.position
		enemy.position = enemy.planet.position + Vector2.from_angle(enemy.planet_theta) * enemy.planet_r
		var velocity := (enemy.position - last_position) / delta

		if player.alive:
			enemy.rotation = enemy.position.angle_to_point(player.position)

			var fire_rate := 2.0
			if get_ticks_sec() - enemy.last_fired_at >= 1.0 / fire_rate:
				enemy.last_fired_at = get_ticks_sec()
				var bullet: Bullet = bullet_scene.instantiate()
				bullet.position = enemy.position
				var bullet_speed := 5000.0
				bullet.velocity = velocity + enemy.transform.x * bullet_speed
				bullet.body_entered.connect(on_bullet_body_entered.bind(bullet))
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


func get_ticks_sec() -> float:
	return Time.get_ticks_msec() / 1000.0


func on_bullet_body_entered(body: Node2D, bullet: Bullet) -> void:
	if body is Planet:
		bullet.queue_free()
	if bullet.source == Bullet.Source.PLAYER and body is Enemy:
		var enemy: Enemy = body
		enemy.queue_free()
		bullet.queue_free()

		var planet_has_enemy := false
		for enemy2: Enemy in get_tree().get_nodes_in_group("enemies"):
			if not enemy2.is_queued_for_deletion() and enemy2.planet == enemy.planet:
				planet_has_enemy = true
		if not planet_has_enemy:
			enemy.planet.color_circle.color = Player.COLOR

	if bullet.source == Bullet.Source.ENEMY and body is Player:
		player.health = maxf(player.health - 0.1, 0.0)
		if player.health == 0.0:
			player.alive = false
			player.process_mode = Node.PROCESS_MODE_DISABLED
		bullet.queue_free()
