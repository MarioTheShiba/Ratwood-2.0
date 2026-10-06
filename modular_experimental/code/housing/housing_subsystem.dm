
SUBSYSTEM_DEF(housing)
	name = "Experimental Housing"
	flags = SS_NO_FIRE

	var/list/property_turfs = list()
	var/list/property_by_turf = list()


/datum/controller/subsystem/housing/Initialize()
	log_world("EXPERIMENTAL HOUSING: [length(property_turfs)] property region\s registered.")

	for(var/property_id in property_turfs)
		var/list/turfs = property_turfs[property_id]
		log_world("EXPERIMENTAL HOUSING: '[property_id]' contains [length(turfs)] turf\s.")
		log_property_bounds(property_id)

	return ..()


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
/datum/controller/subsystem/housing/proc/debug_save_property(property_id)
	var/map_text = write_property_region(property_id)

	if(!map_text)
		log_world("EXPERIMENTAL HOUSING: Failed to save '[property_id]'.")
		return FALSE

	var/save_path = experimental_property_get_save_path(property_id)

	if(fexists(save_path))
		fdel(save_path)

	text2file(map_text, save_path)

	log_world("EXPERIMENTAL HOUSING: Saved '[property_id]' to '[save_path]'.")

	return TRUE


// !!!!!!remove later!!!!!
/datum/controller/subsystem/housing/proc/debug_load_property(property_id)
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
		log_world("EXPERIMENTAL HOUSING: Cannot load '[property_id]', save file '[save_path]' does not exist.")
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

	log_world("EXPERIMENTAL HOUSING: Loaded '[property_id]' from '[save_path]'.")

	return TRUE


/datum/controller/subsystem/housing/proc/get_property_id_at_turf(turf/T)
	if(!T)
		return null

	return property_by_turf[T]
