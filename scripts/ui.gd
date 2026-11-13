extends CanvasLayer
signal action(name_value: String)
const TouchSlider = preload("res://scripts/touch_volume_slider.gd")
const Decor = preload("res://scripts/space_decor.gd")
const Planets = preload("res://scripts/planets.gd")
const Course = preload("res://scripts/course.gd")
const Crew = preload("res://scripts/crew.gd")
const INK := Color("e9f8ff")
const MINT := Color("84f3d8")
const MUTED := Color("a9b8d7")
const GOLD := Color("ffe3a5")
const PLAY_SCREENS := ["cinematic", "countdown", "play", "flight", "explore"]
const MENU_SCREENS := ["boot", "menu", "select", "planets", "settings", "pause",
	"results", "flight_result", "shop", "builder", "skin_picker"]
const TITLE_Y := 100.
const TITLE_HEIGHT := 68.
const ACTION_WIDTH := 352.
const ACTION_HEIGHT := 64.
var root: Control
var screen: Control
var hud: Control
var lives_label: Label
var score_label: Label
var stage_label: Label
var view_switch_button: Button
var progress: ColorRect
var progress_fill: ColorRect
var booster_label: Label
var run_inventory: Control
var run_stats: Panel
var heart_slots: Array[TextureProgressBar] = []
var score_star: TextureRect
var wallet_label: Label
var stock_labels: Dictionary = {}
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
var selection_portal:Control
var crew_name: Label
var crew_trip: Button

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
		if current in ["pause", "settings", "countdown"] or child.has_meta("crew_center"): shift = extra * 0.5
		elif base >= 500: shift = extra
		child.position.y = base + shift
		if child.name=="PlanetList": child.size.y=565.+extra
	hint_label.position.y = (665 if current=="flight" else 718) + extra

func boot_splash() -> void:
	clear_screen("boot")
	var artwork := TextureRect.new()
	artwork.texture = preload("res://assets/branding/launch-splash.png")
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_SCALE
	var fill := ShaderMaterial.new()
	fill.shader = preload("res://assets/branding/splash_fill.gdshader")
	fill.set_shader_parameter("space",preload("res://assets/space_backdrops/space_0_aurora.png"))
	artwork.material = fill
	artwork.resized.connect(func(): fill.set_shader_parameter("screen_size",artwork.size))
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artwork.set_meta("full_screen_art", true)
	screen.add_child(artwork)
	_layout()

func text(parent: Node, value: String, font_size: int, y: float, height: float = 40, x: float = 30, width: float = 480, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.position = Vector2(x, y)
	label.size = Vector2(width, height)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("111b3e"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 3)
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

func button(parent: Node, value: String, command: String, y: float, primary: bool = false, x: float = -1, width: float = 290, height: float = 64) -> Button:
	var b := Button.new()
	b.text=value
	for symbol in ["←","→","↑","↓","↔","↗","✓"]: b.text=b.text.replace(symbol,"")
	b.text=b.text.strip_edges()
	if command=="pause": b.text=""
	b.position = Vector2((540.-width)*.5 if x<0. else x, y)
	b.size = Vector2(width, height)
	b.clip_text=true
	b.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	b.focus_mode = Control.FOCUS_ALL
	b.set_meta("command",command)
	b.tooltip_text={"pause":"Пауза","walk_jump":"Прыжок","leave_finish":"К кораблю"}.get(command,b.text)
	if command in ["walk_jump","run_jump","leave_finish","use_charge_jet","use_charge_board"]: b.text=""
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color("d8eff6"))
	b.add_theme_color_override("font_disabled_color",Color("7e8b9f"))
	b.pressed.connect(func(): action.emit(command))
	parent.add_child(b)
	preload("res://scripts/space_button_face.gd").attach(b,primary)
	return b

func clear_screen(name_value: String) -> void:
	assert(name_value in PLAY_SCREENS or name_value in MENU_SCREENS, "Unclassified UI screen: " + name_value)
	current = name_value
	# Buttons can emit this transition while their pressed signal is still locked.
	for child in screen.get_children():
		child.hide()
		screen.remove_child(child)
		child.queue_free()
	hud.visible = false
	view_switch_button.visible = name_value!="flight"
	run_inventory.visible = name_value in ["play","countdown"]
	score_star.visible = run_inventory.visible
	lives_label.visible = name_value=="flight"
	run_stats.size.y = 91. if run_inventory.visible else 67.
	for heart:TextureProgressBar in heart_slots: heart.visible=run_inventory.visible
	toast_label.visible = false
	call_deferred("_layout")

