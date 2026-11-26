extends Node2D

var ship: Node2D
var nearest_planet: Node2D

func _ready():
	z_index = 25 # Acima de tudo no jogo (exceto UI principal)

func _process(_delta):
	if not ship or not is_instance_valid(ship):
		ship = get_tree().get_first_node_in_group("ship")
	queue_redraw()

func _draw():
	if not ship or not is_instance_valid(ship):
		return
		
	# Encontrar planeta inexplorado mais próximo
	var planets = get_tree().get_nodes_in_group("planet")
	var portals = get_tree().get_nodes_in_group("portal")
	var min_dist = 999999.0
	nearest_planet = null
	
	for p in planets:
		if is_instance_valid(p) and not p.discovered:
			var d = ship.global_position.distance_to(p.global_position)
			if d < min_dist:
				min_dist = d
				nearest_planet = p
				
	# Se encontrar, desenhar o vetor de deslocamento até o planeta
	if portals.size() > 0 and is_instance_valid(portals[0]):
		nearest_planet = portals[0]

	if nearest_planet:
		var ship_pos = ship.global_position
		var planet_pos = nearest_planet.global_position
		var dir = (planet_pos - ship_pos).normalized()
		var dist = ship_pos.distance_to(planet_pos)

		draw_distance_vector(ship_pos, planet_pos, dist)
		
		# Exibir seta se estiver mais distante que o raio de renderização do planeta
		if dist > 350.0:
			# Posição da seta circulando a nave
			var arrow_radius = 85.0
			var arrow_pos = ship_pos + dir * arrow_radius
			var angle = dir.angle()
			
			draw_radar_arrow(arrow_pos, angle, dir)

func draw_radar_arrow(pos: Vector2, angle: float, dir: Vector2):
	var size = 12.0
	
	# Vértices da seta (aponta para a direita em 0 radianos)
	var p1 = Vector2(size * 1.5, 0).rotated(angle) + pos
	var p2 = Vector2(-size, -size * 0.8).rotated(angle) + pos
	var p3 = Vector2(-size, size * 0.8).rotated(angle) + pos
	var p4 = Vector2(-size * 0.5, 0).rotated(angle) + pos # Recesso interno da seta
	
	# Desenhar indicador com preenchimento sutil e contorno neon amarelo/ouro
	var points = PackedVector2Array([p1, p2, p4, p3])
	draw_colored_polygon(points, Color(1.0, 0.8, 0.2, 0.15))
	
	draw_line(p1, p2, Color(1.0, 0.85, 0.2, 0.9), 3.0, true)
	draw_line(p1, p3, Color(1.0, 0.85, 0.2, 0.9), 3.0, true)
	draw_line(p2, p4, Color(1.0, 0.85, 0.2, 0.9), 1.5, true)
	draw_line(p3, p4, Color(1.0, 0.85, 0.2, 0.9), 1.5, true)
	
	# Desenhar pequeno ponto flutuante de radar
	var dot_pos = ship.global_position + dir * 65.0
	draw_circle(dot_pos, 3.0, Color(1.0, 0.8, 0.2, 0.8))

func draw_distance_vector(ship_pos: Vector2, planet_pos: Vector2, dist_px: float):
	# Vetor completo (hipotenusa) ligando nave e planeta - linha tracejada ciano
	draw_dashed_line(ship_pos, planet_pos, Color(0.0, 0.9, 1.0, 0.4), 2.0, 14.0, true, true)

	# Decomposição em componentes (triângulo retângulo Δx / Δy) - Geometria Analítica
	var corner = Vector2(planet_pos.x, ship_pos.y)
	var dx = planet_pos.x - ship_pos.x
	var dy = planet_pos.y - ship_pos.y
	draw_dashed_line(ship_pos, corner, Color(1.0, 0.65, 0.0, 0.3), 1.5, 8.0, true, true)
	draw_dashed_line(corner, planet_pos, Color(1.0, 0.65, 0.0, 0.3), 1.5, 8.0, true, true)

	# Rótulo com a distância e a fórmula no ponto médio do vetor
	var mid = ship_pos.lerp(planet_pos, 0.5)
	var label_font = ThemeDB.fallback_font
	var dist_m = dist_px / 10.0

	draw_string(label_font, mid + Vector2(10, -10), "d = %.0f m" % dist_m, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.3, 1.0, 0.85, 0.95))
	draw_string(label_font, mid + Vector2(10, 8), "√(Δx² + Δy²) = √(%.0f² + %.0f²)" % [dx / 10.0, dy / 10.0], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.65, 0.85, 1.0, 0.8))

func set_target(_pos):
	pass

func clear_target():
	pass
