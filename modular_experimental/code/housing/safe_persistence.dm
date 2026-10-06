

/obj/item
	var/tmp/experimental_safe_slot = null


/obj/item/proc/experimental_safe_get_save_vars()
	return list(
		"name",
		"desc",
		"color",
		"dir",
		"icon_state",

		/*
		 * item condition.
		 */
		"max_integrity",
		"obj_integrity",

		/*
		 * crafting / identity.
		 */
		"item_quality",
		"original_name",
		"renamedByPlayer",
		"sellprice",

		/*
		 * weapon edge state.
		 */
		"blade_int",
		"max_blade_int",
		"dismember_blade_int",
		"blade_dulling",

		/*
		 * blacksmithing state.
		 */
		"polished",
		"polish_bonus",
		"shoddy_repair",


		"looted",
		"unmintable",
		"from_stockpile",
		"atc_sealed"
	)


/proc/experimental_safe_get_slot_path(safe_id, slot)
	if(!istext(safe_id) || !length(safe_id))
		return null

	if(!isnum(slot) || slot < 1)
		return null

	var/clean_id = sanitize_filename(safe_id)

	if(!length(clean_id))
		return null

	return "[EXP_HOUSING_SAFE_DIRECTORY]/[clean_id]_slot_[round(slot)].json"


/proc/experimental_safe_encode_value(value)
	if(ispath(value))
		return list(
			"kind" = "path",
			"value" = "[value]"
		)

	if(isnull(value) || isnum(value) || istext(value))
		return list(
			"kind" = "value",
			"value" = value
		)


	return null


/proc/experimental_safe_decode_value(list/encoded)
	if(!islist(encoded))
		return null

	switch(encoded["kind"])
		if("value")
			return encoded["value"]

		if("path")
			var/path_text = encoded["value"]

			if(!istext(path_text))
				return null

			return text2path(path_text)

	return null


/proc/experimental_safe_serialize_item(safe_id, slot, obj/item/I)
	if(!I)
		return null

	if(!I.experimental_can_persist_in_safe())
		return null

	var/list/saved_vars = list()
	var/list/allowed_vars = I.experimental_safe_get_save_vars()

	for(var/variable in allowed_vars)
		CHECK_TICK

		if(!(variable in I.vars))
			continue

		if(!issaved(I.vars[variable]))
			continue

		var/list/encoded = experimental_safe_encode_value(I.vars[variable])

		if(!encoded)
			continue

		saved_vars[variable] = encoded

	return list(
		"version" = EXP_HOUSING_SAFE_RECORD_VERSION,
		"safe_id" = safe_id,
		"slot" = slot,
		"item_type" = "[I.type]",
		"broken" = I.obj_broken,
		"vars" = saved_vars
	)


/datum/controller/subsystem/housing/proc/safe_slot_exists(safe_id, slot)
	var/save_path = experimental_safe_get_slot_path(safe_id, slot)

	if(!save_path)
		return FALSE

	return fexists(save_path)


/datum/controller/subsystem/housing/proc/write_safe_slot(safe_id, slot, obj/item/I)
	if(!I)
		return FALSE

	var/save_path = experimental_safe_get_slot_path(safe_id, slot)

	if(!save_path)
		return FALSE

	var/list/record = experimental_safe_serialize_item(
		safe_id,
		slot,
		I
	)

	if(!record)
		return FALSE

	var/json_text = json_encode(record)

	if(!length(json_text))
		return FALSE


	var/temp_path = "[save_path].tmp"

	if(fexists(temp_path))
		fdel(temp_path)

	if(!text2file(json_text, temp_path))
		log_world("EXPERIMENTAL HOUSING: Failed to write temporary safe record '[temp_path]'.")
		return FALSE

	var/verify_text = file2text(temp_path)

	if(!length(verify_text))
		fdel(temp_path)
		log_world("EXPERIMENTAL HOUSING: Temporary safe record '[temp_path]' was empty.")
		return FALSE

	var/list/verify_record = json_decode(verify_text)

	if(!islist(verify_record))
		fdel(temp_path)
		log_world("EXPERIMENTAL HOUSING: Temporary safe record '[temp_path]' failed JSON validation.")
		return FALSE

	if(fexists(save_path))
		if(!fdel(save_path))
			fdel(temp_path)
			log_world("EXPERIMENTAL HOUSING: Could not replace safe record '[save_path]'.")
			return FALSE

	if(!fcopy(temp_path, save_path))
		fdel(temp_path)
		log_world("EXPERIMENTAL HOUSING: Failed to commit safe record '[save_path]'.")
		return FALSE

	fdel(temp_path)

	return TRUE


