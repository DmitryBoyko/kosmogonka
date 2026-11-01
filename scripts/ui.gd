extends CanvasLayer
signal action(name_value: String)
const TouchSlider = preload("res://scripts/touch_volume_slider.gd")
const Decor = preload("res://scripts/space_decor.gd")
const Planets = preload("res://scripts/planets.gd")
const INK := Color("e9f8ff")
const MINT := Color("84f3d8")
const MUTED := Color("a9b8d7")
var root: Control
var screen: Control
var hud: Control
var lives_label: Label
var score_label: Label
var stage_label: Label
var progress: ColorRect
var progress_fill: ColorRect
var booster_label: Label
var hint_label: Label
var flash: ColorRect
var transition: ColorRect
var toast_label: Label
var skip: Button
var current := ""
var settings_return := "menu"

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font = preload("res://assets/fonts/Nunito-Bold.ttf")
	theme.default_font_size = 20
	root.theme = theme
	add_child(root)
	var decor := Decor.new()
	decor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(decor)
	build_hud()
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(screen)
	toast_label = text(root, "", 21, 223, 72, 55, 430, MINT)
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_shadow_color", Color("171c43"))
	toast_label.add_theme_constant_override("shadow_offset_y", 2)
	toast_label.visible = false
	flash = ColorRect.new()
	flash.color = Color(1, 0.4, 0.5, 0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash)
	transition = ColorRect.new()
	transition.color = Color(0.05, 0.08, 0.18, 0)
	transition.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(transition)
	root.resized.connect(_layout)

func _layout() -> void:
	# Base canvas 540 x 960; grow the outer frame on taller phones.
	var offset := maxf(0, (root.size.x - 540) * 0.5)
	screen.position.x = offset
	hud.position.x = offset
	toast_label.position.x = offset + 55
	var extra := maxf(0, root.size.y - 960)
	for child in screen.get_children():
		if child is ColorRect:
			child.position = Vector2(-offset, 0)
			child.size = root.size
			continue
		if not child.has_meta("base_y"): child.set_meta("base_y", child.position.y)
		var base: float = child.get_meta("base_y")
		var shift := 0.0
		if current in ["pause", "settings", "countdown"]: shift = extra * 0.5
		elif base >= 500: shift = extra
		child.position.y = base + shift
	hint_label.position.y = 817 + extra

func text(parent: Node, value: String, font_size: int, y: float, height: float = 40, x: float = 30, width: float = 480, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = value
	label.position = Vector2(x, y)
	label.size = Vector2(width, height)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func panel(parent: Node, y: float, height: float, x: float = 26, width: float = 488) -> Panel:
	var p := Panel.new()
	p.position = Vector2(x, y)
	p.size = Vector2(width, height)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.07, 0.17, 0.94)
	style.border_color = Color(0.45, 0.77, 0.81, 0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(24)
	style.shadow_color = Color(0.02, 0.03, 0.12, 0.28)
	style.shadow_size = 12
	p.add_theme_stylebox_override("panel", style)
	parent.add_child(p)
	return p

func button(parent: Node, value: String, command: String, y: float, primary: bool = false, x: float = 48, width: float = 444, height: float = 64) -> Button:
	var b := Button.new()
	b.text = value
	b.position = Vector2(x, y)
	b.size = Vector2(width, height)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 24 if primary else 21)
	b.add_theme_color_override("font_color", Color("163c50") if primary else INK)
	b.add_theme_color_override("font_hover_color", Color("163c50") if primary else Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color("163c50"))
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("87f0d2") if primary else Color("25344f")
		if state == "hover": style.bg_color = style.bg_color.lightened(0.12)
		if state == "pressed": style.bg_color = Color("63bfb6")
		style.border_color = Color("c1fff0") if primary else Color("63859b")
		style.set_border_width_all(1)
		style.set_corner_radius_all(18)
		style.shadow_color = Color("17354b")
		style.shadow_offset = Vector2(0, 4)
		style.shadow_size = 0
		b.add_theme_stylebox_override(state, style)
	b.pressed.connect(func(): action.emit(command))
	parent.add_child(b)
	return b

func clear_screen(name_value: String) -> void:
	current = name_value
	# Buttons can emit this transition while their pressed signal is still locked.
	for child in screen.get_children():
		child.hide()
		screen.remove_child(child)
		child.queue_free()
	hud.visible = false
	toast_label.visible = false
	call_deferred("_layout")

