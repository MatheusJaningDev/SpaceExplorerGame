extends Node2D

@onready var ship = $Ship

# Cenas e assets
var asteroid_scene = preload("res://scenes/asteroid.tscn")
var planet_scene = preload("res://scenes/planet.tscn")
var planet_large_1 = load("res://assets/sprites/planet_large_1.png")
var planet_large_2 = load("res://assets/sprites/planet_large_2.png")

# Estados do jogo
enum State { MENU, PLAYING, GAMEOVER, PAUSED }
var game_state = State.MENU

# Static para persistir decisão de skip ao reiniciar
static var skip_menu_next_load = false

# Dados de jogo
var score = 0
var asteroids_destroyed = 0
var planets_discovered = 0
var total_planets = 5
var spawn_timer = 0.0
var spawn_interval = 1.3  # Spawn ligeiramente mais dinâmico

# Câmera e screenshake
var camera: Camera2D
var shake_intensity = 0.0
var shake_duration = 0.0

# Nós de interface criados programaticamente
var menu_container: Control
var hud_container: Control
var pause_container: Control
var gameover_container: Control
var tutorial_container: Control
var tutorial_return_state = State.MENU
var grid_node: Node2D

# Componentes HUD
var hud_score_label: Label
var hud_planets_label: Label
var hud_shield_bar: ProgressBar
var hud_coord_label: Label
var game_over_title: Label
var stats_detail_label: Label
var hud_target_name_label: Label
var hud_target_coord_label: Label
var hud_target_dist_label: Label
var hud_target_bearing_label: Label
var hud_planets_list_label: Label

# Reprodutores de Áudio
@onready var sfx_explosion = AudioStreamPlayer.new()
@onready var sfx_collect = AudioStreamPlayer.new()
@onready var sfx_hit = AudioStreamPlayer.new()
@onready var music_player = AudioStreamPlayer.new()

func _ready():
	add_to_group("main")
	randomize()
	
	# Configurar modo de processamento (permite que Main rode mesmo pausado)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Setup de áudio local
	setup_audio()
	
	# Setup da câmera inteligente
	setup_camera()
	
	# Spawn dos corpos celestes
	spawn_initial_planets()
	
	# Adicionar a grade de coordenadas no mundo
	var world_grid_script = load("res://scripts/world_grid.gd")
	grid_node = world_grid_script.new()
	add_child(grid_node)
	
	# Criação da UI programática estilizada
	setup_ui()
	
	# Controle do fluxo inicial (Menu ou Gameplay Direto no Restart)
	if skip_menu_next_load:
		skip_menu_next_load = false
		start_game()
	else:
		enter_menu_state()

func setup_audio():
	sfx_explosion.stream = preload("res://assets/sounds/explosion.wav")
	sfx_collect.stream = preload("res://assets/sounds/collect.wav")
	sfx_hit.stream = preload("res://assets/sounds/hit.wav")
	music_player.stream = preload("res://assets/sounds/music.wav")
	
	# Ajustes de volume
	sfx_explosion.volume_db = -2.0
	sfx_collect.volume_db = -2.0
	sfx_hit.volume_db = -3.0
	music_player.volume_db = -8.0
	
	add_child(sfx_explosion)
	add_child(sfx_collect)
	add_child(sfx_hit)
	add_child(music_player)
	
	# Fazer música tocar em loop infinito
	music_player.finished.connect(func(): if game_state == State.PLAYING or game_state == State.PAUSED: music_player.play())
	
	# Começar trilha ambiente de fundo
	music_player.play()

func setup_camera():
	camera = Camera2D.new()
	add_child(camera)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.make_current()
	if ship:
		camera.global_position = ship.global_position
		
	# Setup de partículas de poeira estelar (Space Dust) para percepção de velocidade
	var dust = CPUParticles2D.new()
	camera.add_child(dust)
	dust.z_index = -4
	dust.amount = 180
	dust.lifetime = 4.0
	dust.preprocess = 4.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(900, 600)
	dust.gravity = Vector2.ZERO
	dust.direction = Vector2.ZERO
	dust.spread = 0.0
	dust.local_coords = false # Faz com que as partículas fiquem fixas no mundo enquanto a câmera se move
	dust.scale_amount_min = 1.0
	dust.scale_amount_max = 2.5
	dust.color = Color(0.8, 0.9, 1.0, 0.35) # Azul espacial translúcido

