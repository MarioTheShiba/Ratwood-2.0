
/obj/item
	/*
	 * null  = use normal housing rules
	 * TRUE  = explicitly allow persistence
	 * FALSE = explicitly deny persistence
	 *
	 * Useful for strange edge cases without bloating the blacklist.
	 */
	var/experimental_property_persistence_override = null


/obj/item/proc/experimental_can_persist_in_property()
	if(!isnull(experimental_property_persistence_override))
		return experimental_property_persistence_override

	/*
	 * money absolutely does not belong in DMM persistence.
	 * Persistent money belongs in banking.
	 */
	if(istype(src, /obj/item/roguecoin))
		return FALSE


	if(istype(src, /obj/item/rogueore))
		return FALSE

	if(istype(src, /obj/item/ingot))
		return FALSE

	if(istype(src, /obj/item/stack))
		return FALSE


	if(istype(src, /obj/item/rogueweapon))
		return FALSE

	if(istype(src, /obj/item/ammo_casing))
		return FALSE


	if(istype(src, /obj/item/storage))
		return FALSE


	if(istype(src, /obj/item/reagent_containers))
		return FALSE


	if(istype(src, /obj/item/clothing))
		var/obj/item/clothing/C = src

		if(C.armor_class != ARMOR_CLASS_NONE)
			return FALSE

	return TRUE
