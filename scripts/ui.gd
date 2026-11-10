extends CanvasLayer
signal action(name_value: String)
const TouchSlider = preload("res://scripts/touch_volume_slider.gd")
const Decor = preload("res://scripts/space_decor.gd")
const Planets = preload("res://scripts/planets.gd")
const Course = preload("res://scripts/course.gd")
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
var walk_stick: Control
var shop_button:Button
var charge_buttons:Dictionary={}
var version_button:Label

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font = preload("res://assets/fonts/RussoOne-Regular.ttf")
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
		if child is ColorRect or child.has_meta("full_screen_art"):
			child.position = Vector2(-offset, 0)
			child.size = root.size
			continue
		if not child.has_meta("base_y"): child.set_meta("base_y", child.position.y)
		var base: float = child.get_meta("base_y")
		var shift := 0.0
		if current in ["pause", "settings", "countdown"]: shift = extra * 0.5
		elif base >= 500: shift = extra
		child.position.y = base + shift
	hint_label.position.y = (707 if current=="play" else 817) + extra

func boot_splash() -> void:
	clear_screen("boot")
	var background := ColorRect.new()
	background.color = Color("091127")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(background)
	var artwork := TextureRect.new()
	artwork.texture = preload("res://assets/branding/launch-splash.png")
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artwork.set_meta("full_screen_art", true)
	screen.add_child(artwork)
	_layout()

func text(parent: Node, value: String, font_size: int, y: float, height: float = 40, x: float = 30, width: float = 480, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
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
	b.text=value
	for symbol in ["←","→","↑","↓","↔","↗","✓"]: b.text=b.text.replace(symbol,"")
	b.text=b.text.strip_edges()
	if command=="pause": b.text=""
	b.position = Vector2(x, y)
	b.size = Vector2(width, height)
	b.clip_text=true
	b.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	b.focus_mode = Control.FOCUS_ALL
	b.set_meta("command",command)
	b.tooltip_text={"pause":"Пауза","walk_jump":"Прыжок","leave_finish":"К кораблю"}.get(command,b.text)
	if command in ["walk_jump","run_jump","leave_finish","use_charge_jet","use_charge_board"]: b.text=""
	b.add_theme_font_size_override("font_size", 24 if primary else 21)
	b.add_theme_color_override("font_color", Color("e6faff") if primary else INK)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color("d8eff6"))
	b.add_theme_color_override("font_disabled_color",Color("7e8b9f"))
	b.pressed.connect(func(): action.emit(command))
	parent.add_child(b)
	preload("res://scripts/space_button_face.gd").attach(b,primary)
	preload("res://scripts/action_icons.gd").apply(b,command,value)
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
	view_switch(screen)
	var title:=TextureRect.new();title.name="CosmoraceTitle"
	title.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;title.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title.texture=load("res://assets/branding/menu-title.svg")
	title.position=Vector2(26,103);title.size=Vector2(488,85)
	title.mouse_filter=Control.MOUSE_FILTER_IGNORE;screen.add_child(title)
	var overline := text(screen, "ПРИКЛЮЧЕНИЯ НАЧИНАЮТСЯ ЗДЕСЬ", 23, 194, 36, 30, 480, MINT)
	var sub := text(screen, "Маленькие герои. Большой космос.", 23, 232, 36, 30, 480, Color("e3dcff"))
	for line:Label in [overline,sub]:
		line.add_theme_color_override("font_shadow_color",Color("111b3e"))
		line.add_theme_constant_override("shadow_offset_x",1);line.add_theme_constant_override("shadow_offset_y",3)
	panel(screen, 654, 192)
	button(screen, "Играть   →", "select", 677, true)
	button(screen, "Настройки", "settings", 756)

func selection(hero_index: int, planet: int = 0) -> void:
	clear_screen("select")
	view_switch(screen)
	text(screen, "Кто побежит?", 42, 108, 65).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text(screen, "Выбирай своего космогонщика", 19, 180).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button(screen, ("✓  " if hero_index == 0 else "") + "Мальчик", "boy", 581, hero_index == 0, 34, 226)
	button(screen, ("✓  " if hero_index == 1 else "") + "Девочка", "girl", 581, hero_index == 1, 280, 226)
	panel(screen, 674, 190)
	text(screen, Planets.get_data(planet).name.to_upper()+"  /  "+Planets.get_data(planet).subtitle, 13, 690, 30, 50, 450, MINT)
	text(screen,"3 жизни  ·  Звёздная цель: %d ★" % Course.star_goal(planet),17,725,28,50,450)
	button(screen, "На планету   →", "start", 773, true,48,285)
	button(screen, "Планеты", "planets", 773, false,345,147)
	button(screen,"Конструктор","builder",887,false,48,260,48)
	button(screen,"Назад","menu",887,false,326,166,48)