/datum/controller/subsystem/housing/proc/read_safe_slot(safe_id, slot)
	var/save_path = experimental_safe_get_slot_path(safe_id, slot)

	if(!save_path || !fexists(save_path))
		return null

	var/raw_text = file2text(save_path)

	if(!length(raw_text))
		log_world("EXPERIMENTAL HOUSING: Safe record '[save_path]' is empty.")
		return null

	var/list/record = json_decode(raw_text)

	if(!islist(record))
		log_world("EXPERIMENTAL HOUSING: Safe record '[save_path]' is invalid JSON.")
		return null

	if(record["version"] != EXP_HOUSING_SAFE_RECORD_VERSION)
		log_world("EXPERIMENTAL HOUSING: Safe record '[save_path]' has unsupported version '[record["version"]]'.")
		return null

	if(record["safe_id"] != safe_id)
		log_world("EXPERIMENTAL HOUSING: Safe record '[save_path]' has mismatched safe_id.")
		return null

	if(round(record["slot"]) != slot)
		log_world("EXPERIMENTAL HOUSING: Safe record '[save_path]' has mismatched slot number.")
		return null

	var/item_type_text = record["item_type"]

	if(!istext(item_type_text))
		return null

	var/item_type = text2path(item_type_text)

	if(!ispath(item_type, /obj/item))
		log_world("EXPERIMENTAL HOUSING: Safe record '[save_path]' contains invalid item type '[item_type_text]'.")
		return null

	return record


/datum/controller/subsystem/housing/proc/delete_safe_slot(safe_id, slot)
	var/save_path = experimental_safe_get_slot_path(safe_id, slot)

	if(!save_path)
		return FALSE


	if(!fexists(save_path))
		return TRUE

	if(!fdel(save_path))
		log_world("EXPERIMENTAL HOUSING: Failed to delete safe record '[save_path]'.")
		return FALSE

	return TRUE


/datum/controller/subsystem/housing/proc/instantiate_safe_slot(safe_id, slot, atom/location)
	var/list/record = read_safe_slot(safe_id, slot)

	if(!record)
		return null

	var/item_type_text = record["item_type"]
	var/item_type = text2path(item_type_text)

	if(!ispath(item_type, /obj/item))
		return null

	var/obj/item/I = new item_type(location)

	if(!I)
		return null


	if(!I.experimental_can_persist_in_safe())
		log_world("EXPERIMENTAL HOUSING: Safe '[safe_id]' slot [slot] contains '[item_type]' which current policy refuses.")
		qdel(I)
		return null

	var/list/saved_vars = record["vars"]

	if(islist(saved_vars))

		for(var/variable in I.experimental_safe_get_save_vars())
			CHECK_TICK

			if(!(variable in saved_vars))
				continue

			if(!(variable in I.vars))
				continue

			var/list/encoded = saved_vars[variable]

			if(!islist(encoded))
				continue

			I.vars[variable] = experimental_safe_decode_value(encoded)


	if(record["broken"] && !I.obj_broken)
		I.obj_break(BRUTE)

	I.experimental_safe_slot = slot


	I.update_force_dynamic()
	I.update_damaged_state()
	I.update_icon()

	return I
