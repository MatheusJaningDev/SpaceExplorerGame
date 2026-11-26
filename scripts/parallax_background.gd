extends ParallaxBackground

@onready var parallax_layer = $ParallaxLayer
@onready var sprite = $ParallaxLayer/Sprite2D

func _ready():
	# Configurar o mirroring dinamicamente baseado na textura e escala
	if sprite and sprite.texture:
		var tex_size = sprite.texture.get_size()
		parallax_layer.motion_mirroring = tex_size * sprite.scale
		print("ParallaxBackground: Configurado mirroring para ", parallax_layer.motion_mirroring)
	else:
		parallax_layer.motion_mirroring = Vector2(2048, 2048)

func _process(_delta):
	# O ParallaxBackground segue a Camera2D automaticamente.
	pass
