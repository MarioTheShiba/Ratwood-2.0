/* safe stuff
* the safe itself may be serialized as part of property's DMM, though the contents aren't.
* contents live entirely in the persistent safe backend keyed by safe_id + slot
*/

/datum/controller/subsystem/housing
	/*
	 * runtime registry of physical persistent safes.
	 *
	 * Duplicate IDs are forbidden. Two physical safes must never
	 * point at the same persistent inventory. just so we dont have two safes with the same id so people have like bluespace safes or somethin
	 */
	var/list/safe_instances = list()


/datum/controller/subsystem/housing/proc/register_safe(safe_id, obj/structure/experimental_home_safe/safe)
	if(!istext(safe_id) || !length(safe_id))
		return FALSE

	if(!safe)
		return FALSE

	var/obj/structure/experimental_home_safe/existing = safe_instances[safe_id]

	if(existing && !QDELETED(existing) && existing != safe)
		log_mapping(
			"Duplicate Experimental housing safe_id '[safe_id]' at [AREACOORD(safe)]. Existing safe is at [AREACOORD(existing)]."
		)

		return FALSE

	safe_instances[safe_id] = safe

	return TRUE


/datum/controller/subsystem/housing/proc/unregister_safe(safe_id, obj/structure/experimental_home_safe/safe)
	if(!istext(safe_id) || !length(safe_id))
		return FALSE

	if(safe_instances[safe_id] != safe)
		return FALSE

	safe_instances -= safe_id

	return TRUE


/obj/structure/experimental_home_safe
	name = "home safe"
	desc = "A stout iron strongbox built for the few possessions its owner cannot bear to lose."

	icon = 'icons/roguetown/misc/structure.dmi'
	icon_state = "chestiron_neu" //placeholder

	anchored = TRUE
	density = TRUE

	// cannot break them - for now.
	resistance_flags = INDESTRUCTIBLE

	var/safe_id = null
	var/bound_property_id = null

	var/max_persistent_slots = EXP_HOUSING_SAFE_DEFAULT_SLOTS

/obj/structure/experimental_home_safe/ComponentInitialize()
	. = ..()

	AddComponent(/datum/component/storage/concrete/experimental_safe)


/obj/structure/experimental_home_safe/Initialize(mapload)
	. = ..()

	if(!istext(safe_id) || !length(safe_id))
		log_mapping(
			"Persistent home safe at [AREACOORD(src)] has no safe_id."
		)

		return INITIALIZE_HINT_QDEL

	if(!SShousing.register_safe(safe_id, src))
		return INITIALIZE_HINT_QDEL

	load_persistent_contents()

	return .


/obj/structure/experimental_home_safe/Destroy()
	var/datum/component/storage/concrete/experimental_safe/storage = GetComponent(/datum/component/storage/concrete/experimental_safe)

	if(storage)
		/*
		 * property loading qdels the old safe before reconstructing
		 * the saved room.
		 *
		 * destroying that temporary physical instance must NOT be
		 * mistaken for the player withdrawing every stored item.
		 */
		storage.suppress_persistence = TRUE

	/*
	 * magnum condom protection against item deletion callbacks
	 * while the physical safe is disappearing.
	 */
	for(var/obj/item/I in src)
		I.experimental_safe_slot = null

	if(SShousing)
		SShousing.unregister_safe(safe_id, src)

	return ..()


/obj/structure/experimental_home_safe/experimental_get_save_vars()
	. = ..()

	/*
	 * absolutely necessary.
	 *
	 * the physical safe can be reconstructed by the property DMM,
	 * so its stable persistence identity must survive that process.
	 */
	. |= "safe_id"
	. |= "bound_property_id"
	. |= "max_persistent_slots"


/obj/structure/experimental_home_safe/attack_hand(mob/user)
	. = ..()

	if(!user?.client)
		return

	/*
	 * rw's stock storage component primarily expects portable
	 * storage to be held by the user.
	 *
	 * this is a stationary structure, so explicitly ask the component
	 * to show its storage UI.
	 */
	SEND_SIGNAL(src, COMSIG_TRY_STORAGE_SHOW, user)


/obj/structure/experimental_home_safe/proc/get_free_persistent_slot()
	for(var/slot in 1 to max_persistent_slots)
		var/runtime_occupied = FALSE

		for(var/obj/item/I in src)
			if(I.experimental_safe_slot == slot)
				runtime_occupied = TRUE
				break

		if(runtime_occupied)
			continue

		/*
		 * existing files, including malformed records, count as
		 * occupied.
		 *
		 * we fail closed instead of overwriting potentially valuable
		 * player data.
		 */
		if(SShousing.safe_slot_exists(safe_id, slot))
			continue

		return slot

	return null


