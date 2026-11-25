extends Area2D

# Tamanho do asteroide: 3 = Grande, 2 = Médio, 1 = Pequeno
# Se size for 0, escolheremos aleatoriamente no _ready.
var size = 0
var health = 30
var rotation_speed = 0.0
var velocity = Vector2.ZERO
var score_value = 10

func _ready():
	add_to_group("asteroid")
	z_index = 1
	
	# Determina tamanho caso não tenha sido predefinido (ex: spawn inicial)
	if size == 0:
		var r = randf()
		if r < 0.4:
			size = 3 # Grande (40%)
		elif r < 0.75:
			size = 2 # Médio (35%)
		else:
			size = 1 # Pequeno (25%)
			
	setup_size_properties()
	
	# Rotação aleatória
	rotation_speed = randf_range(-1.5, 1.5)
	
	# Direção aleatória caso a velocidade ainda não esteja definida
	if velocity == Vector2.ZERO:
		var angle = randf() * TAU
		var speed = randf_range(80, 140) if size == 3 else (randf_range(130, 200) if size == 2 else randf_range(200, 280))
		velocity = Vector2(cos(angle), sin(angle)) * speed
	
	# Conectar sinais de colisão
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func setup_size_properties():
	var s = 1.0
	match size:
		3: # Grande
			health = 90
			s = 1.6
			score_value = 30
		2: # Médio
			health = 60
			s = 0.95
			score_value = 20
		1: # Pequeno
			health = 30
			s = 0.5
			score_value = 10
			
	scale = Vector2(s, s)

func _physics_process(delta):
	position += velocity * delta
	rotation += rotation_speed * delta
	
	# Se afastar demais do jogador, remover para liberar memória
	var player = get_tree().get_first_node_in_group("ship")
	if player:
		if global_position.distance_to(player.global_position) > 1600:
			queue_free()

func _on_area_entered(area):
	if area.is_in_group("bullet"):
		# Bullets dão dano dinamicamente
		var damage_amount = 30
		if "damage" in area:
			damage_amount = area.damage
		take_damage(damage_amount)

func _on_body_entered(body):
	if body.is_in_group("ship") or body.name == "Ship":
		if body.has_method("take_damage"):
			body.take_damage(1)
			# Empurrar o asteroide na direção oposta ao impacto
			var dir = (global_position - body.global_position).normalized()
			velocity = dir * velocity.length() * 1.2
		elif body.has_method("die"):
			body.die()

func take_damage(amount: int):
	health -= amount
	
	if health <= 0:
		explode()
		return
		
	# Flash vermelho de impacto (somente se ainda estiver vivo)
	modulate = Color(1.0, 0.3, 0.3, 1.0)
	var timer = get_tree().create_timer(0.08)
	timer.timeout.connect(func():
		if is_instance_valid(self):
			modulate = Color.WHITE
	)
	
	# Mini faíscas de pedras ao ser atingido
	spawn_hit_particles()

func spawn_hit_particles():
	var parent = get_parent()
	if not parent:
		return
	
	var sparks = CPUParticles2D.new()
	parent.add_child(sparks)
	sparks.global_position = global_position
	sparks.amount = 5
	sparks.lifetime = 0.2
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.spread = 45.0
	sparks.direction = -velocity.normalized()
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = 80.0
	sparks.initial_velocity_max = 160.0
	sparks.scale_amount_min = 1.5
	sparks.scale_amount_max = 3.5
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.7, 0.7, 0.7, 0.8))
	gradient.set_color(1, Color(0.3, 0.3, 0.3, 0.0))
	sparks.color_ramp = gradient
	
	sparks.emitting = true
	await get_tree().create_timer(0.25).timeout
	if is_instance_valid(sparks):
		sparks.queue_free()

func explode():
	# Incrementar score do jogador e tocar som de explosão no Main
	get_tree().call_group("main", "on_asteroid_destroyed", global_position, score_value)
	
	# Partículas de explosão de detritos
	spawn_explosion_particles()
	
	# Mecânica de divisão
	if size > 1:
		for i in range(2):
			var new_ast = load("res://scenes/asteroid.tscn").instantiate()
			new_ast.size = size - 1
			new_ast.global_position = global_position
			
			# Direções de velocidade divergentes (+/- 40 graus em relação à original)
			var base_angle = velocity.angle()
			var dev_angle = base_angle + (PI / 4.5) * (-1 if i == 0 else 1)
			
			# Velocidade ligeiramente maior para os menores
			var current_speed = velocity.length()
			var new_speed = current_speed * 1.35
			new_ast.velocity = Vector2(cos(dev_angle), sin(dev_angle)) * new_speed
			new_ast.rotation_speed = randf_range(-3.0, 3.0)
			
			get_parent().call_deferred("add_child", new_ast)
			
	queue_free()

func spawn_explosion_particles():
	var parent = get_parent()
	if not parent:
		return
		
	var debris = CPUParticles2D.new()
	parent.add_child(debris)
	debris.global_position = global_position
	debris.amount = size * 10
	debris.lifetime = 0.45
	debris.one_shot = true
	debris.explosiveness = 1.0
	debris.spread = 180.0
	debris.gravity = Vector2.ZERO
	debris.initial_velocity_min = 100.0
	debris.initial_velocity_max = 240.0
	debris.scale_amount_min = 2.0
	debris.scale_amount_max = 6.5
	
	# Gradiente do cinza rochoso para transparente escuro
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.65, 0.6, 0.55, 1.0))
	gradient.set_color(1, Color(0.2, 0.2, 0.25, 0.0))
	gradient.add_point(0.4, Color(0.45, 0.42, 0.4, 0.9))
	debris.color_ramp = gradient
	
	debris.emitting = true
	await get_tree().create_timer(0.55).timeout
	if is_instance_valid(debris):
		debris.queue_free()
