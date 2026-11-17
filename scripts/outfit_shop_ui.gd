extends RefCounted

const Catalog = preload("res://scripts/outfit_catalog.gd")
const Planets = preload("res://scripts/planets.gd")
const CATEGORIES = ["suit","pack","board","badge","boost"]
const COLORS = {"normal":"345d91","hover":"477db0","pressed":"2d77ab","disabled":"373f59","focus":"ffe272"}
static var button_finish: ShaderMaterial

static func flat(ui: Node, parent: Node, title: String, command: String, x: float, y: float, width: float, height: float, selected: bool=false, font_size: int=18) -> Button:
	var button: Button = ui.button(parent,title,command,y,selected,x,width,height,false)
	if title=="↶": button.text = title
	button.tooltip_text = ""
	button.add_theme_font_size_override("font_size",font_size)
	for state: String in COLORS:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("137c69" if state=="normal" and selected else "365269" if state=="normal" and command=="shop_reward" else COLORS[state])
		style.set_corner_radius_all(7)
		if state=="focus":
			style.draw_center = false
			style.border_color = Color(COLORS[state])
			style.set_border_width_all(2)
		button.add_theme_stylebox_override(state,style)
	if not button_finish:
		button_finish=ShaderMaterial.new()
		button_finish.shader=preload("res://assets/ui/shop_button_finish.gdshader")
		button_finish.set_shader_parameter("alloy",preload("res://assets/salvage/hull-ceramic-v1.png"))
	var texture := ColorRect.new()
	texture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture.show_behind_parent=true
	texture.material=button_finish
	button.add_child(texture)
	texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture.offset_left=5.
	texture.offset_right=-5.
	texture.offset_top=4.
	texture.offset_bottom=-4.
	return button

static func show(ui:Node,p:Node,world:int,category:String,mode:String,selected:String,message:String,can_buy:bool,_trying:bool=true,_details:bool=false) -> String:
	var saved_scroll: Dictionary=ui.get_meta("shop_scroll",{})
	for old: Node in ui.screen.get_children():
		if old is ScrollContainer and old.has_meta("catalog_key"): saved_scroll[old.get_meta("catalog_key")] = old.scroll_vertical
	ui.clear_screen("shop")
	ui.set_meta("shop_scroll",saved_scroll)
	ui.screen_title("Магазин",24,31)
	ui.text(ui.screen,"%d ★"%p.bank,25,77,37,30,480,ui.GOLD)
	for i in CATEGORIES.size():
		flat(ui,ui.screen,["Броня","Ранец","Доска","Знаки","Запас"][i],"shop_cat_"+CATEGORIES[i],20+i*101,125,96,52,category==CATEGORIES[i],17)
	flat(ui,ui.screen,"↶","fit_reset",28,546,58,48)
	var reward := flat(ui,ui.screen,"Реклама · +1000 ★","shop_reward",24,811,492,53,false,20)
	reward.disabled = CosmoAds.active == "reward" or (OS.has_feature("android") and not OS.is_debug_build())
	flat(ui,ui.screen,"Готово","close_gear",278,881,238,58,false,20)
	if category=="boost": return preload("res://scripts/booster_shop_ui.gd").body(ui,p,selected,message,can_buy,flat)

	var modes := ["local","owned","galaxy"]
	for i in modes.size():
		flat(ui,ui.screen,["Здесь","Мои","Все"][i],"shop_mode_"+modes[i],24+i*168,190,156,48,mode==modes[i])
	var items := Catalog.list_items(category,world,p.owned_items,mode)
	var group: String = ui.get_meta("shop_armor", "helmet")
	if category=="suit":
		if not items.any(func(item: Dictionary) -> bool: return item.group == group) and not items.is_empty() and not ui.has_meta("shop_armor"):
			group=items[0].group
		for i in Catalog.ARMOR.size():
			var part: String = Catalog.ARMOR[i]
			flat(ui,ui.screen,["Шлем","Грудь","Плечи","Перчатки","Ноги","Обувь"][i],"shop_part_"+part,24+(i%3)*165,245+(i/3)*47,156,44,part==group,16)
		items = items.filter(func(item: Dictionary) -> bool: return item.group == group)
	if not items.any(func(item: Dictionary) -> bool: return item.id==selected): selected=items[0].id if not items.is_empty() else ""
	var key := "%d:%s:%s:%s"%[p.hero,category,mode,group]
	var top := 342 if category=="suit" else 255
	var scroll := preload("res://scripts/planet_scroll.gd").new()
	ui.screen.add_child(scroll)
	scroll.position=Vector2(306,top)
	scroll.size=Vector2(210,617-top)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus=true
	scroll.set_meta("catalog_key",key)
	var list := Control.new()
	list.custom_minimum_size=Vector2(198,maxi(85,items.size()*76))
	scroll.add_child(list)
	for i in items.size():
		var item: Dictionary = items[i]
		var owned: bool = p.owned_items.has(item.id)
		var equipped: bool = p.current_outfit().get(item.group,"")==item.id
		var status: String = "Надето" if equipped else "Куплено" if owned else "%d ★"%item.price
		var title: String = "%d ур. · %s"%[item.tier,status] if category=="suit" else "%s\n%s"%[item.name,status]
		flat(ui,list,title,"preview_item_"+item.id,0,i*76,198,69,item.id==selected,16)
	if items.is_empty(): ui.text(list,"Нет предметов",17,20,44,0,198)
	scroll.set_deferred("scroll_vertical",int(saved_scroll.get(key,0)))
	var item := Catalog.get_item(selected)
	var owned: bool = p.owned_items.has(selected)
	var equipped: bool = not item.is_empty() and p.current_outfit().get(item.group,"")==selected
	var status := message
	if items.is_empty() and status.is_empty() and mode=="local":
		status = "Другие планеты — во вкладке «Все»"
	if status.is_empty() and not item.is_empty():
		if equipped: status = "Надето"
		elif owned: status = "Куплено"
		elif item.world!=world: status = "Продажа · "+Planets.get_data(item.world).name
		elif p.bank<item.price: status = "Не хватает %d ★"%[item.price-p.bank]
	ui.text(ui.screen,item.get("name",""),23,646,46,24,492)
	ui.text(ui.screen,status,17,696,43,24,492,ui.MINT)
	if equipped: flat(ui,ui.screen,"Снять","remove_item",351,748,165,46)
	var title := "Купить · %d ★"%item.get("price",0) if not owned else "Надеть"
	if item.is_empty(): title = "Купить"
	var primary := flat(ui,ui.screen,title,"wear_item" if owned else "purchase_item",24,881,238,58,true,20)
	primary.disabled=item.is_empty() or equipped or (not owned and (not can_buy or item.world!=world or item.world>p.unlocked or p.bank<item.price))
	return selected