func setup_ui():
	# Limpar labels de legado da cena padrão
	var old_coord = get_node_or_null("UI/CoordinateLabel")
	var old_score = get_node_or_null("UI/ScoreLabel")
	if old_coord: old_coord.queue_free()
	if old_score: old_score.queue_free()
	
	var ui_layer = $UI
	
	# ---------------- MENU PRINCIPAL ----------------
	menu_container = Control.new()
	menu_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(menu_container)
	
	# Overlay escuro futurista
	var menu_bg = ColorRect.new()
	menu_bg.color = Color(0.02, 0.02, 0.06, 0.88)
	menu_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_container.add_child(menu_bg)
	
	var menu_center = CenterContainer.new()
	menu_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_container.add_child(menu_center)
	
	var menu_vbox = VBoxContainer.new()
	menu_vbox.add_theme_constant_override("separation", 20)
	menu_center.add_child(menu_vbox)
	
	var title = Label.new()
	title.text = "SPACE EXPLORER"
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0, 1.0)) # Ciano Neon
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "N3 visual prototype // vertical slice"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.5, 0.7, 0.8))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_vbox.add_child(subtitle)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	menu_vbox.add_child(spacer)
	
	var play_btn = Button.new()
	play_btn.text = "INICIAR JOGO"
	play_btn.custom_minimum_size = Vector2(260, 50)
	play_btn.add_theme_font_size_override("font_size", 18)
	play_btn.add_theme_color_override("font_color", Color(0.0, 1.0, 0.5))
	play_btn.pressed.connect(start_game)
	menu_vbox.add_child(play_btn)
	
	var tutorial_menu_btn = Button.new()
	tutorial_menu_btn.text = "COMO JOGAR"
	tutorial_menu_btn.custom_minimum_size = Vector2(260, 45)
	tutorial_menu_btn.pressed.connect(show_tutorial)
	menu_vbox.add_child(tutorial_menu_btn)
	
	var quit_btn = Button.new()
	quit_btn.text = "SAIR"
	quit_btn.custom_minimum_size = Vector2(260, 45)
	quit_btn.add_theme_font_size_override("font_size", 16)
	quit_btn.pressed.connect(func(): get_tree().quit())
	menu_vbox.add_child(quit_btn)
	
	var instr = Label.new()
	instr.text = "Controles:\nWASD ou Setas para Mover\nEspaço para Disparar Laser\n\nObjetivo: Aproxime-se dos planetas para fazer escaneamento\ne destruir os asteroides hostis."
	instr.add_theme_font_size_override("font_size", 13)
	instr.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	instr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_vbox.add_child(instr)
	
	# ---------------- HUD DINÂMICO ----------------
	hud_container = Control.new()
	hud_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(hud_container)
	
	# Margem do topo para status
	var margin_top = MarginContainer.new()
	margin_top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin_top.add_theme_constant_override("margin_left", 20)
	margin_top.add_theme_constant_override("margin_top", 20)
	margin_top.add_theme_constant_override("margin_right", 20)
	hud_container.add_child(margin_top)
	
	var top_hbox = HBoxContainer.new()
	margin_top.add_child(top_hbox)
	
	# Escudos
	var shield_vbox = VBoxContainer.new()
	top_hbox.add_child(shield_vbox)
	
	var shield_lbl = Label.new()
	shield_lbl.text = "ESCUDOS DEFLETORES"
	shield_lbl.add_theme_font_size_override("font_size", 12)
	shield_lbl.add_theme_color_override("font_color", Color(0.0, 0.8, 1.0))
	shield_vbox.add_child(shield_lbl)
	
	hud_shield_bar = ProgressBar.new()
	hud_shield_bar.max_value = 3
	hud_shield_bar.value = 3
	hud_shield_bar.show_percentage = false
	hud_shield_bar.custom_minimum_size = Vector2(200, 16)
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.05, 0.05, 0.1, 0.6)
	sb_bg.border_width_left = 1
	sb_bg.border_width_top = 1
	sb_bg.border_width_right = 1
	sb_bg.border_width_bottom = 1
	sb_bg.border_color = Color(0.0, 0.5, 0.8, 0.4)
	
	var sb_fill = StyleBoxFlat.new()
	sb_fill.bg_color = Color(0.0, 0.85, 1.0, 0.95)
	sb_fill.shadow_color = Color(0.0, 0.85, 1.0, 0.35)
	sb_fill.shadow_size = 6
	
	hud_shield_bar.add_theme_stylebox_override("background", sb_bg)
	hud_shield_bar.add_theme_stylebox_override("fill", sb_fill)
	shield_vbox.add_child(hud_shield_bar)
	
	# Espaçador
	var top_spacer = Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(top_spacer)
	
	var tutorial_hud_btn = Button.new()
	tutorial_hud_btn.text = "COMO JOGAR"
	tutorial_hud_btn.custom_minimum_size = Vector2(140, 34)
	tutorial_hud_btn.pressed.connect(show_tutorial.bind(true))
	top_hbox.add_child(tutorial_hud_btn)
	
	# Pontuação e Progresso
	var stats_vbox = VBoxContainer.new()
	top_hbox.add_child(stats_vbox)
	
	hud_score_label = Label.new()
	hud_score_label.text = "SCORE: 0"
	hud_score_label.add_theme_font_size_override("font_size", 16)
	stats_vbox.add_child(hud_score_label)
	
	hud_planets_label = Label.new()
	hud_planets_label.text = "EXPLORAÇÃO: 0 / 5"
	hud_planets_label.add_theme_font_size_override("font_size", 13)
	hud_planets_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	stats_vbox.add_child(hud_planets_label)
	
	hud_planets_list_label = Label.new()
	hud_planets_list_label.text = ""
	hud_planets_list_label.add_theme_font_size_override("font_size", 9)
	hud_planets_list_label.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0, 0.8))
	stats_vbox.add_child(hud_planets_list_label)
	
	# Margem inferior para coordenadas
	var margin_bottom = MarginContainer.new()
	margin_bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	margin_bottom.add_theme_constant_override("margin_left", 20)
	margin_bottom.add_theme_constant_override("margin_bottom", 20)
	hud_container.add_child(margin_bottom)
	
	hud_coord_label = Label.new()
	hud_coord_label.text = "COORDENADAS: (0, 0)"
	hud_coord_label.add_theme_font_size_override("font_size", 12)
	hud_coord_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	margin_bottom.add_child(hud_coord_label)
	
	# ---------------- PAINEL DE NAVEGAÇÃO DE PLANETA ----------------
	var margin_radar = MarginContainer.new()
	margin_radar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	margin_radar.add_theme_constant_override("margin_right", 20)
	margin_radar.add_theme_constant_override("margin_bottom", 20)
	hud_container.add_child(margin_radar)
	
	var radar_vbox = VBoxContainer.new()
	radar_vbox.add_theme_constant_override("separation", 4)
	margin_radar.add_child(radar_vbox)
	
	var radar_title = Label.new()
	radar_title.text = "TELEMETRIA DE ALVO"
	radar_title.add_theme_font_size_override("font_size", 12)
	radar_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2)) # Dourado
	radar_vbox.add_child(radar_title)
	
	hud_target_name_label = Label.new()
	hud_target_name_label.text = "ALVO: NENHUM"
	hud_target_name_label.add_theme_font_size_override("font_size", 10)
	radar_vbox.add_child(hud_target_name_label)
	
	hud_target_coord_label = Label.new()
	hud_target_coord_label.text = "COORD: N/A"
	hud_target_coord_label.add_theme_font_size_override("font_size", 10)
	radar_vbox.add_child(hud_target_coord_label)
	
	hud_target_dist_label = Label.new()
	hud_target_dist_label.text = "DIST: N/A"
	hud_target_dist_label.add_theme_font_size_override("font_size", 10)
	radar_vbox.add_child(hud_target_dist_label)
	
	hud_target_bearing_label = Label.new()
	hud_target_bearing_label.text = "RUMO: N/A"
	hud_target_bearing_label.add_theme_font_size_override("font_size", 10)
	radar_vbox.add_child(hud_target_bearing_label)
	
	# ---------------- MENU DE PAUSA ----------------
	pause_container = Control.new()
	pause_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(pause_container)
	
	var pause_bg = ColorRect.new()
	pause_bg.color = Color(0.01, 0.01, 0.03, 0.75)
	pause_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_container.add_child(pause_bg)
	
	var pause_center = CenterContainer.new()
	pause_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_container.add_child(pause_center)
	
	var pause_vbox = VBoxContainer.new()
	pause_vbox.add_theme_constant_override("separation", 15)
	pause_center.add_child(pause_vbox)
	
	var pause_lbl = Label.new()
	pause_lbl.text = "SISTEMAS EM PAUSA"
	pause_lbl.add_theme_font_size_override("font_size", 38)
	pause_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.1))
	pause_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_vbox.add_child(pause_lbl)
	
	var resume_btn = Button.new()
	resume_btn.text = "RETOMAR VOO"
	resume_btn.custom_minimum_size = Vector2(250, 45)
	resume_btn.pressed.connect(toggle_pause)
	pause_vbox.add_child(resume_btn)
	
	var p_menu_btn = Button.new()
	p_menu_btn.text = "MENU PRINCIPAL"
	p_menu_btn.custom_minimum_size = Vector2(250, 45)
	p_menu_btn.pressed.connect(return_to_menu)
	pause_vbox.add_child(p_menu_btn)
	
	# ---------------- TELA GAME OVER / VITÓRIA ----------------
	gameover_container = Control.new()
	gameover_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(gameover_container)
	
	var go_bg = ColorRect.new()
	go_bg.color = Color(0.05, 0.01, 0.01, 0.88)
	go_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gameover_container.add_child(go_bg)
	
	var go_center = CenterContainer.new()
	go_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gameover_container.add_child(go_center)
	
	var go_vbox = VBoxContainer.new()
	go_vbox.add_theme_constant_override("separation", 20)
	go_center.add_child(go_vbox)
	
	game_over_title = Label.new()
	game_over_title.name = "GameOverTitle"
	game_over_title.text = "MISSÃO COMPROMETIDA"
	game_over_title.add_theme_font_size_override("font_size", 42)
	game_over_title.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_vbox.add_child(game_over_title)
	
	stats_detail_label = Label.new()
	stats_detail_label.text = "Resumo estatístico..."
	stats_detail_label.add_theme_font_size_override("font_size", 16)
	stats_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_vbox.add_child(stats_detail_label)
	
	var restart_btn = Button.new()
	restart_btn.text = "JOGAR NOVAMENTE"
	restart_btn.custom_minimum_size = Vector2(250, 45)
	restart_btn.pressed.connect(restart_game)
	go_vbox.add_child(restart_btn)
	
	var go_menu_btn = Button.new()
	go_menu_btn.text = "MENU PRINCIPAL"
	go_menu_btn.custom_minimum_size = Vector2(250, 45)
	go_menu_btn.pressed.connect(return_to_menu)
	go_vbox.add_child(go_menu_btn)
	
	# ---------------- TUTORIAL ----------------
	tutorial_container = Control.new()
	tutorial_container.name = "TutorialOverlay"
	tutorial_container.process_mode = Node.PROCESS_MODE_ALWAYS
	tutorial_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tutorial_container.visible = false
	ui_layer.add_child(tutorial_container)
	
	var tutorial_bg = ColorRect.new()
	tutorial_bg.color = Color(0.01, 0.02, 0.06, 0.96)
	tutorial_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tutorial_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	tutorial_container.add_child(tutorial_bg)
	
	var tutorial_center = CenterContainer.new()
	tutorial_center.name = "TutorialCenter"
	tutorial_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tutorial_container.add_child(tutorial_center)
	
	var tutorial_panel = PanelContainer.new()
	tutorial_panel.name = "TutorialPanel"
	tutorial_panel.custom_minimum_size = Vector2(820, 0)
	var tutorial_panel_style = StyleBoxFlat.new()
	tutorial_panel_style.bg_color = Color(0.025, 0.04, 0.09, 1.0)
	tutorial_panel_style.border_color = Color(0.0, 0.75, 1.0, 0.9)
	tutorial_panel_style.set_border_width_all(2)
	tutorial_panel_style.set_corner_radius_all(8)
	tutorial_panel_style.set_content_margin_all(24)
	tutorial_panel.add_theme_stylebox_override("panel", tutorial_panel_style)
	tutorial_center.add_child(tutorial_panel)
	
	var tutorial_content = VBoxContainer.new()
	tutorial_content.name = "TutorialContent"
	tutorial_content.add_theme_constant_override("separation", 12)
	tutorial_panel.add_child(tutorial_content)
	
	var tutorial_title = Label.new()
	tutorial_title.name = "TutorialTitle"
	tutorial_title.text = "GUIA DE VOO"
	tutorial_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_title.add_theme_font_size_override("font_size", 28)
	tutorial_title.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0))
	tutorial_content.add_child(tutorial_title)
	
	var tutorial_subtitle = Label.new()
	tutorial_subtitle.text = "Sua missão: explorar o sistema e voltar em segurança."
	tutorial_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_subtitle.add_theme_font_size_override("font_size", 15)
	tutorial_subtitle.add_theme_color_override("font_color", Color(0.65, 0.78, 0.9))
	tutorial_content.add_child(tutorial_subtitle)
	
	_add_tutorial_section(tutorial_content, "1. PILOTE A NAVE", "Use W, A, S, D ou as setas do teclado para se mover. A nave tem inércia: solte as teclas para desacelerar.")
	_add_tutorial_section(tutorial_content, "2. DESCUBRA OS PLANETAS", "Explore os 5 planetas. Aproxime-se e permaneça na área de escaneamento até o anel completar. O indicador dourado e a telemetria ajudam a encontrar o planeta mais próximo.")
	_add_tutorial_section(tutorial_content, "3. USE O LASER", "Pressione ESPAÇO para disparar na direção em que a nave aponta. Tiros também descobrem planetas; asteroides podem exigir vários acertos e se dividir em menores.")
	_add_tutorial_section(tutorial_content, "4. CUIDE DOS ESCUDOS", "Evite colidir com asteroides. Você começa com 3 escudos; perder todos encerra a missão. Descubra os 5 planetas para vencer. Pressione ESC para pausar.")
	
	var tutorial_close_btn = Button.new()
	tutorial_close_btn.name = "TutorialCloseButton"
	tutorial_close_btn.text = "VOLTAR"
	tutorial_close_btn.custom_minimum_size = Vector2(220, 42)
	tutorial_close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tutorial_close_btn.pressed.connect(close_tutorial)
	tutorial_content.add_child(tutorial_close_btn)
	
	var pixel_font = load("res://assets/fonts/pixel_font.ttf")
	if pixel_font:
		tutorial_container.add_theme_font_override("font", pixel_font)
	
	# Aplicar estilo de pixel art nas fontes recursivamente
	if pixel_font:
		apply_pixel_style(menu_container, pixel_font)
		apply_pixel_style(hud_container, pixel_font)
		apply_pixel_style(pause_container, pixel_font)
		apply_pixel_style(gameover_container, pixel_font)

