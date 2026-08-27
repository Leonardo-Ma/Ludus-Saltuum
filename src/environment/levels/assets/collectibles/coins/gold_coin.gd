extends Collectible


func _child_ready() -> void:
	collect_sounds = [
		preload("uid://cwptti4mle3g0"),  # coin.wav
		preload("uid://dgdotgk6kwxi"),  # coin_3.wav
		preload("uid://luy8ck7csy0q"),  # coin_4.wav
		preload("uid://ckl5fl1a1sq0w"),  # coin_collect.wav
	]