func screen_title(value: String, y: float = TITLE_Y, font_size: int = 40) -> Label:
	var title := text(screen,value,font_size,y,TITLE_HEIGHT)
	title.name = "ScreenTitle"
	return title

func screen_action(value: String, command: String, y: float, primary: bool = false) -> Button:
	return button(screen,value,command,y,primary,-1.,ACTION_WIDTH,ACTION_HEIGHT)

func shade() -> void:
	var dim := ColorRect.new()
	dim.size = root.size
	dim.color = Color(0.025, 0.035, 0.10, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	screen.add_child(dim)

func menu() -> void:
	clear_screen("menu")
	var title:=TextureRect.new();title.name="CosmoraceTitle"
	title.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;title.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title.texture=load("res://assets/branding/menu-title.svg")
	title.position=Vector2(26,103);title.size=Vector2(488,85)
	title.mouse_filter=Control.MOUSE_FILTER_IGNORE;screen.add_child(title)
	text(screen,"ПРИКЛЮЧЕНИЯ НАЧИНАЮТСЯ ЗДЕСЬ",23,194,36,30,480,MINT)
	text(screen,"Маленькие герои. Большой космос.",23,232,36,30,480,Color("e3dcff"))
	screen_action("Играть","select",677,true)
	screen_action("Настройки","settings",755)
	add_crew_caption(Profile.hero)
	planet_heading(Profile.selected_planet,49)

func selection(hero_index: int, planet: int = 0) -> void:
	clear_screen("select")
	view_switch(screen)
	screen_title("Кто побежит?")
	planet_heading(planet,176)
	add_crew_caption(hero_index)
	text(screen,Planets.get_data(planet).subtitle,23,684,34,30,480,MINT)
	text(screen,"3 жизни  ·  Звёздная цель: %d ★" % Course.star_goal(planet),20,721,32)
	button(screen,"На планету","start",773,true,52,212)
	button(screen,"Планеты","planets",773,false,276,212)
	button(screen,"Назад","menu",851,false,164,212)

func planet_heading(planet:int,y:float) -> void:
	text(screen,"ПЛАНЕТА · "+Planets.get_data(planet).name,22,y,36,30,480,MINT)

func add_crew_caption(index: int) -> void:
	var selecting:=current=="select"
	crew_name = text(screen,"",38 if selecting else 25,567 if selecting else 577,51 if selecting else 35)
	crew_name.set_meta("crew_center",selecting)
	var hint := text(screen,"Листай влево или вправо",18,621,28,30,480,MINT)
	hint.visible=selecting
	hint.set_meta("crew_center",true)
	update_crew_caption(index)

func update_crew_caption(index: int) -> void:
	if is_instance_valid(crew_name):
		crew_name.text=Crew.NAMES[index]
	if is_instance_valid(crew_trip):
		crew_trip.hide()
		crew_trip.queue_free()
		crew_trip=null
	if current=="menu" and not Profile.pending_trip.is_empty():
		crew_trip=screen_action("Продолжить перелёт","continue_trip",552)
		crew_name.hide()
	elif is_instance_valid(crew_name):
		crew_name.show()
	_layout()

func build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	run_stats = panel(hud, 40, 91, 24, 294)
	run_stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 3:
		var heart := TextureProgressBar.new()
		var sprite := preload("res://assets/ui/hud-heart.png")
		heart.texture_under = sprite
		heart.texture_progress = sprite
		heart.tint_under = Color(.38,.25,.37,.62)
		heart.fill_mode = TextureProgressBar.FILL_BOTTOM_TO_TOP
		heart.nine_patch_stretch = true
		heart.value = 100.
		heart.position = Vector2(12+i*32,10)
		heart.size = Vector2(30,30)
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		run_stats.add_child(heart)
		heart_slots.append(heart)
	score_star = hud_icon(run_stats,preload("res://assets/ui/hud-star.png"),Vector2(126,8),Vector2(32,32))
	lives_label = text(hud, "♥ ♥ ♥", 25, 52, 38, 38, 105, Color("ffb2c9"))
	score_label = text(hud, "0", 24, 47, 39, 178, 129, Color("ffe3a5"))
	lives_label.autowrap_mode=TextServer.AUTOWRAP_OFF
	score_label.autowrap_mode=TextServer.AUTOWRAP_OFF
	view_switch_button=view_switch(hud,true)
	button(hud, "Ⅱ", "pause", 40, false, 426, 88, 67)
	progress = ColorRect.new()
	progress.position = Vector2(30, 140)
	progress.size = Vector2(480, 5)
	progress.color = Color(0.1, 0.15, 0.3, 0.6)
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(progress)
	progress_fill = ColorRect.new()
	progress_fill.color = MINT
	progress_fill.size = Vector2(0, 5)
	progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_child(progress_fill)
	stage_label = text(hud, "", 20, 150, 30, 30, 480, Color("e1ecff"))
	run_inventory = Control.new()
	run_inventory.name = "RunInventory"
	run_inventory.position = Vector2(0,44)
	run_inventory.size = Vector2(294,38)
	run_inventory.mouse_filter = Control.MOUSE_FILTER_IGNORE
	run_stats.add_child(run_inventory)
	var divider:=ColorRect.new()
	divider.position=Vector2(11,0)
	divider.size=Vector2(272,1)
	divider.color=Color("527a9c80")
	divider.mouse_filter=Control.MOUSE_FILTER_IGNORE
	run_inventory.add_child(divider)
	wallet_label = text(run_inventory,"",16,7,25,12,151,Color("ffe3a5"))
	wallet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	wallet_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	for i in 2:
		var boost_icon:=preload("res://assets/ui/boost-fire.svg") if i==0 else preload("res://assets/ui/boost-energy.svg")
		hud_icon(run_inventory,boost_icon,Vector2(166+i*57,6),Vector2(22,26))
		stock_labels[["jet","board"][i]] = text(run_inventory,"",18,7,25,188+i*57,26)
	booster_label = text(hud, "", 20, 197, 35, 30, 480, MINT)
	booster_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label = text(hud,"",20,718,84,106,328)

func reset_hud(is_flight: bool) -> void:
	lives_label.text = "МЕСТО —/4" if is_flight else ""
	lives_label.add_theme_font_size_override("font_size",18)
	lives_label.add_theme_color_override("font_color",MINT)
	score_label.text = "⚡ 0" if is_flight else "0"
	progress_fill.size.x = 0
	stage_label.text = ""
	booster_label.text = ""
	hint_label.text = ""

func hud_icon(parent:Control, sprite:Texture2D, at:Vector2, extent:Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = sprite
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = at
	icon.size = extent
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	return icon

func playing() -> void:
	clear_screen("play")
	reset_hud(false)
	hud.visible = true
	button(screen,"","run_jump",836,false,418,90,80)
	for i in 2:
		var kind:String=["jet","board"][i]
		var control:=button(screen,"","use_charge_"+kind,658+i*86,false,440,68,70)
		control.tooltip_text="Огонь ранца · клавиша 1" if i==0 else "Энергия доски · клавиша 2"
		var boost_icon:=preload("res://assets/ui/boost-fire.svg") if i==0 else preload("res://assets/ui/boost-energy.svg")
		hud_icon(control,boost_icon,Vector2(15,12),Vector2(38,44))
		charge_buttons[kind]={"button":control}

func update_charges(profile:Node,active:String) -> void:
	wallet_label.text = "Банк %d" % profile.bank
	for kind:String in stock_labels:
		stock_labels[kind].text = str(profile.charge_count(kind))
	for kind:String in charge_buttons:
		var entry:Dictionary=charge_buttons[kind]
		if not is_instance_valid(entry.button): continue
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
	button(screen,"Ⅱ","pause",40,false,445,70,67)
	button(screen,"","leave_finish",40,false,361,70,67)
	text(screen,planet_name.to_upper()+" · ПОБЕДА!",24,128,46,30,480,MINT)
	text(screen,"Джойстик — бег · свайп — обзор",19,181,42)
	walk_stick=preload("res://scripts/explore_stick.gd").new()
	walk_stick.position=Vector2(28,740); walk_stick.size=Vector2(160,160); screen.add_child(walk_stick)
	button(screen,"","walk_jump",826,false,418,90,80)
	shop_button=screen_action("Магазин","shop_nearest",648,true)
	shop_button.visible=false

func update_hud(lives: int, stars: int, fraction: float, stage: String, booster: String, seconds: float, hint: String, goal: int = 0) -> void:
	show_partial_heart(0.,lives)
	score_label.text = "%d / %d" % [stars,goal] if goal>0 else str(stars)
	progress_fill.size.x = 480 * clampf(fraction, 0, 1)
	stage_label.text = stage
	booster_label.text = ("РЕАКТИВНЫЙ РАНЕЦ" if booster == "jet" else "ЛЕТАЮЩАЯ ДОСКА") + "  ·  %.1f с" % seconds if not booster.is_empty() else ""
	hint_label.text = hint

func show_partial_heart(damage:float,lives:int) -> void:
	for i in heart_slots.size():
		heart_slots[i].visible = run_inventory.visible
		heart_slots[i].value=clampf(lives-i-damage,0.,1.)*100.

func arrival(planet: int) -> void:
	var data := Planets.get_data(planet)
	cinematic(data.name,data.subtitle,true)
	text(screen,"ПЛАНЕТА",20,66,31,30,480,MINT)

func cinematic(title_value: String, subtitle: String, can_set_camera: bool = false, can_skip: bool = true) -> void:
	clear_screen("cinematic")
	if can_set_camera: view_switch(screen)
	var title:=screen_title(title_value)
	title.name="CinematicTitle"
	text(screen,subtitle,22,title.position.y+title.size.y+12.,58,30,480,MINT)
	skip = screen_action("Пропустить","skip",852) if can_skip else null

func view_switch(parent:Control,compact:bool=false) -> Button:
	var control:=button(parent,"","camera_view",40 if compact else 12,false,332 if compact else 440,70,67 if compact else 48)
	preload("res://scripts/action_icons.gd").attach_camera(control)
	control.set_meta("compact_view",compact)
	control.add_theme_font_size_override("font_size",15)
	control.tooltip_text="Переключить забег: от первого / третьего лица"
	refresh_view_switch()
	return control

func refresh_view_switch() -> void:
	for control:Button in root.find_children("*","Button",true,false):
		if control.get_meta("command","")!="camera_view": continue
		preload("res://scripts/action_icons.gd").view(control,Profile.first_person)

func paused() -> void:
	clear_screen("pause")
	shade()
	screen_title("Пауза",243)
	screen_action("Продолжить","resume",342,true)
	screen_action("Настройки","settings",420)
	screen_action("Заново","restart",498)
	screen_action("В меню","menu",576)

func countdown(value: int, flight_countdown:bool=false) -> void:
	clear_screen("countdown")
	reset_hud(flight_countdown)
	if flight_countdown:
		view_switch_button.hide()
		run_inventory.hide()
		score_star.hide()
		for heart:TextureProgressBar in heart_slots: heart.hide()
		lives_label.show()
		run_stats.size.y=67.
	else:
		update_charges(Profile,"")
	hud.visible = true
	text(screen,str(value),104,360,150)

func settings(previous: String) -> void:
	settings_return = previous
	clear_screen("settings")
	shade()
	screen_title("Настройки")
	var labels := {"Master": "Общая громкость", "Music": "Музыка", "Effects": "Эффекты", "Voices": "Голоса"}
	var i := 0
	for bus: String in labels:
		var caption := text(screen,labels[bus],22,186+i*89,30,52,436)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var slider := HSlider.new()
		slider.set_meta("audio_bus",bus)
		slider.set_script(TouchSlider)
		slider.position = Vector2(52,219+i*89)
		slider.size = Vector2(436,40)
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
		toggle.position = Vector2(52,565+j*63)
		toggle.size = Vector2(436,54)
		toggle.add_theme_font_size_override("font_size",20)
		toggle.button_pressed = Profile.get(toggles[j][1])
		var key: String = toggles[j][1]
		toggle.toggled.connect(func(value):
			Profile.set(key, value)
			Profile.save()
			action.emit("preferences"))
		screen.add_child(toggle)
		preload("res://scripts/space_button_face.gd").attach(toggle,false,true)
	screen_action("Готово","close_settings",778,true)
	version_button=text(screen,"Версия "+str(ProjectSettings.get_setting("application/config/version","")),18,860,48,48,444,MUTED)
	version_button.mouse_filter=Control.MOUSE_FILTER_STOP
	version_button.gui_input.connect(func(event:InputEvent):
		if (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and event.device!=InputEvent.DEVICE_ID_EMULATION) or (event is InputEventScreenTouch and event.pressed):action.emit("version_tap")
	)

func results(success: bool, stars: int, score: int, _best: int, planet: int = 0) -> void:
	clear_screen("results")
	shade()
	screen_title("Вот это гонка!" if success else "Попробуем снова!")
	planet_heading(planet,176)
	var more := success and planet<Planets.count()-1
	var summary := panel(screen,520,157)
	summary.name = "RunSummary"
	summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text(summary,Crew.NAMES[Profile.hero],28,12,40,24,440)
	var stats := HBoxContainer.new()
	stats.position = Vector2(24,56)
	stats.size = Vector2(440,38)
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation",10)
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	summary.add_child(stats)
	var icon := hud_icon(stats,preload("res://assets/ui/hud-star.png"),Vector2.ZERO,Vector2(32,32))
	icon.custom_minimum_size = Vector2(32,32)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var totals := text(stats,"%d   ·   Счёт %d" % [stars,score],24,0,38,0,0,GOLD)
	totals.autowrap_mode = TextServer.AUTOWRAP_OFF
	var goal := Course.star_goal(planet)
	var goal_text := "Цель выполнена" if stars>=goal else "До цели ещё %d ★" % (goal-stars)
	text(summary,goal_text+"  ·  Рекорд %d ★" % Profile.star_records[planet],20,102,44,24,440,MINT if stars>=goal else MUTED)
	if more: screen_action("Летим на "+Planets.destination(planet+1),"next",712,true)
	var midpoint:bool=not success and float(Profile.retry_points.get(str(Profile.hero)+":"+str(planet),{}).get("distance",0.))>0.
	screen_action("С середины · 3 ♥" if midpoint else "Ещё раз","restart",790 if more else 712,not more)
	screen_action("В меню","menu",868 if more else 790)

func planets(selected: int, unlocked: int) -> void:
	clear_screen("planets")
	shade()
	screen_title("Наши планеты")
	var scroll:=preload("res://scripts/planet_scroll.gd").new(); screen.add_child(scroll)
	scroll.name="PlanetList"
	scroll.position=Vector2(28,181); scroll.size=Vector2(484,565)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus=true
	var list:=Control.new(); list.custom_minimum_size=Vector2(464,Planets.count()*94); scroll.add_child(list)
	var active_row: Button
	for i in Planets.count():
		var data:=Planets.get_data(i)
		var locked := i>unlocked
		var active := i==selected and not locked
		var cleared := Profile.cleared_planets.has(i)
		var status := "Закрыта" if locked else "Активная" if active else "Пройдена" if cleared else "Доступна"
		var accent := MUTED if locked else MINT if active else GOLD if cleared else Color("99c9ff")
		var row := button(list,"","planet_"+str(i),i*94,active,8,448,84)
		row.disabled = locked
		if active: active_row = row
		row.tooltip_text = data.name+" · "+status+(" · пройдена" if active and cleared else "")
		var number := text(row,"%02d"%[i+1],23,18,45,16,55,accent)
		number.name = "PlanetNumber"
		var name_label := text(row,data.name,24,8,34,78,220,MUTED if locked else INK)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var description := text(row,data.subtitle,17,41,27,78,233,MUTED)
		description.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var badge := panel(row,18,38,318,112)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var badge_style := badge.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		badge_style.bg_color = Color(accent,.16)
		badge_style.border_color = Color(accent,.58)
		badge_style.set_corner_radius_all(10)
		badge_style.shadow_size = 0
		badge.add_theme_stylebox_override("panel",badge_style)
		var status_label := text(badge,status,16,0,38,0,112,accent)
		status_label.name = "PlanetStatus"
		if active and cleared:
			text(row,"✓ Пройдена",13,56,20,318,112,GOLD)
	if is_instance_valid(active_row): scroll.call_deferred("ensure_control_visible",active_row)
	screen_action("Назад","select",850)

func flight_playing(can_skip: bool) -> void:
	clear_screen("flight")
	reset_hud(true)
	hud.visible=true
	charge_buttons.clear()
	button(screen,"Лазер","flight_fire",836,true,30,148,64)
	if can_skip: button(screen,"Пропустить","skip_flight",836,false,286,224,64)

func update_flight(place: int, fraction: float, route: String, seconds: float, energy: int) -> void:
	lives_label.text="МЕСТО %d/4"%place
	score_label.text="⚡ "+str(energy)
	progress_fill.size.x=480*clampf(fraction,0,1)
	stage_label.text=route.to_upper()
	booster_label.text="УСКОРЕНИЕ  ·  %.1f с" % seconds if seconds>0 else ""
	hint_label.text="Свайп вбок — сменить полосу\nСветящиеся заряды ускоряют корабль"

func flight_results(place: int, reward: int, target: int, skipped: bool) -> void:
	clear_screen("flight_result")
	shade()
	screen_title("Пора на планету!")
	planet_heading(target,176)
	panel(screen,558,120)
	text(screen,"Перелёт пропущен" if skipped else "Место %d из 4" % place,24,590 if skipped else 572,42,50,440,GOLD)
	if not skipped: text(screen,"Награда · +%d ★" % reward,20,620,48,50,440,MINT)
	screen_action("Приземляемся!","arrive",704,true)
