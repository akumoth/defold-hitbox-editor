local const

const = {
	HITBOX_COLORS = {
		hitbox = vmath.vector4(255/255, 204/255, 204/255, 1),
		hurtbox = vmath.vector4(204/255, 255/255, 204/255, 1),
		grabbox = vmath.vector4(204/255, 204/255, 255/255, 1)
	},

	HITBOX_BORDER_COLORS = {
		hitbox = vmath.vector4(204/255, 153/255, 153/255, 1),
		hurtbox = vmath.vector4(153/255, 204/255, 153/255, 1),
		grabbox = vmath.vector4(153/255, 153/255, 204/255, 1)
	},

	FRAME_STATE = {"INACTIVE", "STARTUP", "ACTIVE", "RECOVERY"},
	HITBOX_TYPE = {"hurtbox", "hitbox", "grabbox"},
	HITBOX_TYPE_IDX = {hurtbox=1, hitbox=2, grabbox=3},
	FRAME_VIEW_STATE = {"ALL", "NEW FRAME + HITBOX", "ONLY NEW FRAME", "ONLY W/HITBOX"},
	HITBOX_ATTRS = {"angle", "knockback", "is_clashable", "is_collision", "damage"}
}

return const