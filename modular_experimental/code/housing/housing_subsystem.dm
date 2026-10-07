
// i basically copied everything from vanderlin with my modifications put in.


SUBSYSTEM_DEF(housing)
	name = "Experimental Housing"
	flags = SS_NO_FIRE

	var/list/property_turfs = list()
	var/list/property_by_turf = list()
	var/list/persistent_properties = list()
	var/list/property_definitions = list()
	var/list/property_records = list()
	var/list/pending_property_doors = list()

/datum/controller/subsystem/housing/Initialize()
	log_world("EXPERIMENTAL HOUSING: [length(property_turfs)] property region\s registered.")

	for(var/property_id in property_turfs)
		var/list/turfs = property_turfs[property_id]
		log_world("EXPERIMENTAL HOUSING: '[property_id]' contains [length(turfs)] turf\s.")
		log_property_bounds(property_id)

	load_property_records()
	load_persistent_properties()

	for(var/obj/structure/mineral_door/wood/experimental_property/door as anything in pending_property_doors)
		if(!door.bind_property_lock())
			log_mapping("Experimental property door '[door.property_id]' at [AREACOORD(door)] could not bind its lock.")

	pending_property_doors.Cut()

	return ..()



/datum/controller/subsystem/housing/Shutdown()
	save_persistent_properties()
	save_property_records()

/datum/controller/subsystem/housing/proc/register_property_turf(property_id, turf/T)
	if(!istext(property_id) || !length(property_id))
		return FALSE

	if(!T)
		return FALSE


	var/existing_property_id = property_by_turf[T]

	if(existing_property_id && existing_property_id != property_id)
		log_mapping(
			"Experimental housing turf at [AREACOORD(T)] belongs to both '[existing_property_id]' and '[property_id]'."
		)

		return FALSE

	var/list/turfs = property_turfs[property_id]

	if(!turfs)
		turfs = list()
		property_turfs[property_id] = turfs

	turfs[T] = TRUE
	property_by_turf[T] = property_id

	return TRUE


/datum/controller/subsystem/housing/proc/get_property_turfs(property_id)
	if(!istext(property_id) || !length(property_id))
		return null

	return property_turfs[property_id]


/datum/controller/subsystem/housing/proc/is_property_turf(property_id, turf/T)
	if(!T)
		return FALSE

	var/list/turfs = get_property_turfs(property_id)

	if(!turfs)
		return FALSE

	return !!turfs[T]


/datum/controller/subsystem/housing/proc/get_property_bounds(property_id)
	var/list/turfs = get_property_turfs(property_id)

	if(!length(turfs))
		return null

	var/min_x = world.maxx
	var/min_y = world.maxy
	var/min_z = world.maxz

	var/max_x = 1
	var/max_y = 1
	var/max_z = 1

	for(var/turf/T as anything in turfs)
		CHECK_TICK

		min_x = min(min_x, T.x)
		min_y = min(min_y, T.y)
		min_z = min(min_z, T.z)

		max_x = max(max_x, T.x)
		max_y = max(max_y, T.y)
		max_z = max(max_z, T.z)

	return list(
		"min_x" = min_x,
		"min_y" = min_y,
		"min_z" = min_z,
		"max_x" = max_x,
		"max_y" = max_y,
		"max_z" = max_z
	)


/datum/controller/subsystem/housing/proc/log_property_bounds(property_id)
	var/list/bounds = get_property_bounds(property_id)

	if(!bounds)
		log_world("EXPERIMENTAL HOUSING: '[property_id]' has no registered bounds.")
		return FALSE

	var/min_x = bounds["min_x"]
	var/min_y = bounds["min_y"]
	var/min_z = bounds["min_z"]
	var/max_x = bounds["max_x"]
	var/max_y = bounds["max_y"]
	var/max_z = bounds["max_z"]

	log_world("EXPERIMENTAL HOUSING: '[property_id]' bounds are ([min_x], [min_y], [min_z]) through ([max_x], [max_y], [max_z]).")

	return TRUE


