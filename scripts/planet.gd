extends Area2D

var rotation_speed = 0.15
var discovered = false
var planet_type = 0  # 0 = blue, 1 = orange

# Proximidade e Escaneamento
var scan_zone: Area2D
var is_scanning = false
var scan_progress = 0.0
var scan_duration = 1.6 # Segundos próximos para escanear
var player_in_range = false

# Efeito Sonar e Ping
var ping_timer = 0.0
var ping_interval = 2.5
var active_pings = [] # Array de dicionários contendo {radius, max_radius, speed}

func _ready():
	add_to_group("planet")
	z_index = -1 # Atrás da nave
	planet_type = randi() % 2
	
	# Criar área circular de detecção de proximidade para escaneamento
	setup_scan_zone()

func setup_scan_zone():
	scan_zone = Area2D.new()
	add_child(scan_zone)
	
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 250.0 # Alcance do radar de escaneamento ampliado para órbita gravitacional
	col.shape = circle
	scan_zone.add_child(col)
	
	# Configurar máscaras de colisão (detecta apenas corpos na camada do jogador)
	scan_zone.collision_layer = 0
	scan_zone.collision_mask = 1 # Geralmente a camada padrão 1
	
	# Conectar sinais
	scan_zone.body_entered.connect(_on_player_entered)
	scan_zone.body_exited.connect(_on_player_exited)
func _process(delta):
	# Rotacionar planeta lentamente
	rotation += rotation_speed * delta
	
	# Atualizar o escaneamento
	if is_scanning and not discovered:
		scan_progress += delta
		queue_redraw()
		
		if scan_progress >= scan_duration:
			discover_planet()
			
	# Atualizar sonar de pings se ainda não descoberto
	if not discovered:
		ping_timer += delta
		if ping_timer >= ping_interval:
			ping_timer = 0.0
			active_pings.append({
				"radius": 50.0,
				"max_radius": 400.0,
				"speed": 160.0
			})
			
		# Atualizar pings
		var i = active_pings.size() - 1
		while i >= 0:
			var ping = active_pings[i]
			ping.radius += ping.speed * delta
			if ping.radius >= ping.max_radius:
				active_pings.remove_at(i)
			i -= 1
			
		queue_redraw()

func _on_player_entered(body):
	if (body.is_in_group("ship") or body.name == "Ship") and not discovered:
		player_in_range = true
		is_scanning = true

func _on_player_exited(body):
	if body.is_in_group("ship") or body.name == "Ship":
		player_in_range = false
		is_scanning = false
		scan_progress = 0.0
		queue_redraw()

func discover_planet():
	discovered = true
	is_scanning = false
	scan_progress = 0.0
	active_pings.clear()
	
	# Animação de descoberta: pulsação visual e cor dourada/brilhante
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate", Color(1.3, 1.2, 0.4, 1.0), 0.3)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.3) # Começa com 0.8 em main, cresce
	
	var tween_back = create_tween()
	tween_back.tween_interval(0.3)
	tween_back.tween_property(self, "scale", Vector2(0.8, 0.8), 0.2)
	
	# Notifica gerenciador principal (pontuação, som, etc)
	get_tree().call_group("main", "on_planet_discovered", global_position)
	queue_redraw()

func interact():
	# Compatibilidade com tiro (se atirar descobre imediatamente)
	if not discovered:
		discover_planet()

func get_position_info() -> String:
	var status = "descoberto" if discovered else "não descoberto"
	return "Planeta em (%.0f, %.0f) - %s" % [global_position.x, global_position.y, status]

func _draw():
	# Desenhar pings de sonar para planetas inexplorados
	if not discovered:
		for ping in active_pings:
			var ratio = ping.radius / ping.max_radius
			var alpha = (1.0 - ratio) * 0.22
			var ping_color = Color(0.0, 0.7, 1.0, alpha)
			draw_arc(Vector2.ZERO, ping.radius, 0, TAU, 32, ping_color, 2.0, true)
			
	# Desenhar anel circular de progresso se estiver escaneando
	if is_scanning and not discovered:
		var radius = 235.0 # Raio da barra circular
		var angle_end = (scan_progress / scan_duration) * TAU - PI/2
		
		# Arco de progresso neon verde-limão
		draw_arc(Vector2.ZERO, radius, -PI/2, angle_end, 36, Color(0.0, 1.0, 0.5, 0.9), 5.0, true)
		# Fundo do arco
		draw_arc(Vector2.ZERO, radius, -PI/2, 3.0 * PI / 2, 36, Color(1.0, 1.0, 1.0, 0.1), 3.0, true)
		
		# Desenhar feixe de energia conectando a nave
		var ship = get_tree().get_first_node_in_group("ship")
		if ship and is_instance_valid(ship):
			var local_ship_pos = to_local(ship.global_position)
			
			# Feixe laser verde neon com pulsação
			var pulse = 0.75 + 0.25 * sin(Time.get_ticks_msec() * 0.02)
			var beam_color = Color(0.0, 1.0, 0.5, 0.45 * pulse)
			draw_line(Vector2.ZERO, local_ship_pos, beam_color, 4.0 * pulse, true)
			draw_line(Vector2.ZERO, local_ship_pos, Color(0.85, 1.0, 0.95, 0.75 * pulse), 1.5, true)
			
			# Partículas de dados subindo o feixe
			var time_sec = Time.get_ticks_msec() / 1000.0
			var num_particles = 4
			for idx in range(num_particles):
				var t = fmod((time_sec * 1.5) + (float(idx) / num_particles), 1.0)
				var part_pos = local_ship_pos * t
				draw_rect(Rect2(part_pos - Vector2(3, 3), Vector2(6, 6)), Color(0.0, 1.0, 0.5, 0.8))
				draw_rect(Rect2(part_pos - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 1.0, 1.0, 1.0))
		
	# Desenhar anéis estéticos ao redor de planetas já descobertos
	if discovered:
		# Anéis orbitais dourados/azulados translúcidos
		draw_arc(Vector2.ZERO, 200.0, 0, TAU, 48, Color(1.0, 0.8, 0.2, 0.25), 1.5)
		draw_arc(Vector2.ZERO, 230.0, 0, TAU, 48, Color(0.1, 0.6, 1.0, 0.15), 1.0)
