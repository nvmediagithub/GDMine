# scripts/domain/world/block_registry.gd
# Синглтон для настройки материалов и генерации
extends Node
class_name BlockRegistry

# Префабы материалов .tres (создать вручную в res://materials/)
@export var grass_material : Material
@export var dirt_material  : Material
@export var stone_material : Material
@export var coal_material  : Material

static func get_material(block_id: int) -> Material:
    match block_id:
        BlockType.ID.GRASS: return BlockRegistry.new().grass_material
        BlockType.ID.DIRT:  return BlockRegistry.new().dirt_material
        BlockType.ID.STONE: return BlockRegistry.new().stone_material
        BlockType.ID.COAL:  return BlockRegistry.new().coal_material
        _: return null

# TODO сконфигурировать в autoload (ServiceLocator) или через Project Settings