extends Area2D

var pulse_timer = 0.0

func _ready():
	add_to_group("portal")
	z_index = -1

	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 55.0
	col.shape = circle
	add_child(col)

	body_entered.connect(_on_body_entered)

func _process(delta):
	pulse_timer += delta
	rotation += delta * 0.6
	queue_redraw()

func _on_body_entered(body):
	if body.is_in_group("ship") or body.name == "Ship":
		get_tree().call_group("main", "on_portal_entered")
		queue_free()

func _draw():
	var pulse = 0.6 + 0.4 * sin(pulse_timer * 2.0)
	var base_color = Color(0.6, 0.2, 1.0, 0.9)
	var glow_color = Color(0.2, 0.9, 1.0, 0.5)

	for i in range(3):
		var r = 60.0 + i * 16.0
		draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(base_color.r, base_color.g, base_color.b, (0.35 - i * 0.1) * pulse), 3.0, true)

	draw_arc(Vector2.ZERO, 50.0, 0, TAU, 48, glow_color, 5.0 * pulse, true)
	draw_circle(Vector2.ZERO, 20.0 * pulse, Color(1.0, 1.0, 1.0, 0.25))

	var num = 8
	for idx in range(num):
		var t = fmod((pulse_timer * 0.8) + float(idx) / num, 1.0)
		var ang = t * TAU
		var r2 = lerp(65.0, 15.0, t)
		var ppos = Vector2(cos(ang), sin(ang)) * r2
		draw_circle(ppos, 3.0, Color(1.0, 1.0, 1.0, 1.0 - t))