func _add_tutorial_section(parent: VBoxContainer, heading_text: String, body_text: String):
	var card = PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.04, 0.08, 0.15, 0.95)
	card_style.border_color = Color(0.0, 0.55, 0.8, 0.55)
	card_style.set_border_width_all(1)
	card_style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", card_style)
	parent.add_child(card)
	
	var card_content = VBoxContainer.new()
	card_content.add_theme_constant_override("separation", 4)
	card.add_child(card_content)
	
	var heading = Label.new()
	heading.text = heading_text
	heading.add_theme_font_size_override("font_size", 16)
	heading.add_theme_color_override("font_color", Color(0.2, 1.0, 0.7))
	card_content.add_child(heading)
	
	var body = Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	card_content.add_child(body)

func show_tutorial(from_game: bool = false):
	if not tutorial_container:
		return
	
	tutorial_return_state = game_state
	if from_game and game_state == State.PLAYING:
		game_state = State.PAUSED
		get_tree().paused = true
		pause_container.visible = false
	
	tutorial_container.visible = true
	var close_button = tutorial_container.get_node_or_null("TutorialCenter/TutorialPanel/TutorialContent/TutorialCloseButton")
	if close_button:
		close_button.text = "RETOMAR JOGO" if tutorial_return_state == State.PLAYING else "VOLTAR"

