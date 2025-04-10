class_name Player

var health := 100
var experience := 0

func take_damage(amount: int) -> void:
    health = max(health - amount, 0)