/obj/structure/experimental_home_safe/proc/load_persistent_contents()
	var/datum/component/storage/concrete/experimental_safe/storage = GetComponent(/datum/component/storage/concrete/experimental_safe)

	if(!storage)
		log_world("EXPERIMENTAL HOUSING: Safe '[safe_id]' has no storage component.")
		return FALSE

	for(var/slot in 1 to max_persistent_slots)
		CHECK_TICK

		if(!SShousing.safe_slot_exists(safe_id, slot))
			continue

		var/obj/item/I = SShousing.instantiate_safe_slot(
			safe_id,
			slot,
			src
		)

		if(!I)
			continue

		/*
		 * the item was constructed directly inside the safe instead
		 * of passing through normal player insertion.
		 */
		I.item_flags |= IN_STORAGE
		I.on_enter_storage(storage, null)

	storage.refresh_mob_views()

	return TRUE


/datum/component/storage/concrete/experimental_safe
	max_items = EXP_HOUSING_SAFE_DEFAULT_SLOTS
	max_w_class = WEIGHT_CLASS_BULKY

	screen_max_rows = EXP_HOUSING_SAFE_DEFAULT_SLOTS
	screen_max_columns = 1

	allow_quick_empty = FALSE
	allow_quick_gather = FALSE
	allow_dump_out = FALSE
	click_gather = FALSE

	/*
	 * set while the entire physical safe is being destroyed/replaced.
	 *
	 * its disk records must survive that process.
	 */
	var/tmp/suppress_persistence = FALSE

	/*
	 * used so our COMSIG_ATOM_EXITED fallback knows that a departure
	 * is already going through the normal transactional withdrawal
	 * path.
	 */
	var/tmp/obj/item/transactional_removal = null


/obj/structure/experimental_home_safe/Initialize(mapload)
	. = ..()

	if(istext(safe_id) && length(safe_id))
		if(!SShousing.register_safe(safe_id, src))
			return INITIALIZE_HINT_QDEL

		load_persistent_contents()

		return .

	if(mapload)
		return INITIALIZE_HINT_LATELOAD

	if(!bind_to_current_property())
		return .

	if(!SShousing.register_safe(safe_id, src))
		return INITIALIZE_HINT_QDEL

	load_persistent_contents()

	return .

/obj/structure/experimental_home_safe/LateInitialize()
	. = ..()

	if(istext(safe_id) && length(safe_id))
		return

	if(!bind_to_current_property())
		return

	if(!SShousing.register_safe(safe_id, src))
		qdel(src)
		return

	load_persistent_contents()


/datum/component/storage/concrete/experimental_safe/slave_can_insert_object(
	datum/component/storage/slave,
	obj/item/I,
	stop_messages = FALSE,
	mob/M
)
	var/obj/structure/experimental_home_safe/safe = parent

	if(!istype(safe))
		return FALSE

	if(!I?.experimental_can_persist_in_safe())
		if(M)
			to_chat(M, span_warning("[I] cannot be stored persistently in [safe]."))

		return FALSE

	if(isnull(safe.get_free_persistent_slot()))
		if(M)
			to_chat(M, span_warning("[safe] has no free persistent slots."))

		return FALSE

	return TRUE


/datum/component/storage/concrete/experimental_safe/_insert_physical_item(obj/item/I, override = FALSE)
	var/obj/structure/experimental_home_safe/safe = parent

	if(!istype(safe))
		return FALSE

	if(!I?.experimental_can_persist_in_safe())
		return FALSE

	var/slot = safe.get_free_persistent_slot()

	if(isnull(slot))
		return FALSE

	/*
	 * move the item physically first.
	 *
	 * If the disk transaction then fails, returning FALSE causes the
	 * normal storage code to put the item back into the user's hand
	 * or onto the turf.
	 */
	if(!..())
		return FALSE

	I.experimental_safe_slot = slot

	if(!SShousing.write_safe_slot(safe.safe_id, slot, I))
		I.experimental_safe_slot = null

		log_world(
			"EXPERIMENTAL HOUSING: Failed persistent deposit into safe '[safe.safe_id]' slot [slot]."
		)

		return FALSE

	log_game(
		"EXPERIMENTAL HOUSING: Deposited [I] ([I.type]) into safe '[safe.safe_id]' slot [slot]."
	)

	return TRUE


