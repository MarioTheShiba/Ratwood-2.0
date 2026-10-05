/*
 * Experimental Housing
 * Property item persistence rules.
 *
 * Ordinary loose items may persist unless they belong to a broad
 * economically or mechanically valuable category.
 *
 * Saved loose items are ATC sealed when serialized so they cannot
 * be repeatedly exported through the Navigator.
 *
 * Safes will use their own stricter rules later.
 */


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

	/*
	 * rraw economic resources.
	 */
	if(istype(src, /obj/item/rogueore))
		return FALSE

	if(istype(src, /obj/item/ingot))
		return FALSE

	if(istype(src, /obj/item/stack))
		return FALSE

	/*
	 * weapons and ammunition.
	 *
	 * safes may eventually allow selected weapons through their
	 * separate persistence system.
	 */
	if(istype(src, /obj/item/rogueweapon))
		return FALSE

	if(istype(src, /obj/item/ammo_casing))
		return FALSE

	/*
	 * filled storage is deliberately not part of ordinary room
	 * persistence. Otherwise a harmless bag becomes a way to smuggle
	 * an entire persistent inventory into the property save.
	 */
	if(istype(src, /obj/item/storage))
		return FALSE

	/*
	 * reagents are consumable resources and can contain medicines,
	 * poison, alcohol, crafting chemicals, etc.
	 */
	if(istype(src, /obj/item/reagent_containers))
		return FALSE

	/*
	 * ratwood armor is spread across several different type trees,
	 * so armor_class is a cleaner filter than trying to enumerate
	 * every suit/helmet/glove parent.
	 *
	 * ordinary clothing remains allowed.
	 */
	if(istype(src, /obj/item/clothing))
		var/obj/item/clothing/C = src

		if(C.armor_class != ARMOR_CLASS_NONE)
			return FALSE

	return TRUE
