class_name Rarity
extends RefCounted

enum Type { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

static func get_color(rarity: int) -> Color:
	match rarity:
		Type.COMMON: return Color.WHITE
		Type.UNCOMMON: return Color(0.2, 0.8, 0.2)
		Type.RARE: return Color(0.3, 0.5, 1.0)
		Type.EPIC: return Color(0.7, 0.3, 0.9)
		Type.LEGENDARY: return Color(1.0, 0.84, 0.0)
	return Color.WHITE

static func get_name(rarity: int) -> String:
	match rarity:
		Type.COMMON: return "Common"
		Type.UNCOMMON: return "Uncommon"
		Type.RARE: return "Rare"
		Type.EPIC: return "Epic"
		Type.LEGENDARY: return "Legendary"
	return ""
