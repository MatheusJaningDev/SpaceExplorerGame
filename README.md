# Space Explorer - Protótipo Funcional Completo v2.0

Este é um protótipo funcional expandido e visualmente aprimorado desenvolvido para a avaliação N2, focado no **Core Game Loop** completo de um jogo de simulação espacial baseado em Geometria Analítica.

## 🎮 Core Game Loop Implementado

### 1. **Explorar** 🚀
- Navegue pelo espaço inserindo coordenadas cartesianas (X, Y).
- A nave move-se suavemente até à coordenada especificada.
- **Fundo Parallax Dinâmico**: Nebula espacial que se move continuamente, criando uma sensação de profundidade e movimento real.
- Sistema de radar em tempo real mostra a posição atual.

### 2. **Desviar/Combater** 💥
- **Asteroides Móveis**: 12 asteroides que se movem continuamente pelo espaço com velocidades aleatórias.
- **Sistema de Disparo Avançado**: Insira as coordenadas de um asteroide e dispare com precisão.
- **Dano e Destruição**: Os asteroides são destruídos ao serem atingidos com efeito de explosão.
- Feedback visual: asteroides ficam vermelhos ao serem atingidos.
- **Desafio Dinâmico**: Como os asteroides se movem, é necessário calcular a trajetória futura para acertar.

### 3. **Evoluir** ⭐
- **Planetas Grandes e Bonitos**: 4 planetas em alta qualidade (azul/roxo e laranja/vermelho) com tamanho significativo no mapa.
- **Descoberta de Planetas**: Navegue até um planeta ou dispare nele para descobrir.
- **Sistema de Pontuação Avançado**:
  - Destruir um asteroide: +10 pontos
  - Descobrir um planeta: +50 pontos
- Acompanhe o progresso em tempo real na UI.

## 🎮 Controles

| Ação | Controle |
|------|----------|
| Inserir Coordenada X | Campo de texto "X" |
| Inserir Coordenada Y | Campo de texto "Y" |
| Navegar | Botão "Navegar" ou clique do rato |
| Disparar | Botão "Disparar" |

## 🌟 Mecânicas de Jogo

- **Coordenadas Cartesianas**: Todas as ações são baseadas em coordenadas precisas (X, Y).
- **Movimento Dinâmico**: Asteroides movem-se continuamente, obrigando a cálculos precisos.
- **Colisões Precisas**: Projéteis colidem com asteroides e planetas.
- **Feedback Visual Completo**: 
  - Mudanças de cor indicam interações
  - Explosões com animação suave
  - Efeitos de impacto nos projéteis
- **Pontuação Dinâmica**: Acompanhe o teu progresso em tempo real.
- **Fundo Parallax**: Cria imersão e sensação de movimento contínuo.

## 📁 Estrutura do Projeto

```
SpaceExplorer/
├── assets/
│   └── sprites/
│       ├── ship.png              # Nave do jogador
│       ├── asteroid_moving.png   # Asteroide com movimento
│       ├── planet_large_1.png    # Planeta azul/roxo grande
│       ├── planet_large_2.png    # Planeta laranja/vermelho grande
│       └── space_background.png  # Fundo parallax nebula
├── scenes/
│   ├── main.tscn                # Cena principal com parallax
│   ├── bullet.tscn              # Projétil
│   ├── asteroid.tscn            # Asteroide móvel
│   └── planet.tscn              # Planeta
├── scripts/
│   ├── main.gd                  # Lógica principal do jogo
│   ├── ship.gd                  # Lógica da nave
│   ├── bullet.gd                # Lógica do projétil
│   ├── asteroid.gd              # Lógica do asteroide móvel
│   ├── planet.gd                # Lógica do planeta
│   └── parallax_background.gd   # Lógica do fundo parallax
├── project.godot                # Configuração do projeto
└── README.md                    # Este ficheiro
```

## 🚀 Como Executar

1. **Instale o Godot Engine**: Descarregue a versão 4.2 ou superior em [godotengine.org](https://godotengine.org/).
2. **Extraia o Arquivo**: Descompacte o ficheiro `SpaceExplorer_Prototipo.zip`.
3. **Importe o Projeto**:
   - Abra o Godot e clique em **"Import"**.
   - Navegue até à pasta extraída e selecione o ficheiro `project.godot`.
4. **Execute o Jogo**:
   - Pressione **F5** ou clique no botão **"Play"** (ícone de triângulo).

## 🎯 Exemplos de Uso

### Navegar para um Asteroide
1. Observe a posição de um asteroide no mapa (lembra-te que está em movimento!).
2. Insira as coordenadas X e Y no formulário.
3. Clique em **"Navegar"** para mover a nave.

### Disparar contra um Asteroide em Movimento
1. Identifique um asteroide e suas coordenadas **atuais**.
2. Insira as coordenadas X e Y.
3. Clique em **"Disparar"** para atirar.
4. Se acertar, o asteroide explode com efeito visual e ganha 10 pontos.
5. **Desafio**: Como os asteroides se movem, é necessário prever a trajetória!

### Descobrir um Planeta
1. Navegue até um planeta ou dispare nele.
2. O planeta muda de cor (amarelo) ao ser descoberto.
3. Ganhe 50 pontos por planeta descoberto.

## 🎨 Melhorias Visuais v2.0

- ✅ **Fundo Parallax Dinâmico**: Nebula espacial que se move continuamente
- ✅ **Planetas Grandes**: 4 planetas em alta qualidade e tamanho significativo
- ✅ **Asteroides Móveis**: 12 asteroides com movimento contínuo e aleatório
- ✅ **Efeitos de Explosão**: Animações suaves ao destruir asteroides
- ✅ **Feedback Visual Melhorado**: Cores vibrantes e efeitos de impacto
- ✅ **UI Aprimorada**: Status em tempo real e mensagens descritivas

## 🔧 Modificações Sugeridas

### Aumentar Dificuldade
Edite `scripts/asteroid.gd`:
```gdscript
var speed = randf_range(100, 250)  # Aumentar velocidade dos asteroides
var health = 50  # Aumentar vida dos asteroides
```

### Adicionar Mais Asteroides
Edite `scripts/main.gd`, função `spawn_obstacles()`:
```gdscript
for i in range(20):  # Aumentar de 12 para 20
    var asteroid = asteroid_scene.instantiate()
    ...
```

### Modificar Velocidade do Fundo
Edite `scripts/parallax_background.gd`:
```gdscript
var scroll_speed = 40  # Aumentar de 20 para movimento mais rápido
```

### Adicionar Efeitos Sonoros
Crie um script `audio_manager.gd` e adicione sons para disparos e explosões.

## 🎮 Tecnologia

- **Engine**: Godot 4.2
- **Linguagem**: GDScript
- **Estética**: Cyber-Futurista 2D com Parallax
- **Física**: Godot Physics 2D com Colisões de Área

## 📈 Próximas Melhorias

- [ ] Sistema de ondas de asteroides progressivas
- [ ] Upgrades de armas e nave
- [ ] Efeitos sonoros e música de fundo
- [ ] Modo de dificuldade progressiva
- [ ] Leaderboard local
- [ ] Tutoria interativa
- [ ] Partículas de explosão
- [ ] Sistema de combustível/energia

---

**Desenvolvido para a Avaliação N2 - Protótipo Funcional do Core Game Loop v2.0**

**Última Atualização**: Versão 2.0 com Parallax, Asteroides Móveis e Planetas Grandes
