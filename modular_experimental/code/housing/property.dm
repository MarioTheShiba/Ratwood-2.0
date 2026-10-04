/obj/structure/experimental_property_test
	name = "property test controller"
	desc = "A temporary development object for Experimental housing."
	icon = 'icons/roguetown/misc/structure.dmi'
	icon_state = "questnoti"

	anchored = TRUE
	density = FALSE

	var/property_width = 7
	var/property_height = 7

	var/save_path = "data/experimental_test_property.dmm"


/obj/structure/experimental_property_test/attack_hand(mob/user)
	. = ..()

	if(!user?.client)
		return

	var/choice = input(
		user,
		"Experimental property test:",
		"Housing Development"
	) as null|anything in list(
		"Save 7x7 Property",
		"Load 7x7 Property",
		"Save Irregular Test Apartment",
		"Cancel"
	)

	if(choice == "Save 7x7 Property")
		save_test_property(user)

	if(choice == "Load 7x7 Property")
		load_test_property(user)

	if(choice == "Save Irregular Test Apartment")
	if(SShousing.debug_save_property("test_apartment"))
		to_chat(user, span_notice("Saved irregular test apartment."))
	else
		to_chat(user, span_warning("Failed to save irregular test apartment."))

// debug stuff

/obj/structure/experimental_property_test/proc/save_test_property(mob/user)
	var/turf/start = get_turf(src)

	if(!start)
		to_chat(user, span_warning("The property controller has no valid turf."))
		return FALSE

	var/max_x = start.x + property_width - 1
	var/max_y = start.y + property_height - 1

	if(max_x > world.maxx || max_y > world.maxy)
		to_chat(user, span_warning("The test property would extend outside the map."))
		return FALSE

	var/map_text = experimental_property_write_map(start.x, start.y, start.z, max_x, max_y, start.z)

	if(!map_text)
		to_chat(user, span_warning("Failed to generate property map data."))
		return FALSE

	if(fexists(save_path))
		fdel(save_path)

	rustg_file_write(map_text, save_path)

	if(!fexists(save_path))
		to_chat(user, span_warning("Map data was generated, but the save file was not created."))
		return FALSE

	to_chat(user, span_notice("Saved test property to [save_path]."))
	log_game("EXPERIMENTAL HOUSING: [key_name(user)] saved test property at [AREACOORD(src)].")

	return TRUE


/obj/structure/experimental_property_test/proc/load_test_property(mob/user)
	var/turf/start = get_turf(src)

	if(!start)
		to_chat(user, span_warning("The property controller has no valid turf."))
		return FALSE

	if(!fexists(save_path))
		to_chat(user, span_warning("No saved property exists at [save_path]."))
		return FALSE

	var/datum/map_template/template = new(
		save_path,
		"Experimental Test Property"
	)

	var/list/bounds = template.load(start)

	if(!bounds)
		to_chat(user, span_warning("Failed to load the saved property."))
		qdel(template)
		return FALSE

	to_chat(user, span_notice("Loaded property from [save_path]."))
	log_game("EXPERIMENTAL HOUSING: [key_name(user)] loaded test property at [AREACOORD(src)].")

	qdel(template)
	return TRUE
