/obj/structure/mineral_door/wood/experimental_property
	keylock = TRUE
	locked = TRUE

	var/property_id = null


/obj/structure/mineral_door/wood/experimental_property/Initialize(mapload)
	keylock = FALSE
	lockid = null
	lockhash = 0

	. = ..()

	if(bind_property_lock())
		return .

	if(!SShousing.initialized && istext(property_id) && length(property_id))
		SShousing.pending_property_doors += src
	else
		log_mapping("Experimental property door '[property_id]' at [AREACOORD(src)] could not bind its lock.")


/obj/structure/mineral_door/wood/experimental_property/Destroy()
	if(SShousing)
		SShousing.pending_property_doors -= src

	return ..()


/obj/structure/mineral_door/wood/experimental_property/proc/bind_property_lock()
	var/property_lockhash = SShousing.get_property_lockhash(property_id)

	if(!property_lockhash)
		return FALSE

	var/datum/experimental_property_record/record = SShousing.get_property_record(property_id)

	lockid = record.lock_id
	lockhash = property_lockhash
	keylock = TRUE

	return TRUE


/obj/structure/mineral_door/wood/experimental_property/experimental_get_save_vars()
	. = ..()
	. -= list("icon_state", "density", "opacity")
	. |= "property_id"