func close_tutorial():
	if not tutorial_container or not tutorial_container.visible:
		return
	
	tutorial_container.visible = false
	if tutorial_return_state == State.PLAYING:
		get_tree().paused = false
		game_state = State.PLAYING
		menu_container.visible = false
		hud_container.visible = true
		pause_container.visible = false
	elif tutorial_return_state == State.PAUSED:
		get_tree().paused = true
		game_state = State.PAUSED
		pause_container.visible = true
	else:
		get_tree().paused = false
		game_state = State.MENU
		menu_container.visible = true
		hud_container.visible = false
		pause_container.visible = false

func apply_pixel_style(control, custom_font):
	if not custom_font:
		return
		
	if control is Label:
		control.add_theme_font_override("font", custom_font)
		var current_size = control.get_theme_font_size("font_size")
		if current_size > 40:
			control.add_theme_font_size_override("font_size", 24)
		elif current_size > 25:
			control.add_theme_font_size_override("font_size", 16)
		elif current_size > 14:
			control.add_theme_font_size_override("font_size", 10)
		else:
			control.add_theme_font_size_override("font_size", 8)
			
	elif control is Button:
		control.add_theme_font_override("font", custom_font)
		var current_size = control.get_theme_font_size("font_size")
		if current_size > 14:
			control.add_theme_font_size_override("font_size", 10)
		else:
			control.add_theme_font_size_override("font_size", 8)
			
	for child in control.get_children():
		if child is Control:
			apply_pixel_style(child, custom_font)

