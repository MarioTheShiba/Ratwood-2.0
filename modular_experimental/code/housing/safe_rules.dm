GLOBAL_LIST_INIT(experimental_safe_blacklist, typecacheof(list(
	/obj/item/clothing/head/roguetown/crown/serpcrown,

	/obj/item/rogueweapon/sword/long/martyr,
	/obj/item/rogueweapon/greataxe/steel/doublehead/martyr,
	/obj/item/rogueweapon/mace/goden/martyr,
	/obj/item/rogueweapon/spear/partizan/martyr
)))


/obj/item
	var/experimental_safe_persistence_override = null


/obj/item/proc/experimental_can_persist_in_safe()
	if(!isnull(experimental_safe_persistence_override))
		return experimental_safe_persistence_override

	if(is_type_in_typecache(src, GLOB.experimental_safe_blacklist))
		return FALSE

	if(istype(src, /obj/item/roguecoin))
		return FALSE

	if(istype(src, /obj/item/rogueore))
		return FALSE

	if(istype(src, /obj/item/ingot))
		return FALSE

	if(istype(src, /obj/item/stack))
		return FALSE

	if(istype(src, /obj/item/ammo_casing))
		return FALSE

	if(istype(src, /obj/item/storage))
		return FALSE

	if(istype(src, /obj/item/reagent_containers))
		return FALSE

	if(length(contents))
		return FALSE

	return TRUE
