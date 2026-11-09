extends RefCounted
const B=preload("res://scripts/booster_catalog.gd")
static func body(ui:Node,p:Node,selected:String,message:String,can_buy:bool) -> String:
	if not B.KINDS.has(selected): selected="jet"
	for i in 2:
		var kind:String=B.KINDS[i]
		ui.button(ui.screen,B.TITLES[kind]+"\n%d ★ · запас %d / 9"%[B.PRICES[kind],p.charge_count(kind)],"preview_item_"+kind,280+i*120,selected==kind,306,210,100).add_theme_font_size_override("font_size",16)
	ui.text(ui.screen,"Расходуется при включении\nПодбор на трассе пополняет запас",15,615,70,24,492,Color("a7cfd5"))
	ui.panel(ui.screen,700,172,24,492)
	ui.text(ui.screen,B.TITLES[selected],25,708,42)
	var hint:="Один заряд — одно включение.\nВ принятой петле хватит до самого выхода."
	if not can_buy: hint="Купить можно в магазинах на площади"
	elif p.bank<B.PRICES[selected]: hint="Не хватает %d ★"%[B.PRICES[selected]-p.bank]
	elif p.charge_count(selected)>=B.LIMIT: hint="Запас полон: 9 зарядов"
	ui.text(ui.screen,message if not message.is_empty() else hint,16,760,90,38,464)
	var buy:Button=ui.button(ui.screen,"Купить заряд · %d ★"%B.PRICES[selected],"buy_charge_"+selected,889,true,24,360,48)
	buy.add_theme_font_size_override("font_size",18)
	buy.disabled=not can_buy or p.bank<B.PRICES[selected] or p.charge_count(selected)>=B.LIMIT
	ui.button(ui.screen,"Готово","close_gear",889,false,398,118,48).add_theme_font_size_override("font_size",16)
	return selected
