# Scripts/Worley/coherent_noise_cell_value.gd
extends Node
class_name CoherentNoiseCellValue

# Функция генерации карты клеточного шума (cell value)
# width, height – размеры области (в пикселях)
# seeds – массив Vector2 с координатами семян
# seed_colors – Dictionary, где ключ – индекс семени, а значение – Color (цвет для этого семени)
# Возвращает изображение (Image) с заливкой каждого пикселя цветом, соответствующим ближайшему семени
func generate_cell_value_image(width: int, height: int, seeds: Array, seed_colors: Dictionary) -> Image:
	print("Creating image with width: ", width, ", height: ", height)
	var img: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	print("Image created: ", img.get_width(), " x ", img.get_height())
	
	for y in range(height):
		for x in range(width):
			var p = Vector2(x, y)
			var min_dist = INF
			var nearest_seed_index = -1
			for i in range(seeds.size()):
				var d = p.distance_to(seeds[i])
				if d < min_dist:
					min_dist = d
					nearest_seed_index = i
			# Если для данного семени нет цвета, используем белый
			var col: Color = seed_colors[nearest_seed_index] if seed_colors.has(nearest_seed_index) else Color.WHITE
			img.set_pixel(x, y, col)
	img.save_png("res://Data/test_noise.png")
	
	return img
