extends RefCounted
const B=preload("res://scripts/booster_catalog.gd")
const Catalog=preload("res://scripts/outfit_catalog.gd")
static func body(ui:Node,p:Node,selected:String,message:String,can_buy:bool,flat:Callable) -> String:
	var items:Array=["jet","board","heart"]
	if not items.has(selected):selected="jet"
	for i in items.size():
		var kind:String=items[i];var heart:bool=kind=="heart"
		var title:String="♥ Запасное сердце" if heart else B.TITLES[kind]
		var price:int=p.HEART_PRICE if heart else B.PRICES[kind]
		var count:int=p.heart_count() if heart else p.charge_count(kind)
		var limit:int=p.heart_purchase_limit() if heart else B.LIMIT
		flat.call(ui,ui.screen,title+"\n%d ★ · %d / %d"%[price,count,limit],"preview_item_"+kind,306,240+i*110,210,96,selected==kind,16)
	var heart:bool=selected=="heart"
	var price:int=p.HEART_PRICE if heart else B.PRICES[selected]
	var count:int=p.heart_count() if heart else p.charge_count(selected)
	var limit:int=p.heart_purchase_limit() if heart else B.LIMIT
	ui.text(ui.screen,"♥ Запасное сердце" if heart else B.TITLES[selected],25,646,46)
	var hint := ""
	if heart:
		var outfit: Dictionary = p.current_outfit()
		var weakest := Catalog.weakest_armor(outfit)
		var level := Catalog.level(outfit,weakest)
		hint = "Лимит %d ♥ · %s %d ур."%[limit,Catalog.TITLES[weakest],level]
		if level<12: hint += "\nСледующее сердце · все детали %d ур."%maxi(6,level+1)
	if count>=limit: hint = "Лимит покупки · %d%s"%[limit," ♥" if heart else ""]
	elif p.bank<price: hint = "Не хватает %d ★"%[price-p.bank]
	ui.text(ui.screen,message if not message.is_empty() else hint,17,696,87,38,464)
	var buy:Button=flat.call(ui,ui.screen,"Купить · %d ★"%price,"buy_heart" if heart else "buy_charge_"+selected,24,881,238,58,true,20)
	buy.disabled=not can_buy or p.bank<price or count>=limit
	return selected
