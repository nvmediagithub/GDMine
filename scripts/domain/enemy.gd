class_name Enemy

var health := 50

func take_damage(amount: int) -> void:
    health = max(health - amount, 0)