func _process(delta):
	# Suavização da Câmera seguindo o Jogador no espaço
	if ship and is_instance_valid(ship) and game_state == State.PLAYING:
		camera.global_position = camera.global_position.lerp(ship.global_position, 5.0 * delta)
		
		# Atualizar coordenada HUD
		var pos = ship.global_position
		hud_coord_label.text = "COORDENADAS: (%.0f, %.0f)" % [pos.x, pos.y]
		
		# Buscar planeta inexplorado mais próximo
		var planets = get_tree().get_nodes_in_group("planet")
		var min_dist = 999999.0
		var nearest_planet = null
		
		for p in planets:
			if is_instance_valid(p) and not p.discovered:
				var d = ship.global_position.distance_to(p.global_position)
				if d < min_dist:
					min_dist = d
					nearest_planet = p
					
		if nearest_planet:
			var target_pos = nearest_planet.global_position
			var ship_pos = ship.global_position
			var dist = ship_pos.distance_to(target_pos)
			
			# Determinar o índice dele no cenário
			var target_idx = planets.find(nearest_planet) + 1
			if hud_target_name_label:
				hud_target_name_label.text = "ALVO: PLANETA #%d" % target_idx
			if hud_target_coord_label:
				hud_target_coord_label.text = "COORD: (%.0f, %.0f)" % [target_pos.x, target_pos.y]
			if hud_target_dist_label:
				hud_target_dist_label.text = "DIST: %.0f m" % (dist / 10.0) # Escala legível
				
			var angle_rad = (target_pos - ship_pos).angle()
			var angle_deg = rad_to_deg(angle_rad)
			if angle_deg < 0:
				angle_deg += 360.0
				
			var dir_text = ""
			if angle_deg >= 337.5 or angle_deg < 22.5:
				dir_text = "L"
			elif angle_deg >= 22.5 and angle_deg < 67.5:
				dir_text = "SE"
			elif angle_deg >= 67.5 and angle_deg < 112.5:
				dir_text = "S"
			elif angle_deg >= 112.5 and angle_deg < 157.5:
				dir_text = "SO"
			elif angle_deg >= 157.5 and angle_deg < 202.5:
				dir_text = "O"
			elif angle_deg >= 202.5 and angle_deg < 247.5:
				dir_text = "NO"
			elif angle_deg >= 247.5 and angle_deg < 292.5:
				dir_text = "N"
			elif angle_deg >= 292.5 and angle_deg < 337.5:
				dir_text = "NE"
				
			if hud_target_bearing_label:
				hud_target_bearing_label.text = "RUMO: %.0f° [%s]" % [angle_deg, dir_text]
		else:
			if hud_target_name_label:
				hud_target_name_label.text = "ALVO: SISTEMA EXPLORADO"
			if hud_target_coord_label:
				hud_target_coord_label.text = "COORD: N/A"
			if hud_target_dist_label:
				hud_target_dist_label.text = "DIST: N/A"
			if hud_target_bearing_label:
				hud_target_bearing_label.text = "RUMO: N/A"
				
		# Atualizar a lista de coordenadas de todos os planetas no HUD
		var planets_list_text = ""
		var unexplored_idx = 1
		for p in planets:
			if is_instance_valid(p):
				var p_pos = p.global_position
				var p_dist = ship.global_position.distance_to(p_pos) / 10.0
				if not p.discovered:
					planets_list_text += "P%d: (%.0f, %.0f) - %.0f m\n" % [unexplored_idx, p_pos.x, p_pos.y, p_dist]
				else:
					planets_list_text += "P%d: [EXPLORADO]\n" % unexplored_idx
				unexplored_idx += 1
				
		if hud_planets_list_label:
			hud_planets_list_label.text = planets_list_text
		
	# Processar efeito de tremer a tela (screenshake)
	if shake_duration > 0.0:
		shake_duration -= delta
		camera.offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		camera.offset = Vector2.ZERO
		
	# Spawner de asteroides
	if game_state == State.PLAYING:
		spawn_timer += delta
		if spawn_timer >= spawn_interval:
			spawn_asteroid_near_player()
			spawn_timer = 0.0

