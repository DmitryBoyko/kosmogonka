extends RefCounted
const Catalog=preload("res://scripts/outfit_catalog.gd")
const Planets=preload("res://scripts/planets.gd")
static func show(ui:Node,p:Node,world:int,category:String,mode:String,selected:String,message:String,can_buy:bool,trying:bool=true) -> String:
	ui.clear_screen("shop")
	ui.text(ui.screen,"ОРБИТАЛЬНОЕ АТЕЛЬЕ",27,36,45,30,480)
	ui.text(ui.screen,Planets.get_data(world).name+" · "+("Мальчик" if p.hero==0 else "Девочка")+" · "+str(p.bank)+" ★",16,85,30,30,480,Color("ffe0a1"))
	for i in 3:
		ui.button(ui.screen,["В наличии","Мои вещи","Все планеты"][i],"shop_mode_"+["local","owned","galaxy"][i],126,mode==["local","owned","galaxy"][i],30+i*163,154,44).add_theme_font_size_override("font_size",13)
	for i in 4:
		ui.button(ui.screen,["Скафандр","Ранец","Платформа","Украшения"][i],"shop_cat_"+["suit","pack","board","badge"][i],185,category==["suit","pack","board","badge"][i],26+i*123,119,44).add_theme_font_size_override("font_size",12)
	var items:=Catalog.list_items(category,world,p.owned_items,mode)
	if not items.any(func(item): return item.id==selected): selected=items[0].id if not items.is_empty() else ""
	var scroll:=ScrollContainer.new(); ui.screen.add_child(scroll); scroll.position=Vector2(345,247); scroll.size=Vector2(173,351); scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var list:=Control.new(); list.custom_minimum_size=Vector2(156,maxi(90,items.size()*96)); scroll.add_child(list)
	for i in items.size():
		var item:Dictionary=items[i]; var equipped:bool=p.current_outfit().get(item.group,"")==item.id
		var status:String="НАДЕТО" if equipped else "КУПЛЕНО" if p.owned_items.has(item.id) else str(item.price)+" ★"
		var label:String=(str(item.name) if item.group=="badge" else Catalog.TITLES[item.group]+" "+str(item.tier))+"\n"+Planets.get_data(item.world).name+"\n"+status
		ui.button(list,label,"preview_item_"+item.id,i*96,selected==item.id,0,156,87).add_theme_font_size_override("font_size",12)
	if items.is_empty(): ui.text(list,"Здесь пока нет вещей",14,25,100,0,155)
	ui.text(ui.screen,"Потяни героя — поворот",13,607,24,30,285,Color("93b8ce"))
	ui.button(ui.screen,"−","fit_zoom_out",551,false,41,48,44)
	ui.button(ui.screen,"+","fit_zoom_in",551,false,269,48,44)
	ui.button(ui.screen,"Примерить","try_item",551,false,103,152,44).add_theme_font_size_override("font_size",14)
	var item:=Catalog.get_item(selected)
	var current:Dictionary=p.current_outfit(); var trial:=Catalog.preview(current,selected) if trying else current
	var points:int=Catalog.score(trial); var delta:int=points-Catalog.score(current)
	ui.panel(ui.screen,635,238)
	ui.text(ui.screen,item.get("name","Твой гардероб"),22,647,48,38,464,Color("e4f6ff"))
	ui.text(ui.screen,"ЭФФЕКТИВНОСТЬ  %d / 1000  (%+d)"%[points,delta],17,701,30,35,470,Color("a4eadc"))
	var scores:=Catalog.scores(trial)
	ui.text(ui.screen,"Защита %d · сбор %d · манёвр %d\nПолёт %d · платформа %d"%[scores.defense,scores.collection,scores.movement,scores.flight,scores.board],13,738,48,38,464)
	var hint:String="Продажа: "+Planets.get_data(item.world).name if not item.is_empty() and item.world!=world else "Примерка меняет только предпросмотр"
	if category=="badge" and not item.is_empty() and item.world==world: hint="Рисованная нашивка. Характеристики не меняет."
	ui.text(ui.screen,message if not message.is_empty() else hint,12,788,33,38,464,Color("a8bfce"))
	if not item.is_empty():
		var owned:bool=p.owned_items.has(selected); var equipped:bool=current.get(item.group,"")==selected
		var buy:Button=ui.button(ui.screen,"Куплено" if owned else "Купить %d ★"%item.price,"purchase_item",829,true,38,180,44)
		buy.add_theme_font_size_override("font_size",14); buy.disabled=owned or not can_buy or item.world!=world or p.bank<item.price
		var wear:Button=ui.button(ui.screen,"Надеть","wear_item",829,false,229,128,44); wear.add_theme_font_size_override("font_size",14); wear.disabled=not owned or equipped
		var remove:Button=ui.button(ui.screen,"Звезда" if category=="badge" else "Снять","remove_item",829,false,368,128,44); remove.add_theme_font_size_override("font_size",14); remove.disabled=not current.has("badge") if category=="badge" else not equipped
	ui.button(ui.screen,"Закрыть","close_gear",902,false,38,174,44).add_theme_font_size_override("font_size",16)
	ui.button(ui.screen,"Вернуть образ","restore_outfit",902,false,229,267,44).add_theme_font_size_override("font_size",16)
	return selected
