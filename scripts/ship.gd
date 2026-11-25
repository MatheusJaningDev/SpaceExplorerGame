extends CharacterBody2D

# Configurações de movimento
var max_speed = 500
var acceleration = 1200
var friction = 600
var rotation_speed = 10.0

# Sistema de escudos/vida
var max_shield = 3
var shield = 3
var is_invulnerable = false
var invulnerability_duration = 1.5
var shield_visible_timer = 0.0

# Tiro
var bullet_scene = preload("res://scenes/bullet.tscn")
var can_shoot = true
var shoot_cooldown = 0.2

# Efeitos sonoros
@onready var laser_sound = AudioStreamPlayer2D.new()
@onready var hit_sound = AudioStreamPlayer2D.new()
@onready var engine_sound = AudioStreamPlayer2D.new()

# Partículas de motor
var engine_particles: CPUParticles2D

func _ready():
	add_to_group("ship")
	z_index = 10
	
	# Setup de áudio
	laser_sound.stream = preload("res://assets/sounds/laser.wav")
	hit_sound.stream = preload("res://assets/sounds/hit.wav")
	engine_sound.stream = preload("res://assets/sounds/engine.wav")
	add_child(laser_sound)
	add_child(hit_sound)
	add_child(engine_sound)
	
	# Configurar som do motor em loop
	if engine_sound.stream:
		engine_sound.finished.connect(func():
			if is_instance_valid(self) and velocity.length() > 20:
				engine_sound.play()
		)
	
	# Setup de partículas do motor
	setup_particles()

func setup_particles():
	engine_particles = CPUParticles2D.new()
	add_child(engine_particles)
	engine_particles.position = Vector2(0, 35) # Atrás da nave
	engine_particles.amount = 50
	engine_particles.lifetime = 0.4
	engine_particles.direction = Vector2(0, 1) # Aponta para baixo
	engine_particles.spread = 20.0
	engine_particles.gravity = Vector2.ZERO
	engine_particles.initial_velocity_min = 150.0
	engine_particles.initial_velocity_max = 250.0
	engine_particles.scale_amount_min = 3.0
	engine_particles.scale_amount_max = 7.0
	
	# Gradiente de cor: Amarelo-fogo -> Laranja -> Roxo -> Transparente
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 0.9, 0.3, 1.0))
	gradient.set_color(1, Color(0.3, 0.0, 0.3, 0.0))
	gradient.add_point(0.4, Color(1.0, 0.4, 0.0, 0.8))
	gradient.add_point(0.8, Color(0.6, 0.0, 0.6, 0.3))
	engine_particles.color_ramp = gradient
	engine_particles.show_behind_parent = true
	engine_particles.emitting = true

func _process(delta):
	# Diminuir timer de visibilidade do escudo
	if shield_visible_timer > 0.0:
		shield_visible_timer -= delta
		queue_redraw()
	
	# Piscar quando invulnerável
	if is_invulnerable:
		modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.05)
	else:
		modulate.a = 1.0

func _physics_process(delta):
	# Controles WASD
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	# Física de movimento com inércia
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * max_speed, acceleration * delta)
		var target_angle = input_vector.angle() + PI/2
		rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)
		
		# Feedback visual de motor
		engine_particles.emitting = true
		engine_particles.initial_velocity_min = 180.0
		engine_particles.scale_amount_max = 8.0
		
		# Som do motor
		if not engine_sound.playing:
			engine_sound.play()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		engine_particles.initial_velocity_min = 50.0
		engine_particles.scale_amount_max = 4.0
		# Se a nave parar, silencia o motor lentamente
		if velocity.length() < 50 and engine_sound.playing:
			engine_sound.stop()
	# Aplicar gravidade orbital suave ao redor de planetas não descobertos para ajudar no escaneamento
	var gravity_pull = Vector2.ZERO
	var planets = get_tree().get_nodes_in_group("planet")
	for p in planets:
		if is_instance_valid(p) and not p.discovered:
			var diff = p.global_position - global_position
			var dist = diff.length()
			var scan_range = 250.0 # Raio de órbita e escaneamento
			if dist < scan_range:
				# A força de atração aumenta à medida que nos aproximamos do centro
				var force_factor = 1.0 - (dist / scan_range)
				# Puxar a nave com força progressiva (máximo 450 pixels/s²)
				gravity_pull += diff.normalized() * (450.0 * force_factor)
	
	velocity += gravity_pull * delta
	
	move_and_slide()
	
	# Atirar com Espaço
	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
		shoot()

	# Verificar colisões físicas (CharacterBody2D)
	check_collisions()

func shoot():
	if not can_shoot:
		return
		
	can_shoot = false
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	
	# Bala sai da frente da nave
	var direction = Vector2.UP.rotated(rotation)
	bullet.global_position = global_position + direction * 45
	bullet.set_direction(direction)
	
	# Som do laser
	laser_sound.play()
	
	# Efeito de coice/screenshake menor
	get_tree().call_group("main", "shake_camera", 3.0, 0.1)
	
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func check_collisions():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("asteroid"):
			take_damage(1)

func take_damage(amount: int):
	if is_invulnerable:
		return
		
	shield -= amount
	shield_visible_timer = 1.2 # Exibe o escudo por 1.2 segundos
	queue_redraw()
	
	# Som de impacto
	hit_sound.play()
	
	# Tremer câmera
	get_tree().call_group("main", "shake_camera", 15.0, 0.3)
	
	# Atualizar a UI
	get_tree().call_group("main", "update_hud_shield", shield, max_shield)
	
	if shield <= 0:
		die()
	else:
		start_invulnerability()

func start_invulnerability():
	is_invulnerable = true
	await get_tree().create_timer(invulnerability_duration).timeout
	if is_instance_valid(self):
		is_invulnerable = false
		modulate.a = 1.0

func die():
	print("Nave destruída!")
	set_physics_process(false)
	set_process(false)
	engine_particles.emitting = false
	
	# Som de explosão tocado no Main
	get_tree().call_group("main", "on_ship_destroyed", global_position)
	
	# Efeito visual de explosão na nave (escala para zero)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.4)
	tween.tween_callback(queue_free)

func _draw():
	if shield > 0 and shield_visible_timer > 0.0:
		var alpha = clamp(shield_visible_timer, 0.0, 1.0)
		# Desenha círculos concêntricos azul-neon para o escudo
		draw_arc(Vector2.ZERO, 55.0, 0, TAU, 36, Color(0.0, 0.7, 1.0, alpha * 0.5), 2.5)
		draw_arc(Vector2.ZERO, 52.0, 0, TAU, 36, Color(0.0, 0.4, 1.0, alpha * 0.25), 5.0)

func _on_area_entered(area):
	if area.is_in_group("asteroid"):
		take_damage(1)