func shade() -> void:
	var dim := ColorRect.new()
	dim.size = root.size
	dim.color = Color(0.025, 0.035, 0.10, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	screen.add_child(dim)

func menu() -> void:
	clear_screen("menu")
	var overline := text(screen, "ПРИКЛЮЧЕНИЕ НАЧИНАЕТСЯ ЗДЕСЬ", 13, 70, 24, 30, 480, MINT)
	overline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title := text(screen, "КОСМОГОНКА", 51, 103, 78)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_shadow_color", Color("3f2b73"))
	title.add_theme_constant_override("shadow_offset_y", 5)
	var sub := text(screen, "Маленькие герои. Большой космос.", 19, 180, 30, 30, 480, Color("d1d8f6"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel(screen, 613, 254)
	text(screen, "4 ПЛАНЕТЫ  /  3 КОСМИЧЕСКИЕ ГОНКИ", 14, 630, 28, 52, 440, MINT)
	button(screen, "Играть   →", "select", 677, true)
	button(screen, "Настройки", "settings", 756)
	var foot := text(screen, "Кристальные сады  ·  Космические станции", 13, 882, 25, 30, 480, MUTED)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func selection(hero_index: int, planet: int = 0) -> void:
	clear_screen("select")
	text(screen, "ЭКИПАЖ КОСМОГОНКИ", 13, 70, 24, 30, 480, MINT).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text(screen, "Кто побежит?", 42, 108, 65).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text(screen, "Выбирай своего космогонщика", 19, 180).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button(screen, ("✓  " if hero_index == 0 else "") + "Мальчик", "boy", 581, hero_index == 0, 34, 226)
	button(screen, ("✓  " if hero_index == 1 else "") + "Девочка", "girl", 581, hero_index == 1, 280, 226)
	panel(screen, 674, 190)
	text(screen, Planets.get_data(planet).name.to_upper()+"  /  "+Planets.get_data(planet).subtitle, 13, 690, 30, 50, 450, MINT)
	text(screen, "3 жизни  ·  2 бустера  ·  около 2 минут", 17, 725, 28, 50, 450)
	button(screen, "На планету   →", "start", 773, true,48,285)
	button(screen, "Планеты", "planets", 773, false,345,147)
	button(screen, "←  Назад", "menu", 887, false, 165, 210, 43)

func build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	panel(hud, 40, 67, 24, 375)
	lives_label = text(hud, "♥ ♥ ♥", 25, 52, 38, 40, 147, Color("ffb2c9"))
	score_label = text(hud, "★ 0", 24, 52, 38, 207, 170, Color("ffe3a5"))
	button(hud, "Ⅱ", "pause", 40, false, 426, 88, 67)
	progress = ColorRect.new()
	progress.position = Vector2(30, 122)
	progress.size = Vector2(480, 5)
	progress.color = Color(0.1, 0.15, 0.3, 0.6)
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(progress)
	progress_fill = ColorRect.new()
	progress_fill.color = MINT
	progress_fill.size = Vector2(0, 5)
	progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_child(progress_fill)
	stage_label = text(hud, "АВРОРА", 12, 136, 24, 30, 480, Color("e1ecff"))
	booster_label = text(hud, "", 20, 176, 35, 30, 480, MINT)
	booster_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label = text(hud, "", 20, 817, 93, 32, 476)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_color_override("font_shadow_color", Color("182644"))
	hint_label.add_theme_constant_override("shadow_offset_y", 2)

func playing() -> void:
	clear_screen("play")
	hud.visible = true

func update_hud(lives: int, stars: int, fraction: float, stage: String, booster: String, seconds: float, hint: String) -> void:
	lives_label.text = "♥ ".repeat(lives) + "♡ ".repeat(3 - lives)
	score_label.text = "★ " + str(stars)
	progress_fill.size.x = 480 * clampf(fraction, 0, 1)
	stage_label.text = stage
	booster_label.text = ("РЕАКТИВНЫЙ РАНЕЦ" if booster == "jet" else "ПОПУТКА") + "  ·  %.1f с" % seconds if not booster.is_empty() else ""
	hint_label.text = hint

func cinematic(title_value: String, subtitle: String) -> void:
	clear_screen("cinematic")
	text(screen, title_value, 39, 87, 65).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text(screen, subtitle, 17, 160, 65).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip = button(screen, "Пропустить  →", "skip", 850, false, 292, 220, 53)

func paused() -> void:
	clear_screen("pause")
	shade()
	panel(screen, 242, 455)
	text(screen, "Пауза", 38, 263, 65, 50, 440).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button(screen, "Продолжить", "resume", 351, true)
	button(screen, "Настройки", "settings", 433)
	button(screen, "Заново", "restart", 515)
	button(screen, "В меню", "menu", 597)

func countdown(value: int) -> void:
	clear_screen("countdown")
	hud.visible = true
	text(screen, str(value), 104, 340, 150).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func settings(previous: String) -> void:
	settings_return = previous
	clear_screen("settings")
	shade()
	panel(screen, 110, 746)
	text(screen, "Настройки", 36, 126, 60, 45, 450).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var labels := {"Master": "Общая громкость", "Music": "Музыка", "Effects": "Эффекты", "Voices": "Голоса"}
	var i := 0
	for bus: String in labels:
		text(screen, labels[bus], 18, 211 + i * 95, 30, 52, 420)
		var slider := HSlider.new()
		slider.set_script(TouchSlider)
		slider.position = Vector2(52, 247 + i * 95)
		slider.size = Vector2(435, 36)
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.01
		slider.value = Profile.volumes[bus]
		var rail := StyleBoxFlat.new()
		rail.bg_color = Color("3b4d6b")
		rail.content_margin_top = 6
		rail.content_margin_bottom = 6
		rail.set_corner_radius_all(6)
		var fill := rail.duplicate() as StyleBoxFlat
		fill.bg_color = MINT
		slider.add_theme_stylebox_override("slider", rail)
		slider.add_theme_stylebox_override("grabber_area", fill)
		slider.add_theme_stylebox_override("grabber_area_highlight", fill)
		slider.value_changed.connect(func(value):
			Profile.volumes[bus] = value
			Profile.apply_audio()
			Profile.save())
		screen.add_child(slider)
		i += 1
	var toggles := [["Короткие пролёты", "reduced_motion"], ["Вибрация", "vibration"], ["Высокое качество", "quality"]]
	for j in toggles.size():
		var toggle := CheckButton.new()
		toggle.text = toggles[j][0]
		toggle.position = Vector2(48, 611 + j * 53)
		toggle.size = Vector2(440, 48)
		toggle.add_theme_font_size_override("font_size", 18)
		toggle.button_pressed = Profile.get(toggles[j][1])
		var key: String = toggles[j][1]
		toggle.toggled.connect(func(value):
			Profile.set(key, value)
			Profile.save()
			action.emit("preferences"))
		screen.add_child(toggle)
	button(screen, "Готово", "close_settings", 788, true)

func results(success: bool, stars: int, score: int, best: int, planet: int = 0) -> void:
	clear_screen("results")
	text(screen, Planets.get_data(planet).name.to_upper()+" ИССЛЕДОВАНА" if success else "ЕЩЁ ОДНО ПРИКЛЮЧЕНИЕ?", 13, 82, 28, 30, 480, MINT).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text(screen, "Вот это гонка!" if success else "Попробуем снова!", 39, 120, 65).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var more := success and planet<3
	panel(screen, 582, 360 if more else 295)
	text(screen, "★  %d       СЧЁТ  %d" % [stars, score], 25, 603, 45, 50, 440, Color("ffe3a5")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text(screen, "Твой рекорд: %d" % best, 17, 653, 35, 50, 440, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if more: button(screen,"Летим на "+Planets.get_data(planet+1).name+" →","next",704,true)
	button(screen, "Ещё раз   →", "restart", 785 if more else 704, not more)
	button(screen, "В меню", "menu", 866 if more else 785)

func planets(selected: int, unlocked: int) -> void:
	clear_screen("planets")
	shade()
	text(screen,"ВЫБИРАЙ ПРИКЛЮЧЕНИЕ",13,85,30,30,480,MINT).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	text(screen,"Наши планеты",38,130,60).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	for i in 4:
		var data := Planets.get_data(i)
		var title: String = ("✓ " if i==selected else "")+"%02d  %s" % [i+1,data.name]
		if i>unlocked: title+="  ·  закрыта"
		var b := button(screen,title,"planet_"+str(i),250+i*108,i==selected,38,464,62)
		b.disabled=i>unlocked
		text(screen,data.subtitle,15,316+i*108,28,48,440,MUTED)
	text(screen,"Завершай забеги и открывай новые миры",17,735).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	button(screen,"← Назад к экипажу","select",817,false)

func flight_playing(can_skip: bool) -> void:
	playing()
	current="flight"
	if can_skip: button(screen,"Пропустить перелёт →","skip_flight",887,false,220,290,43)

func update_flight(place: int, fraction: float, route: String, seconds: float, energy: int) -> void:
	lives_label.text="%d / 4" % place
	score_label.text="◌ "+str(energy)
	progress_fill.size.x=480*clampf(fraction,0,1)
	stage_label.text=route.to_upper()+"  /  ВСЕ СПЕШАТ НА ГОНКУ!"
	booster_label.text="УСКОРЕНИЕ  ·  %.1f с" % seconds if seconds>0 else ""
	hint_label.text="Свайпы ← → — обгоняй попутчиков\nСветовые кольца ускоряют корабль"

func flight_results(place: int, reward: int, target: int, skipped: bool) -> void:
	clear_screen("flight_result")
	text(screen,"ВСЕ УСПЕЛИ НА КОСМОДРОМ!",15,85,35,30,480,MINT).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	text(screen,"Пора на планету!",39,135,65).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	panel(screen,650,215)
	text(screen,"Перелёт пропущен" if skipped else "Место %d из 4   ·   ★ +%d" % [place,reward],23,670,45,48,444,Color("ffe3a5")).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	text(screen,Planets.get_data(target).name+" ждёт своих героев",19,720,35,48,444).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	button(screen,"Приземляемся! →","arrive",773,true)
