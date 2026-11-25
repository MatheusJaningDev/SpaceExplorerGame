extends Node2D

var grid_size = 1000.0
var font: Font

func _ready():
	z_index = -5 # Atrás da nave e asteroides, mas na frente do background
	font = load("res://assets/fonts/pixel_font.ttf")

func _process(_delta):
	# Precisamos forçar o redesenho constante porque a câmera se move
	queue_redraw()

func _draw():
	var cam = get_viewport().get_camera_2d()
	if not cam:
		return
		
	var viewport_rect = get_viewport_rect()
	var cam_pos = cam.global_position
	var zoom = cam.zoom
	
	# Calcular os limites do mundo que estão visíveis na tela
	var visible_size = viewport_rect.size / zoom
	var top_left = cam_pos - visible_size / 2.0
	var bottom_right = cam_pos + visible_size / 2.0
	
	# Encontrar as coordenadas de grade inicial e final que cruzam o viewport
	var start_x = floor(top_left.x / grid_size) * grid_size
	var end_x = ceil(bottom_right.x / grid_size) * grid_size
	var start_y = floor(top_left.y / grid_size) * grid_size
	var end_y = ceil(bottom_right.y / grid_size) * grid_size
	
	var grid_color = Color(0.0, 0.4, 0.8, 0.07) # Azul ciano neon muito suave
	var axis_color = Color(0.0, 0.8, 1.0, 0.15)  # Eixo principal (0) ligeiramente mais destacado
	
	# Desenhar linhas verticais
	var x = start_x
	while x <= end_x:
		var col = axis_color if abs(x) < 1.0 else grid_color
		draw_line(Vector2(x, top_left.y), Vector2(x, bottom_right.y), col, 1.0)
		x += grid_size
		
	# Desenhar linhas horizontais
	var y = start_y
	while y <= end_y:
		var col = axis_color if abs(y) < 1.0 else grid_color
		draw_line(Vector2(top_left.x, y), Vector2(bottom_right.x, y), col, 1.0)
		y += grid_size

	# Desenhar rótulos de coordenadas nas interseções
	if font:
		x = start_x
		while x <= end_x:
			y = start_y
			while y <= end_y:
				# Evitar acumular texto nas bordas se tiver muito fora
				var label = "[%d, %d]" % [x, y]
				draw_string(font, Vector2(x + 10, y - 10), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.0, 0.6, 1.0, 0.25))
				y += grid_size
			x += grid_size
