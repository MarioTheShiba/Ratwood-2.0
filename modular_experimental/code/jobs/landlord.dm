/datum/job/roguetown/landlord
	title = "Landlord"
	department_flag = YEOMEN
	faction = "Station"

	total_positions = 0
	spawn_positions = 0

	selection_color = JCOLOR_YEOMAN
	allowed_races = ACCEPTED_RACES
	allowed_sexes = list(MALE, FEMALE)
	allowed_ages = list(AGE_ADULT, AGE_MIDDLEAGED, AGE_OLD)

	tutorial = "You oversee the city's properties and tenancies. You keep track of vacant homes, tenants, rent, and the lawful transfer or repossession of property."

	display_order = JDO_EXPERIMENTAL_LANDLORD
	social_rank = SOCIAL_RANK_YEOMAN

	outfit = /datum/outfit/job/roguetown/landlord

	give_bank_account = 20
	min_pq = 60
	max_pq = null
	round_contrib_points = 2

	job_traits = list(
		TRAIT_SEEPRICES,
		TRAIT_CICERONE,
	)

	job_subclasses = list(
		/datum/advclass/landlord
	)


/datum/advclass/landlord
	name = "Landlord"
	tutorial = "You oversee the city's properties and tenancies."

	category_tags = list(CTAG_EXPERIMENTAL_LANDLORD)

	subclass_stats = list(
		STATKEY_INT = 1,
		STATKEY_PER = 2,
		STATKEY_WIL = 1,
	)

	subclass_skills = list(
		/datum/skill/misc/reading = SKILL_LEVEL_EXPERT,
		/datum/skill/combat/knives = SKILL_LEVEL_NOVICE,
		/datum/skill/combat/unarmed = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/wrestling = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/medicine = SKILL_LEVEL_NOVICE,
		/datum/skill/misc/athletics = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/climbing = SKILL_LEVEL_NOVICE,
	)

	outfit = /datum/outfit/job/roguetown/landlord/basic


/datum/outfit/job/roguetown/landlord
	job_bitflag = NONE


/datum/outfit/job/roguetown/landlord/basic/pre_equip(mob/living/carbon/human/H)
	..()

	H.adjust_blindness(-3)

	head = /obj/item/clothing/head/roguetown/nightman
	shoes = /obj/item/clothing/shoes/roguetown/boots
	belt = /obj/item/storage/belt/rogue/leather/black
	shirt = /obj/item/clothing/suit/roguetown/shirt/tunic/purple
	pants = /obj/item/clothing/under/roguetown/trou/leather
	backl = /obj/item/storage/backpack/rogue/satchel
	beltr = /obj/item/storage/belt/rogue/pouch/coins/mid
	id = /obj/item/scomstone/bad

	if(should_wear_masc_clothes(H))
		armor = /obj/item/clothing/suit/roguetown/armor/leather/vest/sailor/nightman
	else if(should_wear_femme_clothes(H))
		cloak = /obj/item/clothing/cloak/matron
		armor = /obj/item/clothing/suit/roguetown/armor/armordress/alt
