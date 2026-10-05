

/obj/item
	/*
	 * null  = use normal safe rules
	 * TRUE  = explicitly allow
	 * FALSE = explicitly deny
	 */
	var/experimental_safe_persistence_override = null

	/*
	 * runtime-only bookkeeping.
	 *
	 * dis is the persistent slot currently backing this physical item.
	 * It must never itself be serialized.
	 */
	var/tmp/experimental_safe_slot = null


/obj/item/proc/experimental_can_persist_in_safe()
	if(!isnull(experimental_safe_persistence_override))
		return experimental_safe_persistence_override

	/*
	 * currency belongs in banking.
	 */
	if(istype(src, /obj/item/roguecoin))
		return FALSE

	/*
	 * bulk economic materials are explicitly prohibited.
	 */
	if(istype(src, /obj/item/rogueore))
		return FALSE

	if(istype(src, /obj/item/ingot))
		return FALSE

	if(istype(src, /obj/item/stack))
		return FALSE

	// Weapons themselves are intentionally NOT prohibited here.

	if(istype(src, /obj/item/ammo_casing))
		return FALSE

	/*
	 * never allow nested storage.
	 *
	 * otherwise four safe slots could secretly contain four
	 * entire backpacks of persistent inventory.
	 */
	if(istype(src, /obj/item/storage))
		return FALSE

	/*
	 * mdicines, alcohol, poisons, crafting liquids, etc.
	 */
	if(istype(src, /obj/item/reagent_containers))
		return FALSE

	if(length(contents))
		return FALSE

	return TRUE


/*
 * variables which a persistent safe preserves.
 *
 * this is intentionally a whitelist.
 *
 * individual item families can override this later if they have
 * some meaningful piece of persistent state which deserves to survive.
 */
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

		/*
		 * economic provenance.
		 *
		 * these are important to preserve so putting something into
		 * a safe cannot wash restrictions off the item. sorry no money laundering.
		 */
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

	/*
	 * lists, datums, icons, files and other complex runtime values
	 * are not implicitly persisted.
	 *
	 * if an item genuinely needs one later, give that item an
	 * explicit persistence implementation rather than blindly
	 * serializing arbitrary runtime state.
	 */
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

	/*
	 * write and validate a temporary file first.
	 *
	 * we do not keep stale backup copies because restoring an old
	 * pre-withdrawal record could duplicate an item.
	 */
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

	/*
	 * already absent is equivalent to successfully removed.
	 *
	 * dis also prevents a runtime item becoming permanently trapped
	 * merely because its backing record was manually cleaned up.
	 */
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

	/*
	 * if policy changes between weekends, do not silently delete the
	 * record. Leave it on disk for staff/migration and simply refuse
	 * to materialize it.
	 */
	if(!I.experimental_can_persist_in_safe())
		log_world("EXPERIMENTAL HOUSING: Safe '[safe_id]' slot [slot] contains '[item_type]' which current policy refuses.")
		qdel(I)
		return null

	var/list/saved_vars = record["vars"]

	if(islist(saved_vars))
		/*
		 * iterate through the item's whitelist rather than blindly
		 * trusting arbitrary variable names from disk.
		 *
		 * dis also gives us deterministic assignment ordering.
		 */
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

	/*
	 * brokenness is restored through the item's actual break logic
	 * instead of simply flipping obj_broken.
	 *
	 * dat matters for Ratwood weapons because obj_break() changes
	 * sharpness, parrying and related combat state.
	 */
	if(record["broken"] && !I.obj_broken)
		I.obj_break(BRUTE)

	I.experimental_safe_slot = slot

	/*
	 * refresh state which may depend upon the restored variables.
	 */
	I.update_force_dynamic()
	I.update_damaged_state()
	I.update_icon()

	return I
