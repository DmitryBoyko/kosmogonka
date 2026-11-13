extends RefCounted
const B=preload("res://scripts/booster_catalog.gd")
static func body(ui:Node,p:Node,selected:String,message:String,can_buy:bool) -> String:
	var items:Array=["jet","board","heart"]
	if not items.has(selected):selected="jet"
	for i in items.size():
		var kind:String=items[i];var heart:bool=kind=="heart"
		var title:String="♥ Запасное сердце" if heart else B.TITLES[kind]
		var price:int=p.HEART_PRICE if heart else B.PRICES[kind]
		var count:int=p.heart_count() if heart else p.charge_count(kind)
		var limit:int=p.HEART_LIMIT if heart else B.LIMIT
		ui.button(ui.screen,title+"\n%d ★ · запас %d / %d"%[price,count,limit],"preview_item_"+kind,240+i*110,selected==kind,306,210,96).add_theme_font_size_override("font_size",16)
	var heart:bool=selected=="heart"
	var price:int=p.HEART_PRICE if heart else B.PRICES[selected]
	var count:int=p.heart_count() if heart else p.charge_count(selected)
	var limit:int=p.HEART_LIMIT if heart else B.LIMIT
	ui.text(ui.screen,"Запасы принадлежат выбранному герою",15,615,70,24,492,Color("a7cfd5"))
	ui.panel(ui.screen,700,172,24,492)
	ui.text(ui.screen,"♥ Запасное сердце" if heart else B.TITLES[selected],25,708,42)
	var hint:String="Автоматически вернёт 1 ♥ после удара.\nСохраняется до использования · максимум 3." if heart else "Один заряд — одно включение.\nВ петле хватит до самого выхода."
	if not can_buy: hint="Купить можно в магазинах на площади"
	elif p.bank<price: hint="Не хватает %d ★"%[price-p.bank]
	elif count>=limit: hint="Запас полон: %d"%limit
	ui.text(ui.screen,message if not message.is_empty() else hint,16,760,90,38,464)
	var buy:Button=ui.button(ui.screen,"Купить · %d ★"%price,"buy_heart" if heart else "buy_charge_"+selected,881,true,24,238,58)
	buy.add_theme_font_size_override("font_size",20)
	buy.disabled=not can_buy or p.bank<price or count>=limit
	ui.button(ui.screen,"Готово","close_gear",881,false,278,238,58).add_theme_font_size_override("font_size",20)
	return selected
