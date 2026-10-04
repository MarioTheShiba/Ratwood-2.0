/*
 * Experimental persistent housing map writer.
 *
 * Ratwood retains runtime DMM/TGM loading but removed its map writer.
 * This is a deliberately limited writer intended only for persistent
 * property interiors.
 *
 * Phase 1 saves:
 * - turfs
 * - areas
 * - non-item objects
 *
 * It deliberately does NOT save: (yet)
 * - mobs
 * - loose items
 * - landmarks/effects
 * - inventories
 * - UUID/stasis data
 */

// this is basically repurposed Ratworld code.

/atom/proc/experimental_get_save_vars()
	. = list(
		"color",
		"dir",
		"icon",
		"icon_state",
		"name",
		"pixel_x",
		"pixel_y",
		"density",
		"opacity",
	)


/atom/movable/experimental_get_save_vars()
	. = ..()
	. += "anchored"


/proc/experimental_property_sanitize_text(text)
	if(isnull(text))
		return ""

	text = "[text]"

	// TGM metadata is code-like. Do not allow user-controlled names
	// to inject arbitrary map syntax.
	text = replacetext(text, "\n", "")
	text = replacetext(text, "\t", "")
	text = replacetext(text, "{", "")
	text = replacetext(text, "}", "")
	text = replacetext(text, "\"", "")
	text = replacetext(text, ";", "")
	text = replacetext(text, ",", "")

	return text


/proc/experimental_property_encode_list(list/input)
	var/list/output = list()
	output += "list("

	var/first = TRUE

	for(var/key in input)
		CHECK_TICK

		if(!first)
			output += ", "

		if(isnum(key) || !input[key])
			output += experimental_property_tgm_encode(key)
		else
			output += "[experimental_property_tgm_encode(key)] = [experimental_property_tgm_encode(input[key])]"

		first = FALSE

	output += ")"

	return output.Join("")


/proc/experimental_property_tgm_encode(value)
	if(istext(value))
		return "\"[experimental_property_sanitize_text(value)]\""

	if(isnum(value) || ispath(value))
		return "[value]"

	if(islist(value))
		return experimental_property_encode_list(value)

	if(isnull(value))
		return "null"

	if(isicon(value) || isfile(value))
		return "'[value]'"

	// fall back to a safe textual representation.
	return experimental_property_tgm_encode("[value]")


/proc/experimental_property_generate_metadata(atom/thing)
	var/list/data_to_add = list()
	var/list/vars_to_save = thing.experimental_get_save_vars()

	for(var/variable in vars_to_save)
		CHECK_TICK

		if(!(variable in thing.vars))
			continue

		var/value = thing.vars[variable]

		// don't clutter the generated map with default values.
		if(value == initial(thing.vars[variable]))
			continue

		if(!issaved(thing.vars[variable]))
			continue

		var/text_value = experimental_property_tgm_encode(value)

		if(isnull(text_value))
			continue

		data_to_add += "[variable] = [text_value]"

	if(!length(data_to_add))
		return ""

	return "{\n\t[data_to_add.Join(";\n\t")]\n\t}"


/proc/experimental_property_get_key_chars()
	var/static/list/key_chars = list(
		"a","b","c","d","e","f","g","h","i","j",
		"k","l","m","n","o","p","q","r","s","t",
		"u","v","w","x","y","z",
		"A","B","C","D","E","F","G","H","I","J",
		"K","L","M","N","O","P","Q","R","S","T",
		"U","V","W","X","Y","Z",
	)

	return key_chars


/proc/experimental_property_calculate_key(index, key_length)
	var/list/output = list()
	var/list/key_chars = experimental_property_get_key_chars()
	var/base = length(key_chars)

	for(var/i in key_length to 1 step -1)
		var/calculated = FLOOR((index - 1) / (base ** (i - 1)), 1)
		calculated = (calculated % base) + 1
		output += key_chars[calculated]

	return output.Join("")


/proc/experimental_property_write_map(
	min_x,
	min_y,
	min_z,
	max_x,
	max_y,
	max_z,
	save_flags = EXP_PROPERTY_SAVE_DEFAULT
)
	/*
	 * normalise coordinates so callers don't need to care which corner
	 * they supplied first.
	 */
	var/real_min_x = min(min_x, max_x)
	var/real_max_x = max(min_x, max_x)

	var/real_min_y = min(min_y, max_y)
	var/real_max_y = max(min_y, max_y)

	var/real_min_z = min(min_z, max_z)
	var/real_max_z = max(min_z, max_z)

	if(real_min_x < 1 || real_max_x > world.maxx || real_min_y < 1 || real_max_y > world.maxy || real_min_z < 1 || real_max_z > world.maxz)
		return null

	var/width = real_max_x - real_min_x
	var/height = real_max_y - real_min_y
	var/depth = real_max_z - real_min_z

	/*
	 * number of possible cells determines how many characters our map
	 * model keys might need.
	 */
	var/tile_count = (width + 1) * (height + 1) * (depth + 1)

	var/list/key_chars = experimental_property_get_key_chars()
	var/base = length(key_chars)

	var/key_length = 1
	while((base ** key_length) < tile_count)
		key_length++

	var/list/header_lookup = list()
	var/list/header_output = list()
	var/list/map_output = list()

	var/key_index = 1

	/*
	 * TGM stores each X coordinate as a vertical column.
	 */
	for(var/z_offset in 0 to depth)
		for(var/x_offset in 0 to width)

			map_output += "\n([x_offset + 1],1,[z_offset + 1]) = {\"\n"

			for(var/y_offset in height to 0 step -1)
				CHECK_TICK

				var/turf/current_turf = locate(
					real_min_x + x_offset,
					real_min_y + y_offset,
					real_min_z + z_offset
				)

				var/turf/turf_type = /turf/template_noop
				var/area/area_type = /area/template_noop

				if(current_turf)
					if(save_flags & EXP_PROPERTY_SAVE_TURFS)
						turf_type = current_turf.type

					if(save_flags & EXP_PROPERTY_SAVE_AREAS)
						var/area/current_area = get_area(current_turf)

						if(current_area)
							area_type = current_area.type

				var/list/current_header = list()
				current_header += "(\n"

				var/has_contents = FALSE

				/*
				 * Save structures/machinery/etc, but never loose items
				 * or /obj/effect internals during Phase 1.
				 */
				if(current_turf && (save_flags & EXP_PROPERTY_SAVE_OBJECTS))
					for(var/obj/thing in current_turf)
						CHECK_TICK

						if(isitem(thing))
							continue

						if(istype(thing, /obj/effect))
							continue

						if(istype(thing, /obj/structure/experimental_property_test))
							continue

						var/metadata = experimental_property_generate_metadata(thing)

						if(has_contents)
							current_header += ",\n"

						current_header += "[thing.type][metadata]"
						has_contents = TRUE

				if(has_contents)
					current_header += ",\n"

				current_header += "[turf_type],\n[area_type])\n"

				var/header_text = current_header.Join("")
				var/key = header_lookup[header_text]

				if(!key)
					key = experimental_property_calculate_key(
						key_index,
						key_length
					)

					key_index++

					header_lookup[header_text] = key
					header_output += "\"[key]\" = [header_text]"

				map_output += "[key]\n"

			map_output += "\"}"

	return "[EXP_PROPERTY_DMM_HEADER]\n[header_output.Join("")][map_output.Join("")]"