func build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	panel(hud, 40, 67, 24, 294)
	lives_label = text(hud, "♥ ♥ ♥", 25, 52, 38, 38, 105, Color("ffb2c9"))
	score_label = text(hud, "★ 0", 22, 52, 38, 145, 162, Color("ffe3a5"))
	lives_label.autowrap_mode=TextServer.AUTOWRAP_OFF
	score_label.autowrap_mode=TextServer.AUTOWRAP_OFF
	view_switch(hud,true)
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
	lives_label.add_theme_font_size_override("font_size",25)
	lives_label.add_theme_color_override("font_color",Color("ffb2c9"))
	clear_screen("play")
	hud.visible = true
	button(screen,"","run_jump",836,false,418,90,80)
	for i in 2:
		var kind:String=["jet","board"][i]
		var control:=button(screen,"","use_charge_"+kind,658+i*86,false,440,68,70)
		control.tooltip_text="Огонь ранца · клавиша 1" if i==0 else "Энергия доски · клавиша 2"
		var image:=TextureRect.new(); image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; image.texture=preload("res://assets/ui/boost-fire.svg") if i==0 else preload("res://assets/ui/boost-energy.svg"); image.position=Vector2(18,5); image.size=Vector2(32,36); image.mouse_filter=Control.MOUSE_FILTER_IGNORE; control.add_child(image)
		var count:=text(control,"0",16,41,23,0,68); charge_buttons[kind]={"button":control,"label":count}

func update_charges(profile:Node,active:String) -> void:
	for kind:String in charge_buttons:
		var entry:Dictionary=charge_buttons[kind]
		if not is_instance_valid(entry.button): continue
		entry.label.text=str(profile.charge_count(kind))
		entry.button.disabled=profile.charge_count(kind)<=0 or not active.is_empty()
		entry.button.modulate.a=.55 if entry.button.disabled else 1.

func focus_charge(kind:String) -> void:
	for key:String in charge_buttons:
		var control:Button=charge_buttons[key].button
		if not is_instance_valid(control):continue
		var alpha:float=control.modulate.a
		control.modulate=Color("ffe7a1") if key==kind else Color.WHITE
		control.modulate.a=alpha

func exploring(planet_name: String) -> void:
	clear_screen("explore")
	button(screen,"Ⅱ","pause",40,false,445,70,58)
	button(screen,"","leave_finish",40,false,360,70,58)
	text(screen,planet_name.to_upper()+" · ПОБЕДА!",23,128,55,30,480,MINT)
	text(screen,"Побегай вокруг монумента — ты никуда не спешишь",16,202,60,30,480)
	text(screen,"Джойстик — бег · потяни экран — обзор",15,282,45,30,480,MUTED)
	walk_stick=preload("res://scripts/explore_stick.gd").new()
	walk_stick.position=Vector2(28,740); walk_stick.size=Vector2(160,160); screen.add_child(walk_stick)
	button(screen,"","walk_jump",774,false,402,90,90)
	shop_button=button(screen,"Магазин","shop_nearest",648,true,55,430,60)
	shop_button.visible=false

func update_hud(lives: int, stars: int, fraction: float, stage: String, booster: String, seconds: float, hint: String, goal: int = 0) -> void:
	lives_label.text = "♥".repeat(lives) + "♡".repeat(maxi(0,3-lives))
	score_label.text = "★ %d / %d" % [stars,goal] if goal>0 else "★ " + str(stars)
	progress_fill.size.x = 480 * clampf(fraction, 0, 1)
	stage_label.text = stage
	booster_label.text = ("РЕАКТИВНЫЙ РАНЕЦ" if booster == "jet" else "ЛЕТАЮЩАЯ ДОСКА") + "  ·  %.1f с" % seconds if not booster.is_empty() else ""
	hint_label.text = hint

func cinematic(title_value: String, subtitle: String) -> void:
	clear_screen("cinematic")
	view_switch(screen)
	var title_size:=39
	while root.theme.default_font.get_string_size(title_value,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size).x>480 and title_size>25: title_size-=1
	var title:=text(screen,title_value,title_size,87,65); title.name="CinematicTitle"
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	text(screen, subtitle, 17, 160, 65).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip = button(screen, "Пропустить  →", "skip", 850, false, 292, 220, 53)

func view_switch(parent:Control,compact:bool=false) -> void:
	var control:=button(parent,"","camera_view",40 if compact else 12,false,332 if compact else 440,70,67 if compact else 48)
	control.set_meta("compact_view",compact)
	control.add_theme_font_size_override("font_size",15)
	control.tooltip_text="Переключить забег: от первого / третьего лица"
	refresh_view_switch()

