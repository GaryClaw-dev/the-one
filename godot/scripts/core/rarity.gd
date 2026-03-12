class_name Rarity
extends RefCounted

enum Type { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

## Colors from Art Bible
static func get_color(rarity: int) -> Color:
	match rarity:
		Type.COMMON: return Color(0.69, 0.69, 0.69)     # #B0B0B0 grey
		Type.UNCOMMON: return Color(0.3, 0.73, 0.3)      # #4CBB4C green
		Type.RARE: return Color(0.3, 0.62, 0.88)          # #4D9DE0 blue
		Type.EPIC: return Color(0.61, 0.35, 0.71)         # #9B59B6 purple
		Type.LEGENDARY: return Color(0.91, 0.77, 0.28)    # #E8C547 gold
	return Color.WHITE

static func get_rarity_name(rarity: int) -> String:
	match rarity:
		Type.COMMON: return "Common"
		Type.UNCOMMON: return "Uncommon"
		Type.RARE: return "Rare"
		Type.EPIC: return "Epic"
		Type.LEGENDARY: return "Legendary"
	return ""
