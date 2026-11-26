extends Area2D

var power_type = "shield" # shield, triple_shot, speed
var lifetime = 10.0
var bob_timer = 0.0

func _ready():
	add_to_group("powerup")
	z_index = 3

	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 22.0
	col.shape = circle
	add_child(col)

	body_entered.connect(_on_body_entered)

	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		fade_and_remove()

func _process(delta):
	bob_timer += delta
	rotation += delta * 1.2
	queue_redraw()

func _on_body_entered(body):
	if body.is_in_group("ship") or body.name == "Ship":
		if body.has_method("apply_power_up"):
			body.apply_power_up(power_type)
		get_tree().call_group("main", "on_powerup_collected")
		queue_free()

func fade_and_remove():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_callback(queue_free)

func get_color() -> Color:
	match power_type:
		"shield":
			return Color(0.0, 0.8, 1.0, 1.0)
		"triple_shot":
			return Color(1.0, 0.3, 0.3, 1.0)
		"speed":
			return Color(1.0, 0.85, 0.2, 1.0)
	return Color.WHITE

func _draw():
	var c = get_color()

	var pts = PackedVector2Array([Vector2(0, -16), Vector2(16, 0), Vector2(0, 16), Vector2(-16, 0)])
	draw_colored_polygon(pts, Color(c.r, c.g, c.b, 0.35))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), c, 2.5, true)
	draw_circle(Vector2.ZERO, 4.0, c)

	var pulse = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
	draw_arc(Vector2.ZERO, 20.0, 0, TAU, 24, Color(c.r, c.g, c.b, 0.2 * pulse), 2.0)
