extends Node2D

const FILAS = 6
const COLUMNAS = 7

var turno = 1
var tablero = []
var eventos = []
var juego_terminado = false
var juego_iniciado = false

@onready var grid = $Control/GridContainer
@onready var panel = $Control/PanelPregunta
@onready var texto = $Control/PanelPregunta/TextoPregunta
@onready var input = $Control/PanelPregunta/InputRespuesta
@onready var boton = $Control/PanelPregunta/BotonEnviar
@onready var panel_reglas = $Control/PanelReglas
@onready var boton_entendido = $Control/PanelReglas/BotonEntendido
@onready var panel_ganador = $Control/PanelGanador
@onready var texto_ganador = $Control/PanelGanador/LabelGanador


func _ready():
	panel.visible = false
	panel_ganador.visible = false
	panel_reglas.visible = true
	
	randomize()
	inicializar_tablero()
	conectar_botones()


func inicializar_tablero():
	tablero.clear()
	eventos.clear()

	for i in range(FILAS):
		tablero.append([])
		eventos.append([])
		
		for j in range(COLUMNAS):
			tablero[i].append(0)
			
			var rand = randi() % 10
			
			if rand == 0:
				eventos[i].append("bomba")
			elif rand == 1:
				eventos[i].append("diamante")
			else:
				eventos[i].append("")


func conectar_botones():
	var botones = grid.get_children()
	
	for i in range(botones.size()):
		var boton_temp = botones[i]
		var index = i
		
		boton_temp.pressed.connect(func():
			jugar(index)
		)



func jugar(index) -> void:
	if juego_terminado or not juego_iniciado:
		return

	var col = index % COLUMNAS
	
	for fila in range(FILAS - 1, -1, -1):
		if tablero[fila][col] == 0:
			
			
			var resultado = await procesar_evento(eventos[fila][col])
			
			
			if resultado == 2:
				turno = 2 if turno == 1 else 1
				return
			
			
			tablero[fila][col] = turno
			actualizar_visual(fila, col)
			
			
			if verificar_ganador(fila, col):
				juego_terminado = true
				efecto_ganar()
				await get_tree().create_timer(3.0).timeout
				mostrar_ganador(turno)
				return
			
			
			if resultado == 0:
				
				turno = 2 if turno == 1 else 1
			
			elif resultado == 1:
				
				pass
			
			break


func actualizar_visual(fila, col):
	var index = fila * COLUMNAS + col
	var boton_temp = grid.get_child(index)

	var estilo = boton_temp.get_theme_stylebox("normal").duplicate()

	if turno == 1:
		estilo.bg_color = Color(1, 0.3, 0.6)
	else:
		estilo.bg_color = Color(0.2, 0.5, 1)

	boton_temp.add_theme_stylebox_override("normal", estilo)

	
	var pos_final = boton_temp.position
	boton_temp.position.y = pos_final.y - 300

	var tween = create_tween()
	tween.tween_property(boton_temp, "position:y", pos_final.y, 0.3)


func procesar_evento(evento):
	if evento == "":
		return 0
	
	if evento == "diamante":
		texto.text = "💎 ¡Diamante!"
	else:
		texto.text = "💣 ¡Bomba!"
	
	panel.visible = true
	await get_tree().create_timer(1.5).timeout
	
	var correcto = await hacer_pregunta()
	
	if correcto:
		texto.text = "✅ Correcto"
	else:
		texto.text = "❌ Incorrecto"
	
	await get_tree().create_timer(1.5).timeout
	panel.visible = false
	
	
	if evento == "diamante":
		if correcto:
			return 1
		else:
			return 0
	
	
	elif evento == "bomba":
		if correcto:
			return 0
		else:
			return 2
	
	return 0


func hacer_pregunta():
	var a = randi() % 1000
	var b = randi() % 1000
	var correcta = a + b
	
	texto.text = "¿Cuánto es %d + %d?" % [a, b]
	input.text = ""
	panel.visible = true
	
	input.grab_focus()
	await boton.pressed
	
	var respuesta = 0
	
	if input.text.is_valid_int():
		respuesta = int(input.text)
	
	return respuesta == correcta


func verificar_ganador(f, c):
	var jugador = tablero[f][c]
	
	return (
		contar(f, c, 1, 0, jugador) + contar(f, c, -1, 0, jugador) >= 3 or
		contar(f, c, 0, 1, jugador) + contar(f, c, 0, -1, jugador) >= 3 or
		contar(f, c, 1, 1, jugador) + contar(f, c, -1, -1, jugador) >= 3 or
		contar(f, c, 1, -1, jugador) + contar(f, c, -1, 1, jugador) >= 3
	)


func contar(f, c, df, dc, jugador):
	var count = 0
	f += df
	c += dc
	
	while f >= 0 and f < FILAS and c >= 0 and c < COLUMNAS and tablero[f][c] == jugador:
		count += 1
		f += df
		c += dc
	
	return count

func efecto_ganar():
	for boton_temp in grid.get_children():
		var tween = create_tween()
		tween.tween_property(boton_temp, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(boton_temp, "scale", Vector2(1, 1), 0.1)

func mostrar_ganador(jugador):
	grid.visible = false
	panel.visible = false
	
	panel_ganador.visible = true
	texto_ganador.text = "🏆 ¡Gana Jugador " + str(jugador) + "! 🏆"


func _on_boton_reiniciar_pressed():
	print("CLICK")  
	get_tree().change_scene_to_file("res://juego.tscn")
	


func _on_boton_home_pressed() -> void:
	get_tree().change_scene_to_file("res://node_2d.tscn")


func _on_button_pressed() -> void:
	panel_reglas.visible = false
	juego_iniciado = true
