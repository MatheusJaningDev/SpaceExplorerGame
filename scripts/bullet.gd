extends Area2D

var speed = 1000  # Aumentado um pouco para dar mais dinamismo
var direction = Vector2.RIGHT
var damage = 30
var lifetime = 2.0

var trail_particles: CPUParticles2D

func _ready():
	add_to_group("bullet")
	area_entered.connect(_on_area_entered)
	z_index = 5
	
	# Ajustar ColorRect para parecer uma linha laser alongada
	var color_rect = get_node_or_null("Sprite2D/ColorRect")
	if color_rect:
		color_rect.size = Vector2(30, 4)
		color_rect.position = Vector2(-15, -2)
		color_rect.color = Color(0.0, 1.0, 1.0, 1.0)
	
	# Setup de partículas de rastro
	setup_trail()
	
	# Destruir após tempo limite
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func setup_trail():
	trail_particles = CPUParticles2D.new()
	add_child(trail_particles)
	trail_particles.amount = 15
	trail_particles.lifetime = 0.15
	# Aponta na direção oposta do movimento
	trail_particles.direction = -direction
	trail_particles.spread = 2.0
	trail_particles.gravity = Vector2.ZERO
	trail_particles.initial_velocity_min = 100.0
	trail_particles.initial_velocity_max = 200.0
	trail_particles.scale_amount_min = 2.0
	trail_particles.scale_amount_max = 4.0
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.0, 1.0, 1.0, 0.9)) # Ciano brilhante
	gradient.set_color(1, Color(0.0, 0.3, 0.9, 0.0)) # Azul transparente
	trail_particles.color_ramp = gradient
	trail_particles.emitting = true
	trail_particles.show_behind_parent = true

func _physics_process(delta):
	position += direction * speed * delta

func _on_area_entered(area):
	if area.is_in_group("asteroid"):
		area.take_damage(damage)
		create_impact_effect()
		queue_free()
	elif area.is_in_group("planet"):
		# Não causa dano a planetas, apenas interage
		if area.has_method("interact"):
			area.interact()
		create_impact_effect()
		queue_free()

func set_direction(dir: Vector2):
	direction = dir.normalized()
	rotation = direction.angle()
	if trail_particles:
		trail_particles.direction = -direction

func create_impact_effect():
	var parent = get_parent()
	if not parent:
		return
		
	# Efeito visual de faísca
	var impact = CPUParticles2D.new()
	parent.add_child(impact)
	impact.global_position = global_position
	impact.amount = 15
	impact.lifetime = 0.25
	impact.one_shot = true
	impact.explosiveness = 1.0
	impact.spread = 180.0
	impact.gravity = Vector2.ZERO
	impact.initial_velocity_min = 150.0
	impact.initial_velocity_max = 250.0
	impact.scale_amount_min = 2.5
	impact.scale_amount_max = 5.0
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.0, 1.0, 1.0, 1.0)) # Ciano
	gradient.set_color(1, Color(0.5, 0.0, 0.5, 0.0)) # Roxo transparente
	gradient.add_point(0.6, Color(0.0, 0.4, 1.0, 0.8)) # Azul
	impact.color_ramp = gradient
	
	impact.emitting = true
	
	# Auto destruição do emissor de impacto
	await get_tree().create_timer(0.35).timeout
	if is_instance_valid(impact):
		impact.queue_free()
