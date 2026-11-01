extends Control
## Code-native decorative interface lines; does not intercept touch.
func _draw() -> void:
	var w := size.x
	var h := size.y
	for x in [20.0, w - 20.0]:
		draw_line(Vector2(x, 35), Vector2(x, 95), Color("6acbcf"), 1)
		draw_line(Vector2(x, h - 35), Vector2(x, h - 90), Color("6acbcf"), 1)
	for i in 7:
		var p := Vector2(38 + i * (w - 76) / 6, 28)
		draw_circle(p, 1.5, Color("a3b1d1"))
	draw_line(Vector2(35, h - 28), Vector2(w - 35, h - 28), Color(0.5, 0.8, 0.9, 0.2), 1)
