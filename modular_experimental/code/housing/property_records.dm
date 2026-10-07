/datum/experimental_property_record
	var/property_id
	var/property_type = EXP_PROPERTY_TYPE_APARTMENT

	var/holder_id = null
	var/holder_name = null
	var/tenure_type = EXP_PROPERTY_TENURE_VACANT

	var/rent_amount = 0
	var/delinquent_rounds = 0
	var/max_delinquent_rounds = 2

	var/lock_id


/datum/experimental_property_record/New(
	new_property_id,
	new_property_type = EXP_PROPERTY_TYPE_APARTMENT,
	new_rent_amount = 0,
	new_max_delinquent_rounds = 2
)
	property_id = new_property_id
	property_type = new_property_type
	rent_amount = max(0, round(new_rent_amount))
	max_delinquent_rounds = max(1, round(new_max_delinquent_rounds))
	lock_id = experimental_property_make_lock_id(property_id)


/proc/experimental_property_make_lock_id(property_id)
	if(!istext(property_id) || !length(property_id))
		return null

	var/clean_id = sanitize_filename(property_id)

	if(!length(clean_id))
		return null

	return "housing_[clean_id]"


/proc/experimental_property_get_record_path(property_id)
	if(!istext(property_id) || !length(property_id))
		return null

	var/clean_id = sanitize_filename(property_id)

	if(!length(clean_id))
		return null

	return "[EXP_HOUSING_PROPERTY_RECORD_DIRECTORY]/[clean_id].json"


/datum/experimental_property_record/proc/to_list()
	return list(
		"version" = EXP_HOUSING_PROPERTY_RECORD_VERSION,
		"property_id" = property_id,
		"property_type" = property_type,
		"holder_id" = holder_id,
		"holder_name" = holder_name,
		"tenure_type" = tenure_type,
		"rent_amount" = rent_amount,
		"delinquent_rounds" = delinquent_rounds,
		"max_delinquent_rounds" = max_delinquent_rounds,
		"lock_id" = lock_id
	)

/datum/controller/subsystem/housing/proc/get_property_record(property_id)
	return property_records[property_id]



/datum/controller/subsystem/housing/proc/normalize_property_holder_id(holder_id)
	if(!istext(holder_id) || !length(holder_id))
		return null

	var/normalized_id = ckey(holder_id)

	if(!length(normalized_id))
		return null

	return normalized_id


/datum/controller/subsystem/housing/proc/assign_property_holder(
	property_id,
	holder_id,
	holder_name,
	tenure_type = EXP_PROPERTY_TENURE_RENTED,
	mob/actor = null
)
	var/datum/experimental_property_record/record = get_property_record(property_id)

	if(!record)
		return FALSE

	if(record.tenure_type != EXP_PROPERTY_TENURE_VACANT || record.holder_id)
		return FALSE

	if(!(tenure_type in list(EXP_PROPERTY_TENURE_RENTED, EXP_PROPERTY_TENURE_OWNED)))
		return FALSE

	var/normalized_holder_id = normalize_property_holder_id(holder_id)

	if(!normalized_holder_id)
		return FALSE

	if(!istext(holder_name) || !length(holder_name))
		return FALSE


	var/old_holder_id = record.holder_id
	var/old_holder_name = record.holder_name
	var/old_tenure_type = record.tenure_type
	var/old_delinquent_rounds = record.delinquent_rounds

	record.holder_id = normalized_holder_id
	record.holder_name = holder_name
	record.tenure_type = tenure_type
	record.delinquent_rounds = 0

	if(!write_property_record(record))
		record.holder_id = old_holder_id
		record.holder_name = old_holder_name
		record.tenure_type = old_tenure_type
		record.delinquent_rounds = old_delinquent_rounds

		return FALSE

	var/actor_name = actor ? key_name(actor) : "SYSTEM"

	log_game(
		"EXPERIMENTAL HOUSING: [actor_name] assigned property '[property_id]' to [holder_name] ([normalized_holder_id]) as '[tenure_type]'."
	)

	return TRUE


/datum/controller/subsystem/housing/proc/assign_property_holder_from_mob(
	property_id,
	mob/living/holder,
	tenure_type = EXP_PROPERTY_TENURE_RENTED,
	mob/actor = null
)
	if(!holder?.client)
		return FALSE

	return assign_property_holder(
		property_id,
		holder.client.ckey,
		holder.real_name,
		tenure_type,
		actor
	)


/datum/controller/subsystem/housing/proc/clear_property_holder(
	property_id,
	mob/actor = null
)
	var/datum/experimental_property_record/record = get_property_record(property_id)

	if(!record)
		return FALSE

	if(record.tenure_type == EXP_PROPERTY_TENURE_VACANT && !record.holder_id)
		return TRUE

	var/old_holder_id = record.holder_id
	var/old_holder_name = record.holder_name
	var/old_tenure_type = record.tenure_type
	var/old_delinquent_rounds = record.delinquent_rounds

	record.holder_id = null
	record.holder_name = null
	record.tenure_type = EXP_PROPERTY_TENURE_VACANT
	record.delinquent_rounds = 0

	if(!write_property_record(record))
		record.holder_id = old_holder_id
		record.holder_name = old_holder_name
		record.tenure_type = old_tenure_type
		record.delinquent_rounds = old_delinquent_rounds

		return FALSE

	var/actor_name = actor ? key_name(actor) : "SYSTEM"

	log_game(
		"EXPERIMENTAL HOUSING: [actor_name] cleared holder [old_holder_name] ([old_holder_id]) from property '[property_id]'."
	)

	return TRUE


