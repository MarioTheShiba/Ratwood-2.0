/datum/job/roguetown/banker
	title = "Banker"
	department_flag = YEOMEN
	faction = "Station"

	total_positions = 0
	spawn_positions = 0

	selection_color = JCOLOR_YEOMAN
	allowed_races = ACCEPTED_RACES
	allowed_sexes = list(MALE, FEMALE)
	allowed_ages = list(AGE_ADULT, AGE_MIDDLEAGED, AGE_OLD)

	tutorial = "You are a banker entrusted with the keeping of accounts, loans, deposits, and the financial records of the city. Your work is conducted through the municipal banking system, and the security of its records is your responsibility."

	display_order = JDO_EXPERIMENTAL_BANKER
	social_rank = SOCIAL_RANK_YEOMAN

	outfit = /datum/outfit/job/roguetown/banker

	give_bank_account = 22
	min_pq = 70
	max_pq = null
	round_contrib_points = 2

	job_traits = list(
		TRAIT_SEEPRICES,
	)

	job_subclasses = list(
		/datum/advclass/banker
	)


/datum/advclass/banker
	name = "Banker"
	tutorial = "You are a banker entrusted with the keeping of accounts, loans, deposits, and the financial records of the settlement."

	category_tags = list(CTAG_EXPERIMENTAL_BANKER)

	subclass_stats = list(
		STATKEY_INT = 2,
		STATKEY_PER = 2,
		STATKEY_LCK = 1,
		STATKEY_STR = -1,
	)

	subclass_skills = list(
		/datum/skill/misc/reading = SKILL_LEVEL_EXPERT,
		/datum/skill/combat/knives = SKILL_LEVEL_NOVICE,
		/datum/skill/combat/unarmed = SKILL_LEVEL_NOVICE,
		/datum/skill/combat/wrestling = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/medicine = SKILL_LEVEL_NOVICE,
		/datum/skill/craft/cooking = SKILL_LEVEL_NOVICE,
		/datum/skill/misc/athletics = SKILL_LEVEL_NOVICE,
	)

	outfit = /datum/outfit/job/roguetown/banker/basic


/datum/outfit/job/roguetown/banker
	job_bitflag = NONE


/datum/outfit/job/roguetown/banker/basic/pre_equip(mob/living/carbon/human/H)
	..()

	H.adjust_blindness(-3)

	if(should_wear_femme_clothes(H))
		shirt = /obj/item/clothing/suit/roguetown/shirt/dress/silkdress/steward
	else if(should_wear_masc_clothes(H))
		shirt = /obj/item/clothing/suit/roguetown/shirt/undershirt/guard
		pants = /obj/item/clothing/under/roguetown/tights/random
		armor = /obj/item/clothing/suit/roguetown/shirt/tunic/silktunic

	shoes = /obj/item/clothing/shoes/roguetown/shortboots
	belt = /obj/item/storage/belt/rogue/leather
	backr = /obj/item/storage/backpack/rogue/satchel
	beltr = /obj/item/storage/belt/rogue/pouch/coins/mid
	id = /obj/item/scomstone/bad
