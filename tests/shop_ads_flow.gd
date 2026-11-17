extends SceneTree

class FakeAds extends YandexAds:
	var shows := 0
	var loads := 0
	func _enter_tree():pass
	func show_interstitial():shows+=1
	func load_interstitial():loads+=1

func _initialize():call_deferred("run")

func run():
	var ads=root.get_node("CosmoAds")
	var fake=FakeAds.new()
	root.add_child(fake);ads.bridge=fake;ads.shop_flow.setup(fake)
	assert(ads.register_shop_entry()==1)
	assert(fake.shows==0)
	assert(ads.register_shop_entry()==2)
	ads.show_shop_ad()
	assert(fake.shows==0 and fake.loads==1 and ads.active=="")
	# A creative loaded after a skipped visit must not interrupt the player.
	fake._is_interstitial_loaded=true
	fake.interstitial_loaded.emit()
	await process_frame
	assert(fake.shows==0)
	assert(ads.register_shop_entry()==3)
	assert(ads.register_shop_entry()==4)
	ads.show_shop_ad()
	await process_frame;await process_frame
	assert(fake.shows==1 and ads.active=="shop")
	fake.interstitial_closed.emit()
	await ads.shop_finished
	assert(ads.active=="" and not ads.shop_flow._interstitial_waiting)
	var old:int=ads.shop_flow._interstitial_gen
	assert(ads.register_shop_entry()==5)
	assert(ads.register_shop_entry()==6)
	ads.show_shop_ad();await process_frame;await process_frame
	ads.shop_flow._show_interstitial_now(old)
	assert(fake.shows==2)
	fake.interstitial_failed_to_show.emit("native show failure")
	await ads.shop_finished
	assert(ads.active=="" and not ads.shop_flow._interstitial_waiting)
	# A late close callback cannot complete a new odd entry or re-open a scene.
	fake.interstitial_closed.emit()
	ads.bridge=null;fake.queue_free()
	print("SHOP ADS PASS: registration, cold and late load, close, stale generation, show failure")
	quit()
