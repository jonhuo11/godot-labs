class_name LibOgat

static func clear_handlers(sig: Signal) -> int:
	var n := len(sig.get_connections())
	for handler in sig.get_connections():
		var callable = handler.callable
		sig.disconnect(callable)
	return n


static func dig(dict: Variant, keys: Array[Variant], default = null) -> Variant:
	var level = dict
	for i in range(len(keys)):
		if level == null:
			return default
		var k = keys[i]
		if level is Dictionary:
			if k not in level:
				return default
			level = level[k]
		elif level is Array:
			if (k is not int) or (abs(k) >= len(level)):
				return default
			level = level[k]
		else:
			return default
	return level