/datum/controller/subsystem/housing/proc/is_property_holder(
	property_id,
	holder_id
)
	var/datum/experimental_property_record/record = get_property_record(property_id)

	if(!record?.holder_id)
		return FALSE

	var/normalized_holder_id = normalize_property_holder_id(holder_id)

	if(!normalized_holder_id)
		return FALSE

	return record.holder_id == normalized_holder_id


/datum/controller/subsystem/housing/proc/get_properties_for_holder(holder_id)
	var/normalized_holder_id = normalize_property_holder_id(holder_id)

	if(!normalized_holder_id)
		return list()

	var/list/results = list()

	for(var/property_id in property_records)
		var/datum/experimental_property_record/record = property_records[property_id]

		if(!record)
			continue

		if(record.holder_id != normalized_holder_id)
			continue

		results[property_id] = record

	return results

/datum/controller/subsystem/housing/proc/create_property_record(property_id)
	if(property_records[property_id])
		return property_records[property_id]

	var/list/definition = property_definitions[property_id]

	if(!definition)
		log_mapping("Experimental housing property '[property_id]' has no property definition.")
		return null

	var/datum/experimental_property_record/record = new(
		property_id,
		definition["property_type"],
		definition["rent_amount"],
		definition["max_delinquent_rounds"]
	)

	property_records[property_id] = record

	return record


/datum/controller/subsystem/housing/proc/write_property_record(datum/experimental_property_record/record)
	if(!record?.property_id)
		return FALSE

	var/save_path = experimental_property_get_record_path(record.property_id)

	if(!save_path)
		return FALSE

	var/json_text = json_encode(record.to_list())

	if(!length(json_text))
		return FALSE

	var/temp_path = "[save_path].tmp"

	if(fexists(temp_path))
		fdel(temp_path)

	if(!text2file(json_text, temp_path))
		return FALSE

	var/verify_text = file2text(temp_path)

	if(!length(verify_text) || !islist(json_decode(verify_text)))
		fdel(temp_path)
		return FALSE

	if(fexists(save_path))
		if(!fdel(save_path))
			fdel(temp_path)
			return FALSE

	if(!fcopy(temp_path, save_path))
		fdel(temp_path)
		return FALSE

	fdel(temp_path)

	return TRUE


/datum/controller/subsystem/housing/proc/load_property_record(property_id)
	var/save_path = experimental_property_get_record_path(property_id)

	if(!save_path || !fexists(save_path))
		return null

	var/raw_text = file2text(save_path)

	if(!length(raw_text))
		return null

	var/list/data = json_decode(raw_text)

	if(!islist(data))
		return null

	if(data["version"] != EXP_HOUSING_PROPERTY_RECORD_VERSION)
		log_world("EXPERIMENTAL HOUSING: Property record '[property_id]' has an unsupported version.")
		return null

	if(data["property_id"] != property_id)
		log_world("EXPERIMENTAL HOUSING: Property record '[property_id]' has a mismatched property_id.")
		return null

	var/property_type = data["property_type"]

	if(!(property_type in list(
		EXP_PROPERTY_TYPE_APARTMENT,
		EXP_PROPERTY_TYPE_HOME,
		EXP_PROPERTY_TYPE_MANSION
	)))
		return null

	var/tenure_type = data["tenure_type"]

	if(!(tenure_type in list(
		EXP_PROPERTY_TENURE_VACANT,
		EXP_PROPERTY_TENURE_RENTED,
		EXP_PROPERTY_TENURE_OWNED
	)))
		return null

	var/datum/experimental_property_record/record = new(
		property_id,
		property_type,
		data["rent_amount"],
		data["max_delinquent_rounds"]
	)

	record.holder_id = data["holder_id"]
	record.holder_name = data["holder_name"]
	record.tenure_type = tenure_type
	record.delinquent_rounds = max(0, round(data["delinquent_rounds"]))

	if(istext(data["lock_id"]) && length(data["lock_id"]))
		record.lock_id = data["lock_id"]

	property_records[property_id] = record

	return record


/datum/controller/subsystem/housing/proc/load_property_records()
	var/loaded = 0
	var/created = 0

	for(var/property_id in property_turfs)
		CHECK_TICK

		var/save_path = experimental_property_get_record_path(property_id)

		if(save_path && fexists(save_path))
			if(load_property_record(property_id))
				loaded++
			else
				log_world("EXPERIMENTAL HOUSING: Failed to load property record '[property_id]'.")
			continue

		var/datum/experimental_property_record/record = create_property_record(property_id)

		if(record && write_property_record(record))
			created++

	log_world("EXPERIMENTAL HOUSING: Loaded [loaded] property record\s and created [created] new record\s.")


/datum/controller/subsystem/housing/proc/save_property_records()
	var/saved = 0

	for(var/property_id in property_records)
		CHECK_TICK

		var/datum/experimental_property_record/record = property_records[property_id]

		if(write_property_record(record))
			saved++

	log_world("EXPERIMENTAL HOUSING: Saved [saved] property record\s.")
