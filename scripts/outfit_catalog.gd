extends RefCounted
const GROUPS=["helmet","torso","arms","gloves","legs","boots","pack","board","badge"]
const ARMOR=["helmet","torso","arms","gloves","legs","boots"]
const TITLES={"helmet":"Шлем","torso":"Нагрудник","arms":"Наплечники","gloves":"Перчатки","legs":"Защита ног","boots":"Ботинки","pack":"Ранец","board":"Платформа","badge":"Украшение"}
const SLOTS={"helmet":["helmet"],"torso":["torso"],"arms":["left_arm","right_arm"],"gloves":["left_glove","right_glove"],"legs":["left_leg","right_leg"],"boots":["left_boot","right_boot"],"pack":["backpack"]}
const WEIGHTS={"helmet":1.2,"torso":2.,"arms":.8,"gloves":.6,"legs":.8,"boots":.6}
const COLORS=["6dded7","a7df8b","ffc77d","a696ff","6dd6ed","f4b768","db9ce6","c9eafa","f18a77","e3d28d"]
const SERIES=["Контур","Вектор","Спектр","Авангард","Горизонт"]
static var items:Dictionary={}
static func all() -> Dictionary:
	if not items.is_empty(): return items
	for g in ARMOR.size():
		var group:String=ARMOR[g]
		for tier in range(1,6):
			var world:int=(g+(tier-1)*6+1)%10
			var id:String=group+"_"+str(tier)
			var price:int=maxi(450,roundi([450,950,1650,2600,3900][tier-1]*[1.,1.25,.75,.65,.90,.80][g]/25.)*25)
			items[id]={"id":id,"group":group,"category":"suit","tier":tier,"world":world,"price":price,"color":COLORS[world],"name":TITLES[group]+" «"+SERIES[tier-1]+"»","shape":(g+world)%3}
	for world in 10:
		for category in ["pack","board"]:
			var tier:int=([5,1,3,2,4,2,5,3,4,1] if category=="pack" else [2,4,1,5,3,1,4,2,5,3])[world]
			var id:String=category+"_world_"+str(world)
			items[id]={"id":id,"group":category,"category":category,"tier":tier,"world":world,"price":[650,1250,2150,3250,4750 if category=="pack" else 4500][tier-1]+(world%3)*75,"color":COLORS[world],"name":TITLES[category]+" «"+SERIES[tier-1]+" " +str(world+1)+"»","shape":world%3}
	for world in 10:
		var id:String="badge_"+str(world)
		items[id]={"id":id,"group":"badge","category":"badge","tier":1,"world":world,"price":3500+world*750,"color":COLORS[world],"name":["Атом","Звёздный герб","Цветок","Лотос","Квант","Ракета","Планета с кольцом","Комета","Молния","Солнце"][world],"shape":10 if world==1 else world}
	for category:String in ["pack","board"]:
		var id:String=category+"_world_10"
		items[id]={"id":id,"group":category,"category":category,"tier":5,"world":10,"price":5500 if category=="pack" else 5250,"color":"9defff","name":TITLES[category]+" «Зеркальный парадокс»","shape":1 if category=="pack" else 2}
	items["badge_10"]={"id":"badge_10","group":"badge","category":"badge","tier":1,"world":10,"price":11000,"color":"bcefff","name":"Зеркальные грани","shape":11}
	return items
static func get_item(id:String) -> Dictionary: return all().get(id,{})
static func level(outfit:Dictionary,group:String) -> int:
	return int(get_item(str(outfit.get(group,""))).get("tier",0))
static func normalized(raw:Dictionary,owned:Array=[]) -> Dictionary:
	var result:Dictionary={}
	for group in GROUPS:
		var id:String=str(raw.get(group,"")); var item:=get_item(id)
		if not item.is_empty() and item.group==group and (owned.is_empty() or owned.has(id)): result[group]=id
	return result
static func legacy(levels:Dictionary) -> Dictionary:
	var result:Dictionary={}; var suit:int=clampi(int(levels.get("suit",0)),0,5)
	if suit>0:
		for group in ARMOR: result[group]=group+"_"+str(suit)
	for category in ["pack","board"]:
		for item:Dictionary in all().values():
			if item.category==category and item.tier==int(levels.get(category,0)): result[category]=item.id; break
	return result
static func levels(outfit:Dictionary) -> Dictionary:
	var total:=0.
	for group in ARMOR: total+=level(outfit,group)*float(WEIGHTS[group])
	return {"suit":total/6.,"pack":level(outfit,"pack"),"board":level(outfit,"board")}
static func stats(outfit:Dictionary) -> Dictionary:
	var tiers:=levels(outfit); var suit:float=tiers.suit; var pack:int=tiers.pack; var board:int=tiers.board
	return {"magnet":suit*.10,"tempo":1.-suit*.03,"shields":floori((suit+1.)/2.),"jet_seconds":8.+pack*.8,"lane_speed":13.+pack*.5,"rescues":2 if pack==5 else 1 if pack>=3 else 0,"board_seconds":10.+board,"board_armor":1+int(board/2),"board_magnet":board*.08}
static func scores(outfit:Dictionary) -> Dictionary:
	var tiers:=levels(outfit)
	return {"defense":roundi(tiers.suit*60.),"collection":roundi(tiers.suit*20.+tiers.board*10.),"movement":roundi(tiers.pack*20.+level(outfit,"boots")*10.),"flight":int(tiers.pack)*40,"board":int(tiers.board)*40}
static func score(outfit:Dictionary) -> int:
	var total:=0
	for value:int in scores(outfit).values(): total+=value
	return total
static func preview(outfit:Dictionary,id:String) -> Dictionary:
	var result:=outfit.duplicate(); var item:=get_item(id)
	if not item.is_empty(): result[item.group]=id
	return result
static func list_items(category:String,world:int,owned:Array,mode:String) -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for item:Dictionary in all().values():
		if item.category!=category: continue
		if mode=="local" and item.world!=world: continue
		if mode=="owned" and not owned.has(item.id): continue
		result.append(item)
	result.sort_custom(func(a,b): return a.world<b.world if mode=="galaxy" and a.world!=b.world else a.price<b.price)
	return result