/datum/controller/subsystem/housing/proc/write_property_region(property_id, save_flags = EXP_PROPERTY_SAVE_DEFAULT)
	var/list/turfs = get_property_turfs(property_id)

	if(!length(turfs))
		log_world("EXPERIMENTAL HOUSING: Cannot write '[property_id]', no property turfs are registered.")
		return null

	var/list/bounds = get_property_bounds(property_id)

	if(!bounds)
		log_world("EXPERIMENTAL HOUSING: Cannot write '[property_id]', failed to calculate property bounds.")
		return null

	var/min_x = bounds["min_x"]
	var/min_y = bounds["min_y"]
	var/min_z = bounds["min_z"]

	var/max_x = bounds["max_x"]
	var/max_y = bounds["max_y"]
	var/max_z = bounds["max_z"]

	return experimental_property_write_map(min_x, min_y, min_z, max_x, max_y, max_z, save_flags, turfs)


//!!!!remove this later!!!!
/datum/controller/subsystem/housing/proc/save_property(property_id)
	var/map_text = write_property_region(property_id)

	if(!map_text)
		log_world("EXPERIMENTAL HOUSING: Failed to save '[property_id]'.")
		return FALSE

	var/save_path = experimental_property_get_save_path(property_id)

	if(!save_path)
		return FALSE

	if(fexists(save_path))
		if(!fdel(save_path))
			log_world("EXPERIMENTAL HOUSING: Could not replace property save '[save_path]'.")
			return FALSE

	if(!text2file(map_text, save_path))
		log_world("EXPERIMENTAL HOUSING: Failed to write '[property_id]' to '[save_path]'.")
		return FALSE

	persistent_properties[property_id] = TRUE

	log_world("EXPERIMENTAL HOUSING: Saved '[property_id]' to '[save_path]'.")

	return TRUE


/datum/controller/subsystem/housing/proc/load_property(property_id)
	var/list/turfs = get_property_turfs(property_id)

	if(!length(turfs))
		log_world("EXPERIMENTAL HOUSING: Cannot load '[property_id]', no property turfs are registered.")
		return FALSE

	var/list/bounds = get_property_bounds(property_id)

	if(!bounds)
		log_world("EXPERIMENTAL HOUSING: Cannot load '[property_id]', failed to calculate property bounds.")
		return FALSE

	var/save_path = experimental_property_get_save_path(property_id)

	if(!save_path || !fexists(save_path))
		return FALSE

	var/min_x = bounds["min_x"]
	var/min_y = bounds["min_y"]
	var/min_z = bounds["min_z"]

	var/turf/start = locate(min_x, min_y, min_z)

	if(!start)
		log_world("EXPERIMENTAL HOUSING: Cannot load '[property_id]', invalid starting turf.")
		return FALSE

	for(var/turf/T as anything in turfs)
		CHECK_TICK

		for(var/obj/thing in T)
			if(isitem(thing))
				continue

			if(istype(thing, /obj/effect))
				continue

			if(istype(thing, /obj/structure/experimental_property_test))
				continue

			qdel(thing)

	var/datum/map_template/template = new(
		save_path,
		"Experimental Property [property_id]"
	)

	var/list/loaded_bounds = template.load(start)

	if(!loaded_bounds)
		log_world("EXPERIMENTAL HOUSING: Failed to load '[property_id]' from '[save_path]'.")
		qdel(template)
		return FALSE

	qdel(template)

	persistent_properties[property_id] = TRUE

	log_world("EXPERIMENTAL HOUSING: Loaded '[property_id]' from '[save_path]'.")

	return TRUE

/datum/controller/subsystem/housing/proc/load_persistent_properties()
	var/loaded = 0

	for(var/property_id in property_turfs)
		CHECK_TICK

		var/save_path = experimental_property_get_save_path(property_id)

		if(!save_path || !fexists(save_path))
			continue

		if(load_property(property_id))
			loaded++

	log_world("EXPERIMENTAL HOUSING: Automatically loaded [loaded] persistent propert[loaded == 1 ? "y" : "ies"].")