func refresh_view_switch() -> void:
	for control:Button in root.find_children("*","Button",true,false):
		if control.get_meta("command","")!="camera_view": continue
		preload("res://scripts/action_icons.gd").view(control,Profile.first_person)

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
		slider.set_meta("audio_bus",bus)
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
	var toggles := [["Меньше движения и вспышек", "reduced_motion"], ["Вибрация", "vibration"], ["Высокое качество", "quality"]]
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
		preload("res://scripts/space_button_face.gd").attach(toggle,false,true)
	button(screen, "Готово", "close_settings", 788, true)
	version_button=text(screen,"Версия "+str(ProjectSettings.get_setting("application/config/version","")),15,878,48,48,444,MUTED)
	version_button.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	version_button.mouse_filter=Control.MOUSE_FILTER_STOP
	version_button.gui_input.connect(func(event:InputEvent):
		if (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and event.device!=InputEvent.DEVICE_ID_EMULATION) or (event is InputEventScreenTouch and event.pressed):action.emit("version_tap")
	)

func results(success: bool, stars: int, score: int, best: int, planet: int = 0) -> void:
	clear_screen("results")
	text(screen, Planets.get_data(planet).name.to_upper()+" ИССЛЕДОВАНА" if success else "ЕЩЁ ОДНО ПРИКЛЮЧЕНИЕ?", 13, 82, 28, 30, 480, MINT).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text(screen, "Вот это гонка!" if success else "Попробуем снова!", 39, 120, 65).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var more := success and planet<Planets.count()-1
	panel(screen, 582, 360 if more else 295)
	text(screen, "★  %d       СЧЁТ  %d" % [stars, score], 25, 603, 45, 50, 440, Color("ffe3a5")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var goal := Course.star_goal(planet)
	var goal_text := "Звёздная цель выполнена!" if stars>=goal else "До звёздной цели: ещё %d ★" % (goal-stars)
	text(screen,goal_text+"  ·  Рекорд %d ★" % Profile.star_records[planet],16,653,35,50,440,MINT if stars>=goal else MUTED).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	if more: button(screen,"Летим на "+Planets.destination(planet+1)+" →","next",704,true)
	button(screen, "Ещё раз   →", "restart", 785 if more else 704, not more)
	button(screen, "В меню", "menu", 866 if more else 785)

func planets(selected: int, unlocked: int) -> void:
	clear_screen("planets")
	shade()
	text(screen,"Наши планеты",38,130,60).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var scroll:=ScrollContainer.new(); screen.add_child(scroll)
	scroll.position=Vector2(28,230); scroll.size=Vector2(484,485)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus=true
	var list:=Control.new(); list.custom_minimum_size=Vector2(464,Planets.count()*106); scroll.add_child(list)
	for i in Planets.count():
		var data:=Planets.get_data(i)
		var title:String=("✓ " if i==selected else "")+"%02d  %s"%[i+1,data.name]
		if i>unlocked: title+=" · закрыта"
		var b:=button(list,title,"planet_"+str(i),i*106,i==selected,6,450,58)
		b.disabled=i>unlocked
		text(list,data.subtitle+" / Сложность %d из 10"%[i+1],14,i*106+62,32,12,430,MUTED)

	text(screen,"Завершай забеги и открывай новые миры",17,735).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	button(screen,"← Назад к экипажу","select",817,false)

func flight_playing(can_skip: bool) -> void:
	playing()
	lives_label.add_theme_font_size_override("font_size",18)
	lives_label.add_theme_color_override("font_color",MINT)
	current="flight"
	if can_skip: button(screen,"Пропустить перелёт →","skip_flight",887,false,220,290,48)

func update_flight(place: int, fraction: float, route: String, seconds: float, energy: int) -> void:
	lives_label.text="МЕСТО %d/4"%place
	score_label.text="⚡ "+str(energy)
	progress_fill.size.x=480*clampf(fraction,0,1)
	stage_label.text=route.to_upper()+" / ОРБИТАЛЬНЫЙ СПРИНТ"
	booster_label.text="УСКОРЕНИЕ  ·  %.1f с" % seconds if seconds>0 else ""
	hint_label.text="Свайпы ← → — обгоняй попутчиков\nСветящиеся заряды ускоряют корабль"

func flight_results(place: int, reward: int, target: int, skipped: bool) -> void:
	clear_screen("flight_result")
	text(screen,"ВСЕ УСПЕЛИ НА КОСМОДРОМ!",15,85,35,30,480,MINT).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	text(screen,"Пора на планету!",39,135,65).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	panel(screen,650,215)
	text(screen,"Перелёт пропущен" if skipped else "Место %d из 4   ·   ★ +%d" % [place,reward],23,670,45,48,444,Color("ffe3a5")).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	text(screen,Planets.get_data(target).name+" ждёт своих героев",19,720,35,48,444).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	button(screen,"Приземляемся! →","arrive",773,true)
