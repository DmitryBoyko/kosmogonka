extends Node

const Bridge = preload("res://addons/GodotAndroidYandexAds/yandex_ads.gd")
const APP_OPEN := "R-M-20419375-3"
const BANNER := "R-M-20419375-2"
const SHOP := "R-M-20419375-1"
const REWARD_STARS := 1000
signal reward_finished(granted: bool)
signal shop_finished
var shop_flow := preload("res://scripts/shop_interstitial_flow.gd").new()

func trace_shop(stage: String) -> void:
	var line := "%s %d %s active=%s shown=%s" % [Time.get_datetime_string_from_system(),Time.get_ticks_msec(),stage,active,presentation_started]
	print("SHOP_FLOW "+line)
	var file := FileAccess.open("user://shop_flow.log",FileAccess.READ_WRITE if FileAccess.file_exists("user://shop_flow.log") else FileAccess.WRITE)
	if file:
		file.seek_end();file.store_line(line)

var bridge: YandexAds
var active := ""
var presentation_started := false
var focus_was_lost := false
var startup_deadline := 0
var shop_entries := 0
var banner_wanted := false
var banner_loading := false
var banner_ready := false
var banner_height := 0.
var reward_owner := -1
var reward_showing := false
var reward_attempt := 0
var focus_watch := 0
var earned := false
var demo := false

func _ready() -> void:
	add_child(shop_flow)
	shop_flow.interstitial_flow_finished.connect(_on_shop_finished)
	if not OS.has_feature("android") or not Engine.has_singleton("GodotAndroidYandexAds"): return
	demo = "--ads-demo" in OS.get_cmdline_user_args() or (OS.is_debug_build() and FileAccess.file_exists("user://ads_demo"))
	bridge = Bridge.new()
	bridge.app_open_id = "demo-appopenad-yandex" if demo else APP_OPEN
	bridge.banner_id = "demo-banner-yandex" if demo else BANNER
	bridge.interstitial_id = "demo-interstitial-yandex" if demo else SHOP
	bridge.rewarded_id = "demo-rewarded-yandex" if OS.is_debug_build() else ""
	bridge.banner_width = maxi(1, roundi(DisplayServer.window_get_size().x / maxf(1., DisplayServer.screen_get_dpi() / 160.)))
	bridge.banner_height = 0
	bridge.app_open_shown.connect(mark_presented)
	bridge.interstitial_shown.connect(mark_presented)
	bridge.rewarded_video_shown.connect(mark_presented)
	bridge.app_open_loaded.connect(show_open)
	bridge.app_open_closed.connect(end_open)
	bridge.app_open_failed_to_show.connect(func(_error): end_open())
	shop_flow.setup(bridge)
	bridge.banner_loaded.connect(on_banner_loaded)
	bridge.banner_failed_to_load.connect(on_banner_error)
	bridge.rewarded_video_loaded.connect(show_reward)
	bridge.rewarded_video_failed_to_load.connect(func(_error): finish_reward())
	bridge.rewarded_video_failed_to_show.connect(func(_error): finish_reward())
	bridge.rewarded_video_closed.connect(finish_reward)
	bridge.rewarded.connect(grant_reward)
	add_child(bridge)
	startup_deadline = Time.get_ticks_msec() + 3000
	bridge.load_app_open()
	bridge.load_interstitial()
	if not bridge.rewarded_id.is_empty(): bridge.load_rewarded_video()

func show_open() -> void:
	if active != "" or Time.get_ticks_msec() > startup_deadline: return
	active = "open"
	bridge.show_app_open()
	watch_ad_focus()

func cancel_startup() -> void:
	startup_deadline = 0

func end_open() -> void:
	if active == "open": active = "";presentation_started=false;focus_was_lost=false

func register_shop_entry() -> int:
	shop_entries += 1
	trace_shop("entry %d"%shop_entries)
	return shop_entries

func show_shop_ad() -> void:
	if not bridge or active != "":
		return
	# A load callback must not start an ad after the player has left the shop.
	if not bridge.is_interstitial_loaded():
		bridge.load_interstitial()
		return
	trace_shop("request interstitial")
	active="shop"
	shop_flow.show_interstitial()

func _on_shop_finished(_granted: bool) -> void:
	active=""
	presentation_started=false
	focus_was_lost=false
	trace_shop("finished")
	shop_finished.emit()

func set_flight_banner(enabled: bool) -> void:
	if not bridge or banner_wanted == enabled: return
	banner_wanted = enabled
	if not enabled:
		bridge.hide_banner()
		banner_height = 0.
	elif banner_ready:
		on_banner_loaded()
	elif not banner_loading:
		banner_loading = true
		bridge.load_banner()

func on_banner_loaded() -> void:
	banner_loading = false
	banner_ready = true
	if not banner_wanted:
		bridge.hide_banner()
		return
	bridge.show_banner()
	var height := bridge.get_banner_dimension().y
	banner_height = height if height > 0. else 50. * DisplayServer.screen_get_dpi() / 160.

func on_banner_error(_code: int) -> void:
	banner_loading = false
	banner_ready = false
	bridge.hide_banner()
	banner_height = 0.

func request_reward() -> bool:
	if not bridge or active != "" or bridge.rewarded_id.is_empty(): return false
	active = "reward"
	reward_owner = Profile.hero
	earned = false
	reward_attempt += 1
	if bridge.is_rewarded_video_loaded(): show_reward()
	else:
		bridge.load_rewarded_video()
		var attempt := reward_attempt
		get_tree().create_timer(6.).timeout.connect(func():
			if active == "reward" and attempt == reward_attempt and not reward_showing: finish_reward())
	return true

func show_reward() -> void:
	if active != "reward" or reward_owner < 0 or reward_showing: return
	reward_showing = true
	bridge.show_rewarded_video()
	watch_ad_focus()

func is_presenting() -> bool:
	return not active.is_empty() and presentation_started

func mark_presented() -> void:
	if not active.is_empty():presentation_started=true
	if active=="shop":trace_shop("native shown callback")

func _notification(what: int) -> void:
	if active.is_empty() or active=="shop":return

	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:focus_was_lost=true
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_RESUMED] and focus_was_lost:
		finish_after_focus_return(focus_watch,active)

func finish_after_focus_return(watch: int,format: String) -> void:
	# Allow the SDK's reward/dismiss callbacks to finish first.
	await get_tree().create_timer(.5).timeout
	if watch==focus_watch and active==format:end_current_ad()

func end_current_ad() -> void:
	match active:
		"open":end_open()
		"reward":finish_reward()

func watch_ad_focus() -> void:
	focus_watch += 1
	var watch := focus_watch
	var format := active
	await get_tree().create_timer(5.).timeout
	# A failed native show must never freeze the shop indefinitely.
	if watch==focus_watch and active==format and not presentation_started and not focus_was_lost:
		end_current_ad()

func grant_reward(_currency: String, _amount: int) -> void:
	if active != "reward" or earned: return
	var previous := int(Profile.wallets.get(str(reward_owner), 0))
	Profile.credit(REWARD_STARS, reward_owner)
	earned = Profile.save() == OK
	if not earned: Profile.wallets[str(reward_owner)] = previous

func finish_reward() -> void:
	if active != "reward": return
	active = ""
	presentation_started=false;focus_was_lost=false
	reward_showing = false
	reward_owner = -1
	reward_finished.emit(earned)
	bridge.load_rewarded_video()