func _input(event):
	if tutorial_container and tutorial_container.visible and event.is_action_pressed("ui_cancel"):
		close_tutorial()
		get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed("ui_cancel"):
		if game_state == State.PLAYING:
			toggle_pause()
		elif game_state == State.PAUSED:
			toggle_pause()

func enter_menu_state():
	game_state = State.MENU
	menu_container.visible = true
	hud_container.visible = false
	pause_container.visible = false
	gameover_container.visible = false
	
	if ship and is_instance_valid(ship):
		ship.visible = false
		ship.set_physics_process(false)
		ship.set_process(false)

func start_game():
	game_state = State.PLAYING
	menu_container.visible = false
	hud_container.visible = true
	pause_container.visible = false
	gameover_container.visible = false
	
	score = 0
	asteroids_destroyed = 0
	planets_discovered = 0
	update_hud_labels()
	
	if ship and is_instance_valid(ship):
		ship.visible = true
		ship.set_physics_process(true)
		ship.set_process(true)
		ship.global_position = Vector2(640, 360)
		ship.shield = ship.max_shield
		ship.is_invulnerable = false
		ship.scale = Vector2.ONE
		update_hud_shield(ship.shield, ship.max_shield)
		camera.global_position = ship.global_position
		
	# Garantir que a música está tocando
	if not music_player.playing:
		music_player.play()

