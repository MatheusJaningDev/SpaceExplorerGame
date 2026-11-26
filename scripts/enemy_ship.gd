extends Area2D

var max_speed = 150.0
var accel = 300.0
var turn_speed = 2.0
var health = 40
var score_value = 25
var shoot_cooldown = 3.5
var shoot_range = 650.0
var shoot_timer = 0.0
var velocity = Vector2.ZERO
var bullet_scene = preload("res://scenes/enemy_bullet.tscn")

func _ready():
	add_to_group("enemy_ship")
	z_index = 4
	shoot_timer = randf_range(1.5, shoot_cooldown)

	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 38.0
	col.shape = circle
	add_child(col)

	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate = Color(1.0, 0.4, 0.4, 1.0)

	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	var player = get_tree().get_first_node_in_group("ship")

	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		var target_angle = dir.angle() + PI / 2
		rotation = lerp_angle(rotation, target_angle, turn_speed * delta)
		velocity = velocity.move_toward(dir * max_speed, accel * delta)

		var dist = global_position.distance_to(player.global_position)
		shoot_timer -= delta
		if shoot_timer <= 0.0 and dist < shoot_range:
			shoot_at(player)
			shoot_timer = shoot_cooldown

		if dist > 2200.0:
			queue_free()
			return

	position += velocity * delta

func shoot_at(player):
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	var dir = (player.global_position - global_position).normalized()
	bullet.global_position = global_position + dir * 40
	bullet.set_direction(dir)

func _on_area_entered(area):
	if area.is_in_group("bullet"):
		var damage_amount = 30
		if "damage" in area:
			damage_amount = area.damage
		take_damage(damage_amount)

func _on_body_entered(body):
	if body.is_in_group("ship") or body.name == "Ship":
		if body.has_method("take_damage"):
			body.take_damage(1)
		explode()

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		explode()
		return

	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		var timer = get_tree().create_timer(0.08)
		timer.timeout.connect(func():
			if is_instance_valid(self) and sprite:
				sprite.modulate = Color(1.0, 0.4, 0.4, 1.0)
		)

func explode():
	get_tree().call_group("main", "on_enemy_destroyed", global_position, score_value)
	queue_free()
