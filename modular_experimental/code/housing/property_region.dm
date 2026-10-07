

/obj/effect/landmark/property_region
	name = "property region"
	icon = 'modular_experimental/sprites/landmarks.dmi'
	icon_state = "property"
	var/property_id = null


/obj/effect/landmark/property_region/Initialize(mapload)
	. = ..()

	if(!istext(property_id) || !length(property_id))
		log_mapping(
			"Property region marker at [AREACOORD(src)] has no property_id."
		)

		return INITIALIZE_HINT_QDEL

	var/turf/T = get_turf(src)

	if(!T)
		log_mapping(
			"Property region marker '[property_id]' has no valid turf."
		)

		return INITIALIZE_HINT_QDEL

	if(!SShousing)
		log_mapping(
			"Property region marker '[property_id]' at [AREACOORD(src)] could not find SShousing."
		)

		return INITIALIZE_HINT_QDEL

	if(!SShousing.register_property_turf(property_id, T))
		log_mapping(
			"Property region marker '[property_id]' failed to register turf at [AREACOORD(src)]."
		)

		return INITIALIZE_HINT_QDEL

	/*
	 * This is mapper metadata only.
	 *
	 * Once its turf has been registered, there is no reason for the
	 * marker itself to remain in the live round.
	 */
	return INITIALIZE_HINT_QDEL


/obj/effect/landmark/property_definition
	name = "property definition"
	icon = 'modular_experimental/sprites/landmarks.dmi'
	icon_state = "property"

	var/property_id = null
	var/property_type = EXP_PROPERTY_TYPE_APARTMENT
	var/rent_amount = 0
	var/max_delinquent_rounds = 2


/obj/effect/landmark/property_definition/Initialize(mapload)
	. = ..()

	if(!SShousing.register_property_definition(
		property_id,
		property_type,
		rent_amount,
		max_delinquent_rounds
	))
		log_mapping("Invalid Experimental housing definition at [AREACOORD(src)].")

	return INITIALIZE_HINT_QDEL