func toggle_pause():
	if game_state == State.PLAYING:
		game_state = State.PAUSED
		get_tree().paused = true
		pause_container.visible = true
	elif game_state == State.PAUSED:
		game_state = State.PLAYING
		get_tree().paused = false
		pause_container.visible = false

func restart_game():
	skip_menu_next_load = true
	get_tree().paused = false
	get_tree().reload_current_scene()

func return_to_menu():
	skip_menu_next_load = false
	get_tree().paused = false
	get_tree().reload_current_scene()

func update_hud_labels():
	hud_score_label.text = "SCORE: %d" % score
	hud_planets_label.text = "EXPLORAÇÃO: %d / %d" % [planets_discovered, total_planets]

func update_hud_shield(current: int, max_val: int):
	if hud_shield_bar:
		hud_shield_bar.max_value = max_val
		hud_shield_bar.value = current

func shake_camera(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration

func spawn_initial_planets():
	# Remover planetas se já existirem na cena (para segurança em restarts)
	for child in get_children():
		if child.is_in_group("planet"):
			child.queue_free()
			
	for i in range(total_planets):
		var planet = planet_scene.instantiate()
		var angle = randf() * TAU
		var distance = randf_range(400, 1600)
		planet.global_position = Vector2(cos(angle), sin(angle)) * distance
		
		# Alternar sprites
		var sprite = planet.get_node("Sprite2D")
		if sprite:
			sprite.texture = planet_large_1 if i % 2 == 0 else planet_large_2
		
		planet.scale = Vector2(0.8, 0.8)
		planet.z_index = -2
		add_child(planet)

func spawn_asteroid_near_player():
	if not ship or not is_instance_valid(ship) or game_state != State.PLAYING:
		return
		
	var asteroid = asteroid_scene.instantiate()
	var angle = randf() * TAU
	var distance = 850.0  # Ligeiramente fora da tela 1280x720
	asteroid.global_position = ship.global_position + Vector2(cos(angle), sin(angle)) * distance
	asteroid.size = 0  # Faz randomizar o tamanho internamente
	add_child(asteroid)

func on_asteroid_destroyed(_pos: Vector2, value: int):
	asteroids_destroyed += 1
	score += value
	update_hud_labels()
	
	# Áudio e Screenshake
	sfx_explosion.play()
	shake_camera(8.0, 0.2)

func on_planet_discovered(pos: Vector2):
	planets_discovered += 1
	score += 100
	update_hud_labels()
	
	# Áudio e Screenshake
	sfx_collect.play()
	shake_camera(12.0, 0.25)
	
	# Efeito de fogos neon orbitando
	spawn_celebration_particles(pos)
	
	# Condição de Vitória
	if planets_discovered >= total_planets:
		trigger_victory()

func spawn_celebration_particles(pos: Vector2):
	var p = CPUParticles2D.new()
	add_child(p)
	p.global_position = pos
	p.amount = 60
	p.lifetime = 1.0
	p.one_shot = true
	p.explosiveness = 0.95
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 180.0
	p.initial_velocity_max = 320.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 7.0
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.0, 1.0, 0.5, 1.0))   # Verde neon
	gradient.set_color(1, Color(0.5, 0.0, 0.5, 0.0))
	gradient.add_point(0.4, Color(1.0, 0.8, 0.0, 1.0)) # Dourado
	gradient.add_point(0.8, Color(0.0, 0.8, 1.0, 0.8)) # Azul neon
	p.color_ramp = gradient
	
	p.emitting = true
	await get_tree().create_timer(1.2).timeout
	if is_instance_valid(p):
		p.queue_free()

func on_ship_destroyed(_pos: Vector2):
	sfx_explosion.play()
	shake_camera(20.0, 0.6)
	
	# Aguarda a animação e depois mostra Game Over
	await get_tree().create_timer(0.8).timeout
	show_game_over(false)

func show_game_over(victory: bool):
	game_state = State.GAMEOVER
	hud_container.visible = false
	gameover_container.visible = true
	
	if victory:
		game_over_title.text = "MISSÃO CUMPRIDA"
		game_over_title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5)) # Verde
		stats_detail_label.text = "PARABÉNS! Você explorou todos os planetas!\n\nScore Final: %d\nAsteroides Destruídos: %d" % [score, asteroids_destroyed]
	else:
		game_over_title.text = "MISSÃO COMPROMETIDA"
		game_over_title.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25)) # Vermelho
		stats_detail_label.text = "Sua nave foi desintegrada nos confins do espaço.\n\nScore Final: %d\nPlanetas Explorados: %d / %d\nAsteroides Destruídos: %d" % [score, planets_discovered, total_planets, asteroids_destroyed]

func trigger_victory():
	show_game_over(true)
