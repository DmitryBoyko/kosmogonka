extends Node
## Interstitial flow ported from TrueTaro (Руны Осириса), yandex_ads_manager.gd.
## Ad IDs and Android bridge availability are supplied by CosmoAds.
const LOAD_TIMEOUT_SEC := 2.0
const SHOW_TIMEOUT_SEC := 45.0
signal interstitial_flow_finished(granted: bool)
var _ads: Node
var _interstitial_waiting := false
var _interstitial_shown := false
var _interstitial_gen := 0
var last_skip_reason := ""

func setup(bridge: Node) -> void:
	_ads=bridge
	_ads.interstitial_loaded.connect(_on_interstitial_loaded)
	_ads.interstitial_failed_to_load.connect(_on_interstitial_failed_to_load)
	_ads.interstitial_closed.connect(_on_interstitial_closed)
	if _ads.has_signal("interstitial_failed_to_show"):
		_ads.interstitial_failed_to_show.connect(func(_error): call_deferred("_finish_interstitial_flow",false))

func show_interstitial() -> void:
	last_skip_reason = ""
	if _ads == null:
		call_deferred("_emit_interstitial_finished", true)
		return
	if _interstitial_waiting:
		call_deferred("_emit_interstitial_finished", false)
		last_skip_reason = "busy"
		return
	_interstitial_waiting = true
	_interstitial_shown = false
	_interstitial_gen += 1
	var gen := _interstitial_gen

	if _ads.is_interstitial_loaded():
		call_deferred("_show_interstitial_now", gen)
		return

	_ads.load_interstitial()
	var timer := get_tree().create_timer(LOAD_TIMEOUT_SEC)
	timer.timeout.connect(func() -> void:
		if gen != _interstitial_gen or not _interstitial_waiting or _interstitial_shown:
			return
		_finish_interstitial_flow(false)
	, CONNECT_ONE_SHOT)


func _on_interstitial_loaded() -> void:
	if _interstitial_waiting and not _interstitial_shown:
		call_deferred("_show_interstitial_now", _interstitial_gen)


func _on_interstitial_failed_to_load(_error_code: int) -> void:
	if _interstitial_waiting and not _interstitial_shown:
		_finish_interstitial_flow(false)


func _on_interstitial_closed() -> void:
	if not _interstitial_waiting:
		return
	call_deferred("_finish_interstitial_flow", true)


func _show_interstitial_now(gen: int) -> void:
	if gen != _interstitial_gen or not _interstitial_waiting or _interstitial_shown:
		return
	if _ads == null or not _ads.is_interstitial_loaded():
		_finish_interstitial_flow(false)
		return
	_interstitial_shown = true
	_ads.show_interstitial()
	var timer := get_tree().create_timer(SHOW_TIMEOUT_SEC)
	timer.timeout.connect(func() -> void:
		if gen != _interstitial_gen or not _interstitial_waiting:
			return
		_finish_interstitial_flow(false)
	, CONNECT_ONE_SHOT)


func _finish_interstitial_flow(_closed_normally: bool) -> void:
	if not _interstitial_waiting:
		return
	var shown := _interstitial_shown
	_interstitial_waiting = false
	_interstitial_shown = false
	_interstitial_gen += 1
	if _ads != null:
		_ads.load_interstitial()
	var granted := shown
	if not granted:
		last_skip_reason = "no_fill"
	call_deferred("_emit_interstitial_finished", granted)


func _emit_interstitial_finished(granted: bool) -> void:
	interstitial_flow_finished.emit(granted)
