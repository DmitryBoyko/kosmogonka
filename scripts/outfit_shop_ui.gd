extends RefCounted
const Catalog=preload("res://scripts/outfit_catalog.gd")
const Planets=preload("res://scripts/planets.gd")
static func show(ui:Node,p:Node,world:int,category:String,mode:String,selected:String,message:String,can_buy:bool,trying:bool=true,details:bool=false) -> String:
	var saved_scroll:Dictionary=ui.get_meta("shop_scroll",{})
	for old:Node in ui.screen.get_children():
		if old is ScrollContainer and old.has_meta("catalog_key"): saved_scroll[old.get_meta("catalog_key")]=old.scroll_vertical
	ui.set_meta("shop_scroll",saved_scroll)
	ui.clear_screen("shop")
	ui.text(ui.screen,"ОРБИТАЛЬНОЕ АТЕЛЬЕ",25,30,40)
	ui.text(ui.screen,Planets.get_data(world).name+" · "+preload("res://scripts/crew.gd").NAMES[p.hero]+" · %d ★"%p.bank,17,78,32,24,492,Color("ffe0a1"))
	for i in 5:
		ui.button(ui.screen,["Скафандр","Ранец","Доска","Нашивки","Запасы"][i],"shop_cat_"+["suit","pack","board","badge","boost"][i],128,category==["suit","pack","board","badge","boost"][i],24+i*100,92,48).add_theme_font_size_override("font_size",13)
	if category=="boost": return preload("res://scripts/booster_shop_ui.gd").body(ui,p,selected,message,can_buy)
	ui.button(ui.screen,"Мои вещи" if mode!="owned" else "Магазин","shop_mode_owned" if mode!="owned" else "shop_mode_local",190,mode=="owned",24,238,48).add_theme_font_size_override("font_size",16)
	ui.button(ui.screen,"Эта планета" if mode=="galaxy" else "Каталог планет","shop_mode_local" if mode=="galaxy" else "shop_mode_galaxy",190,mode=="galaxy",278,238,48).add_theme_font_size_override("font_size",16)
	var items:=Catalog.list_items(category,world,p.owned_items,mode)
	if not items.any(func(item):return item.id==selected): selected=items[0].id if not items.is_empty() else ""
	var key:=str(p.hero)+":"+category+":"+mode
	var scroll:=ScrollContainer.new(); ui.screen.add_child(scroll); scroll.position=Vector2(306,260); scroll.size=Vector2(210,350); scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; scroll.set_meta("catalog_key",key)
	var list:=Control.new(); list.custom_minimum_size=Vector2(190,maxi(90,items.size()*104)); scroll.add_child(list)
	for i in items.size():
		var item:Dictionary=items[i]; var owned:bool=p.owned_items.has(item.id)
		var equipped:bool=p.current_outfit().get(item.group,"")==item.id
		var title:String=str(item.name) if owned else "? "+Catalog.TITLES[item.group]+" · "+str(item.tier)
		var status:String="НАДЕТО" if equipped else "КУПЛЕНО" if owned else str(item.price)+" ★"
		var label:String=title+"\n"+Planets.get_data(item.world).name+" · "+status
		ui.button(list,label,"preview_item_"+item.id,i*104,selected==item.id,0,190,96).add_theme_font_size_override("font_size",14)
	if items.is_empty(): ui.text(list,"Пока пусто\nВыбери магазин",16,25,100,0,190)
	scroll.set_deferred("scroll_vertical",int(saved_scroll.get(key,0)))
	ui.button(ui.screen,"Обзор","fit_reset",551,false,42,220,48).add_theme_font_size_override("font_size",15)
	ui.text(ui.screen,"Потяни — поворот · щипок — масштаб",12,614,30,24,492,Color("93b8ce"))
	var item:=Catalog.get_item(selected)
	var owned:bool=p.owned_items.has(selected)
	var current:Dictionary=p.current_outfit()
	var trial:=Catalog.preview(current,selected) if trying else current
	var points:int=Catalog.score(trial); var delta:int=points-Catalog.score(current)
	ui.panel(ui.screen,650,228,24,492)
	var title:String=item.get("name","Твой гардероб") if owned else "? "+Catalog.TITLES.get(item.get("group",""),"Новая вещь")
	ui.text(ui.screen,title,21,658,43,38,464)
	ui.text(ui.screen,"Эффективность  %d / 1000  (%+d)"%[points,delta],17,705,30,32,476,Color("a4eadc"))
	ui.button(ui.screen,"Скрыть свойства" if details else "Свойства","shop_details",743,false,38,214,48).add_theme_font_size_override("font_size",15)
	var equipped:bool=not item.is_empty() and current.get(item.group,"")==selected
	if equipped: ui.button(ui.screen,"Вернуть звезду" if category=="badge" else "Снять","remove_item",743,false,270,232,48).add_theme_font_size_override("font_size",15)
	var hint:="Выбери вещь в списке"
	if not item.is_empty():
		if owned: hint="Надето" if equipped else "Куплено · можно надеть"
		elif item.world!=world: hint="Продажа: "+Planets.get_data(item.world).name+(" · ещё не открыта" if item.world>p.unlocked else " · выбери её в меню планет")
		elif not can_buy: hint="Покупка — в магазине на площади"
		elif p.bank<item.price: hint="Не хватает %d ★"%[item.price-p.bank]
		else: hint="Облик — сюрприз после покупки"
		if category=="badge": hint+=" · без усилений"
	if details:
		var scores:=Catalog.scores(trial)
		hint="Защита %d · сбор %d · манёвр %d\nПолёт %d · доска %d"%[scores.defense,scores.collection,scores.movement,scores.flight,scores.board]
	ui.text(ui.screen,message if not message.is_empty() else hint,14,798,69,38,464,Color("b8cedb"))
	var label:="Выбери вещь" if item.is_empty() else "Надето" if equipped else "Надеть" if owned else "Купить · %d ★"%item.get("price",0)
	var action:String="wear_item" if owned else "purchase_item"
	var primary:Button=ui.button(ui.screen,label,action,889,true,24,360,48)
	primary.add_theme_font_size_override("font_size",18)
	primary.disabled=item.is_empty() or equipped or (not owned and (not can_buy or item.world!=world or item.world>p.unlocked or p.bank<item.price))
	ui.button(ui.screen,"Готово","close_gear",889,false,398,118,48).add_theme_font_size_override("font_size",16)
	return selected
