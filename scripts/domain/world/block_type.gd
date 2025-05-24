# scripts/domain/world/block_type.gd
# Определение типов блоков
extends Resource
class_name BlockType

enum ID {
    EMPTY = 0,
    GRASS = 1,
    DIRT  = 2,
    STONE = 3,
    COAL  = 4,
}