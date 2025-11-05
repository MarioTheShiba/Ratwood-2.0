// Helper procs for affix aggregation on mobs

/mob/living/proc/get_total_affix_stat(stat, default = 0)
	// Sums a numeric affix stat across all equipped items
	var/total = 0
	if(!stat)
		return default
	var/list/items = get_equipped_items()
	if(items)
		for(var/obj/item/I in items)
			if(hascall(I, "get_affix_stat"))
				var/val = call(I, "get_affix_stat")(stat, 0)
				if(isnum(val))
					total += val
	return total