/datum/component/storage/concrete/experimental_safe/remove_from_storage(atom/movable/AM, atom/new_location)
	if(!istype(AM, /obj/item))
		return FALSE

	var/obj/item/I = AM
	var/obj/structure/experimental_home_safe/safe = parent

	if(!istype(safe))
		return FALSE

	var/slot = I.experimental_safe_slot

	/*
	 * safe destruction/property reconstruction must not alter the
	 * persistent backend.
	 */
	if(suppress_persistence || isnull(slot))
		return ..()

	/*
	 * TRANSACTIONAL WITHDRAWAL
	 *
	 * the disk record disappears BEFORE the physical item is allowed
	 * to leave.
	 *
	 * therefore a crash between the two operations can lose the item,
	 * but it cannot duplicate it.
	 */
	if(!SShousing.delete_safe_slot(safe.safe_id, slot))
		log_world(
			"EXPERIMENTAL HOUSING: Refusing withdrawal from safe '[safe.safe_id]' slot [slot] because its persistent record could not be removed."
		)

		return FALSE

	transactional_removal = I

	var/success = ..()

	transactional_removal = null

	if(!success)
		/*
		 * physical withdrawal somehow failed after the record was
		 * removed. Recreate the record while the item is still here.
		 */
		if(!SShousing.write_safe_slot(safe.safe_id, slot, I))
			log_world(
				"EXPERIMENTAL HOUSING: OUGH FUCK! Could not roll back safe '[safe.safe_id]' slot [slot] after failed withdrawal."
			)

		return FALSE

	I.experimental_safe_slot = null

	log_game(
		"EXPERIMENTAL HOUSING: Withdrew [I] ([I.type]) from safe '[safe.safe_id]' slot [slot]."
	)

	return TRUE


/datum/component/storage/concrete/experimental_safe/_remove_and_refresh(
	datum/source,
	atom/movable/thing
)
	. = ..()

	if(suppress_persistence)
		return

	if(!istype(thing, /obj/item))
		return

	var/obj/item/I = thing

	/*
	 * normal withdrawals already deleted their disk record before
	 * forceMove() happened.
	 */
	if(I == transactional_removal)
		return

	var/slot = I.experimental_safe_slot

	if(isnull(slot))
		return

	var/obj/structure/experimental_home_safe/safe = parent

	if(!istype(safe))
		return

	/*
	 * FALLBACK CONSISTENCY GUARD
	 *
	 * some unrelated code could theoretically forceMove() an item out
	 * of the safe without using remove_from_storage().
	 *
	 * if that happens somehow, immediately delete the backing record.
	 *
	 * uf deletion fails, put the item back into the safe rather than
	 * allowing disk and runtime state to disagree.
	 */
	if(!SShousing.delete_safe_slot(safe.safe_id, slot))
		log_world(
			"EXPERIMENTAL HOUSING: Unexpected removal from safe '[safe.safe_id]' slot [slot] could not be committed. Returning item to safe."
		)

		I.forceMove(safe)
		return

	I.experimental_safe_slot = null

	log_world(
		"EXPERIMENTAL HOUSING: Caught non-standard removal of [I] from safe '[safe.safe_id]' slot [slot]; persistent record removed."
	)

/obj/structure/experimental_home_safe/proc/generate_safe_id(property_id)
	if(!istext(property_id) || !length(property_id))
		return null

	var/property_slug = sanitize_filename(property_id)

	for(var/attempt in 1 to 20)
		/*
		 * we only need to generate this once.
		 *
		 * da generated value is subsequently stored in the property's
		 * DMM, so it does NOT change between rounds.
		 */
		var/hash = md5(
			"[property_id]|[world.realtime]|[world.time]|[rand(1, 2147483647)]|\ref[src]|[attempt]"
		)

		var/candidate = "[property_slug]_safe_[copytext(hash, 1, 13)]"

		var/obj/structure/experimental_home_safe/existing = SShousing.safe_instances[candidate]

		if(existing && !QDELETED(existing))
			continue

		return candidate

	return null


/obj/structure/experimental_home_safe/proc/bind_to_current_property()
	if(!SShousing)
		return FALSE

	/*
	 * already bound.
	 */
	if(istext(safe_id) && length(safe_id))
		return TRUE

	var/turf/T = get_turf(src)

	if(!T)
		return FALSE

	var/property_id = SShousing.get_property_id_at_turf(T)

	if(!istext(property_id) || !length(property_id))
		log_world(
			"EXPERIMENTAL HOUSING: Home safe at [AREACOORD(src)] is not inside a registered property."
		)

		return FALSE

	var/generated_id = generate_safe_id(property_id)

	if(!generated_id)
		log_world(
			"EXPERIMENTAL HOUSING: Failed to generate safe ID for property '[property_id]' at [AREACOORD(src)]."
		)

		return FALSE

	bound_property_id = property_id
	safe_id = generated_id

	log_world(
		"EXPERIMENTAL HOUSING: New safe '[safe_id]' bound to property '[bound_property_id]' at [AREACOORD(src)]."
	)

	return TRUE
