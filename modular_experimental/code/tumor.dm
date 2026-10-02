/mob/living/simple_animal/tumor
	name = "The Watcher"
	desc = "A vast mass of living flesh, arcyne machinery, and civic apparatus. It watches in thoughtful silence."
	gender = NEUTER
	density = TRUE
	anchored = TRUE
	// he fat
	move_resist = MOVE_FORCE_OVERPOWERING
	status_flags = 0
	mob_size = MOB_SIZE_LARGE
	health = 1000
	maxHealth = 1000

	// supposed to be player countrolled
	wander = FALSE
	stop_automated_movement = TRUE
	can_have_ai = FALSE
	AIStatus = AI_OFF

	// he a blob of flesh he can't exactly fight.
	melee_damage_lower = 0
	melee_damage_upper = 0
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	base_intents = list(/datum/intent/use)

	// maybe give him random gurgles and stuff eventually?
	speak_chance = 0
	speak_emote = list("states")
	emote_hear = null
	emote_see = null

	// it's a living machine pretty much, not an animal. (at least not externally)
	food_type = null
	pooptype = null

	// decent natural vision for its chamber
	see_in_dark = 8
	faction = list("overseer")


/mob/living/simple_animal/tumor/Initialize(mapload)
	. = ..()

	// for now we give it some helping traits
	ADD_TRAIT(src, TRAIT_NOBREATH, TRAIT_GENERIC)
	ADD_TRAIT(src, TRAIT_NOHUNGER, TRAIT_GENERIC)
	ADD_TRAIT(src, TRAIT_NOMOOD, TRAIT_GENERIC)

	// make absolutely doubly sure nothing tries to wake its AI up.
	AIStatus = AI_OFF
	can_have_ai = FALSE


/mob/living/simple_animal/tumor/Move(atom/newloc, direct = 0, glide_size_override = 0)
	// the tumor's 'body' is permanently incorporated into its apparatus.
	return FALSE
