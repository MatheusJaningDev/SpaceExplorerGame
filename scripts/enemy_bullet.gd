extends Area2D

var speed = 260.0
var direction = Vector2.RIGHT
var damage = 1
var lifetime = 4.0

func _ready():
	add_to_group("enemy_bullet")
	z_index = 4

	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 6.0
	col.shape = circle
	add_child(col)

	body_entered.connect(_on_body_entered)

	var color_rect = get_node_or_null("Sprite2D/ColorRect")
	if color_rect:
		color_rect.size = Vector2(22, 4)
		color_rect.position = Vector2(-11, -2)
		color_rect.color = Color(1.0, 0.3, 0.2, 1.0)

	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta):
	position += direction * speed * delta

func set_direction(dir: Vector2):
	direction = dir.normalized()
	rotation = direction.angle()

func _on_body_entered(body):
	if body.is_in_group("ship") or body.name == "Ship":
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