/datum/controller/subsystem/housing/proc/save_persistent_properties()
	var/saved = 0

	for(var/property_id in persistent_properties)
		CHECK_TICK

		if(save_property(property_id))
			saved++

	log_world("EXPERIMENTAL HOUSING: Automatically saved [saved] persistent propert[saved == 1 ? "y" : "ies"].")


/datum/controller/subsystem/housing/proc/get_property_id_at_turf(turf/T)
	if(!T)
		return null

	return property_by_turf[T]

/datum/controller/subsystem/housing/proc/register_property_definition(
	property_id,
	property_type,
	rent_amount = 0,
	max_delinquent_rounds = 2
)
	if(!istext(property_id) || !length(property_id))
		return FALSE

	if(!(property_type in list(
		EXP_PROPERTY_TYPE_APARTMENT,
		EXP_PROPERTY_TYPE_HOME,
		EXP_PROPERTY_TYPE_MANSION
	)))
		return FALSE

	if(property_definitions[property_id])
		log_mapping("Duplicate Experimental housing definition for '[property_id]'.")
		return FALSE

	property_definitions[property_id] = list(
		"property_type" = property_type,
		"rent_amount" = max(0, round(rent_amount)),
		"max_delinquent_rounds" = max(1, round(max_delinquent_rounds))
	)

	return TRUE


/datum/controller/subsystem/housing/proc/get_property_lockhash(property_id)
	if(!istext(property_id) || !length(property_id))
		return null

	var/datum/experimental_property_record/record = get_property_record(property_id)

	if(!record || !istext(record.lock_id) || !length(record.lock_id))
		return null

	var/property_lockhash = GLOB.lockids[record.lock_id]

	if(property_lockhash)
		return property_lockhash

	property_lockhash = rand(1000, 9999)

	while(property_lockhash in GLOB.lockhashes)
		property_lockhash = rand(1000, 9999)

	GLOB.lockhashes += property_lockhash
	GLOB.lockids[record.lock_id] = property_lockhash

	return property_lockhash


/datum/controller/subsystem/housing/proc/create_property_key(property_id, atom/key_location)
	if(!key_location)
		return null

	var/property_lockhash = get_property_lockhash(property_id)

	if(!property_lockhash)
		return null

	var/datum/experimental_property_record/record = get_property_record(property_id)
	var/obj/item/roguekey/experimental_property/key = new(key_location)

	key.lockid = record.lock_id
	key.lockhash = property_lockhash

	return key

/datum/controller/subsystem/housing/proc/issue_property_key(property_id, mob/living/recipient)
	if(!istext(property_id) || !length(property_id))
		return FALSE

	if(!istype(recipient) || !recipient.client)
		return FALSE

	var/datum/experimental_property_record/record = get_property_record(property_id)

	if(!record || !record.holder_id || record.tenure_type == EXP_PROPERTY_TENURE_VACANT)
		return FALSE

	if(!is_property_holder(property_id, recipient.client.ckey))
		return FALSE

	var/obj/item/roguekey/experimental_property/key = create_property_key(property_id, recipient)

	if(!key)
		return FALSE

	return recipient.put_in_hands(key, del_on_fail = TRUE)

/datum/controller/subsystem/housing/proc/get_property_management_data(mob/user)
	var/list/properties = list()

	for(var/property_id in property_records)
		var/datum/experimental_property_record/record = property_records[property_id]

		if(!record)
			continue

		var/is_vacant = record.tenure_type == EXP_PROPERTY_TENURE_VACANT
		var/can_request_key = FALSE

		if(isliving(user) && user.client && !is_vacant)
			can_request_key = is_property_holder(record.property_id, user.client.ckey)

		properties += list(list(
			"property_id" = record.property_id,
			"property_type" = record.property_type,
			"holder_name" = record.holder_name,
			"tenure_type" = record.tenure_type,
			"rent_amount" = record.rent_amount,
			"delinquent_rounds" = record.delinquent_rounds,
			"is_vacant" = is_vacant,
			"can_request_key" = can_request_key
		))

	return properties
