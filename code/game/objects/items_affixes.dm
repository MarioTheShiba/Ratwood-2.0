// Item-side affix integration: slots, naming, and simple stat aggregation
#include "../../__DEFINES/affixes_defines.dm"
#include "../../datums/affixes/names.dm"

/obj/item
    /// Rolled affix instances applied to this item (template ids in base_id)
    var/datum/affix/prefix_affix
    var/datum/affix/suffix_affix
    /// Additional rolled affixes (rare items can exceed prefix/suffix)
    var/list/extra_affixes
    /// The original base name used to compose affixed names
    var/affix_base_name
    /// Aggregated numeric modifiers from affixes
    var/list/affix_stats
    /// Rarity tier for display and rules
    var/item_rarity = ITEM_RARITY_NORMAL

/obj/item/Initialize()
    . = ..()
    if(!affix_base_name)
        // Capture the original name at first init for stable renaming
        affix_base_name = name
    if(!affix_stats)
        affix_stats = list()
    if(!extra_affixes)
        extra_affixes = list()

/// Apply a registry affix template to this item. Rolls RNG and stores an instance.
/// If replace is FALSE and the slot is occupied, returns FALSE.
/obj/item/proc/apply_affix(datum/affix/template, replace = FALSE)
    if(!template || !istype(template, /datum/affix))
        return FALSE
    if(!template.can_apply(src))
        return FALSE
    var/datum/affix/inst = template.create_instance()
    if(template.kind == AFFIX_KIND_PREFIX)
        if(prefix_affix && !replace)
            return FALSE
        if(prefix_affix)
            prefix_affix.unapply(src)
        prefix_affix = inst
        prefix_affix.apply(src)
    else if(template.kind == AFFIX_KIND_SUFFIX)
        if(suffix_affix && !replace)
            return FALSE
        if(suffix_affix)
            suffix_affix.unapply(src)
        suffix_affix = inst
        suffix_affix.apply(src)
    else
        return FALSE
    recalc_affix_effects()
    update_affix_name()
    return TRUE

/// Remove an affix by kind (AFFIX_KIND_PREFIX or AFFIX_KIND_SUFFIX)
/obj/item/proc/remove_affix(kind)
    if(kind == AFFIX_KIND_PREFIX && prefix_affix)
        prefix_affix.unapply(src)
        prefix_affix = null
    else if(kind == AFFIX_KIND_SUFFIX && suffix_affix)
        suffix_affix.unapply(src)
        suffix_affix = null
    recalc_affix_effects()
    update_affix_name()

/// Rebuild the affix_stats cache by summing numeric keys across affixes
/obj/item/proc/recalc_affix_effects()
    affix_stats = list()
    var/list/sources = list()
    if(prefix_affix)
        sources += prefix_affix
    if(suffix_affix)
        sources += suffix_affix
    if(extra_affixes)
        for(var/datum/affix/E in extra_affixes)
            if(E)
                sources += E
    for(var/datum/affix/A in sources)
        if(!A || !A.stat_mods)
            continue
        for(var/K in A.stat_mods)
            var/V = A.stat_mods[K]
            if(isnum(V))
                affix_stats[K] = (affix_stats[K] || 0) + V
            // Non-numeric stats ignored in aggregator; use hooks where needed

/// Compose item name from base + affixes
/obj/item/proc/update_affix_name()
    var/base = affix_base_name || name
    var/combined
    if(item_rarity == ITEM_RARITY_MAGIC)
        // Magic items show explicit prefix/suffix in the name
        var/list/parts = list()
        if(prefix_affix)
            parts += prefix_affix.display_name
        parts += base
        if(suffix_affix && suffix_affix.display_name)
            parts += suffix_affix.display_name
        combined = jointext(parts, " ")
    else if(item_rarity == ITEM_RARITY_RARE)
        // Rare items have fully generated names, not using the base name
        combined = generate_rare_item_name(base)
    else
        combined = base

    // Apply rarity color to entire name
    var/color = get_rarity_color()
    if(color)
        name = "<font color='[color]'>[combined]</font>"
    else
        name = combined

/// Generate a simple rare item name from a base name
/obj/item/proc/generate_rare_item_name(base)
    if(istype(src, /obj/item/rogueweapon))
        return affix_generate_weapon_rare_name()
    if(istype(src, /obj/item/clothing))
        return affix_generate_armor_rare_name()
    return affix_generate_generic_rare_name()

/// Return the display color hex for this item's rarity
/obj/item/proc/get_rarity_color()
    switch(item_rarity)
        if(ITEM_RARITY_MAGIC)
            return ITEM_RARITY_COLOR_MAGIC
        if(ITEM_RARITY_RARE)
            return ITEM_RARITY_COLOR_RARE
        else
            return ITEM_RARITY_COLOR_NORMAL

/// Add an extra (implicit) affix that doesn't affect the name directly
/obj/item/proc/add_extra_affix(datum/affix/template)
    if(!template || !istype(template, /datum/affix))
        return FALSE
    if(!template.can_apply(src))
        return FALSE
    var/datum/affix/inst = template.create_instance()
    if(!extra_affixes)
        extra_affixes = list()
    extra_affixes += inst
    inst.apply(src)
    recalc_affix_effects()
    return TRUE

/// Remove all affixes and reset rarity to normal
/obj/item/proc/clear_all_affixes()
    if(prefix_affix)
        prefix_affix.unapply(src)
        prefix_affix = null
    if(suffix_affix)
        suffix_affix.unapply(src)
        suffix_affix = null
    if(extra_affixes)
        for(var/datum/affix/E in extra_affixes)
            if(E)
                E.unapply(src)
        extra_affixes.Cut()
    affix_stats = list()
    item_rarity = ITEM_RARITY_NORMAL
    update_affix_name()

/// Get combined numeric stat from affixes, or default
/obj/item/proc/get_affix_stat(stat, default = 0)
    if(!affix_stats || !(stat in affix_stats))
        return default
    return affix_stats[stat]

/// Summarize affix effects for examine
/obj/item/proc/get_affix_summary()
    var/list/lines = list()
    if(prefix_affix)
        var/_ps = prefix_affix.get_effect_summary(src)
        if(_ps)
            lines += "[prefix_affix.display_name]: [_ps]"
        else
            lines += "[prefix_affix.display_name]"
    if(suffix_affix)
        var/_ss = suffix_affix.get_effect_summary(src)
        if(_ss)
            lines += "[suffix_affix.display_name]: [_ss]"
        else
            lines += "[suffix_affix.display_name]"
    if(extra_affixes && length(extra_affixes))
        for(var/datum/affix/E in extra_affixes)
            if(E)
                var/_es = E.get_effect_summary(src)
                if(_es)
                    lines += "[E.display_name]: [_es]"
                else
                    lines += "[E.display_name]"
    return jointext(lines, "\n")

// --- Rolling helpers for Magic/Rare ---

/// Roll and apply affixes according to rarity rules
/obj/item/proc/reroll_item_rarity(new_rarity)
    clear_all_affixes()
    item_rarity = new_rarity
    var/list/selected = list()
    if(new_rarity == ITEM_RARITY_MAGIC)
        var/count = rand(1, 2)
        // Pools declared upfront
        var/list/prefix_pool = find_affixes_for_item(src, AFFIX_KIND_PREFIX)
        var/list/suffix_pool = find_affixes_for_item(src, AFFIX_KIND_SUFFIX)
        if(count == 1)
            // Randomly choose either prefix or suffix first
            var/first_kind = pick(AFFIX_KIND_PREFIX, AFFIX_KIND_SUFFIX)
            var/datum/affix/choice
            if(first_kind == AFFIX_KIND_PREFIX)
                choice = weighted_pick_affix(prefix_pool, selected)
                if(!choice)
                    choice = weighted_pick_affix(suffix_pool, selected)
            else
                choice = weighted_pick_affix(suffix_pool, selected)
                if(!choice)
                    choice = weighted_pick_affix(prefix_pool, selected)
            if(choice)
                if(choice.kind == AFFIX_KIND_PREFIX)
                    apply_affix(choice, TRUE)
                else
                    apply_affix(choice, TRUE)
                selected += choice.id
        else
            // Try to get one of each when rolling 2
            var/datum/affix/P = weighted_pick_affix(prefix_pool)
            if(P)
                apply_affix(P, TRUE)
                selected += P.id
            var/datum/affix/S = weighted_pick_affix(suffix_pool, selected)
            if(!S)
                // Fallback: another prefix
                var/datum/affix/PP = weighted_pick_affix(prefix_pool, selected)
                if(PP)
                    apply_affix(PP, FALSE)
                    selected += PP.id
            else
                apply_affix(S, TRUE)
                selected += S.id

    else if(new_rarity == ITEM_RARITY_RARE)
        var/total = rand(2, 6)
        var/list/pool_all = list()
        var/list/prefix_pool2 = find_affixes_for_item(src, AFFIX_KIND_PREFIX)
        var/list/suffix_pool2 = find_affixes_for_item(src, AFFIX_KIND_SUFFIX)
        for(var/_id in prefix_pool2)
            var/datum/affix/A = prefix_pool2[_id]
            if(!A.tags || !A.tags["admin_only"]) pool_all += A
        for(var/_id2 in suffix_pool2)
            var/datum/affix/B = suffix_pool2[_id2]
            if(!B.tags || !B.tags["admin_only"]) pool_all += B
        var/picked = 0
        while(picked < total && length(pool_all) > 0)
            var/datum/affix/choice = weighted_pick_affix_from_list(pool_all, selected)
            if(!choice)
                break
            // Apply to slots if possible, then extras
            if(choice.kind == AFFIX_KIND_PREFIX && !prefix_affix)
                apply_affix(choice, TRUE)
            else if(choice.kind == AFFIX_KIND_SUFFIX && !suffix_affix)
                apply_affix(choice, TRUE)
            else
                add_extra_affix(choice)
            selected += choice.id
            picked++

    update_affix_name()
    return TRUE

/// Weighted pick from registry map {id=>datum}; skip already selected/conflicts
/proc/weighted_pick_affix(list/map, list/selected_ids)
    if(!map || !length(map))
        return null
    var/list/candidates = list()
    for(var/_id in map)
        var/datum/affix/A = map[_id]
        if(A && (!A.tags || !A.tags["admin_only"]))
            if(!selected_ids || !(_id in selected_ids))
                candidates += A
    return weighted_pick_affix_from_list(candidates, selected_ids)

/// Weighted pick from a simple list of affix datums; respects conflicts_with
/proc/weighted_pick_affix_from_list(list/candidates, list/selected_ids)
    if(!candidates || !length(candidates))
        return null
    var/total_weight = 0
    var/list/weights = list()
    for(var/datum/affix/A in candidates)
        if(!A)
            continue
        // conflict check
        if(selected_ids && length(selected_ids) && A.conflicts_with && length(A.conflicts_with))
            var/conflict = FALSE
            for(var/C in A.conflicts_with)
                if(C in selected_ids)
                    conflict = TRUE; break
            if(conflict)
                continue
        var/W = max(1, A.rarity_weight)
        total_weight += W
        weights[A] = W
    if(total_weight <= 0 || !length(weights))
        return null
    var/r = rand(1, total_weight)
    var/acc = 0
    for(var/datum/affix/B in weights)
        acc += weights[B]
        if(r <= acc)
            return B
    return null

// ADMIN TOOLING: Right-click verb on held item to add/remove affixes for testing/debug
/obj/item/verb/affix_admin_menu()
    set name = "Add Affix"
    set category = "Admin"
    set popup_menu = 1
    set src in usr // appears when the item is in the user's inventory/hands

    // Require admin rights
    if(!usr || !usr.client || !check_rights(R_ADMIN))
        return

    // Sanity: must be holding the item
    if(!(src in usr.contents))
        to_chat(usr, span_warning("You must hold [src] to modify its affixes."))
        return

    var/state = GLOB.affix_god_roll ? "ENABLED" : "DISABLED"
    var/toggle_label = "God-rolling: [state]"
    var/list/main_actions = list(
        "Add Affix",
        "Roll Magic (1-2)",
        "Roll Rare (2-6)",
        "Remove affix (All)",
        "Remove Suffix",
        "Remove Prefix",
    )
    // Insert toggle after Rare roll
    main_actions.Insert(4, toggle_label)
    var/action = input(usr, "What would you like to do with [src]?", "Affix Admin") as null|anything in main_actions
    if(!action)
        return

    // Handle dynamic toggle first
    if(action == toggle_label)
        GLOB.affix_god_roll = !GLOB.affix_god_roll
        var/state2 = GLOB.affix_god_roll ? "ENABLED" : "DISABLED"
        to_chat(usr, span_notice("God-rolling is now [state2]."))
        return

    switch(action)
        if("Add Affix")
            // Robust selection: present readable labels, then map to internal kind
            var/list/kind_labels = list("Prefix", "Suffix")
            var/kind_choice = input(usr, "Apply a Prefix or a Suffix?", "Affix Kind") as null|anything in kind_labels
            if(!kind_choice)
                return
            var/kind
            if(istext(kind_choice))
                var/lc = lowertext(kind_choice)
                if(lc == "prefix")
                    kind = AFFIX_KIND_PREFIX
                else if(lc == "suffix")
                    kind = AFFIX_KIND_SUFFIX
            if(!kind)
                // Fallback default
                kind = AFFIX_KIND_PREFIX

            // Build available tiers from eligible affixes for this item/kind
            var/list/eligible_all = find_affixes_for_item(src, kind)
            if(!eligible_all || !length(eligible_all))
                to_chat(usr, span_warning("No [kind] affixes are eligible for this item."))
                return
            var/list/tiers = list()
            for(var/_id in eligible_all)
                var/datum/affix/A = eligible_all[_id]
                if(!(A.tier in tiers))
                    tiers += A.tier
            tiers = sortList(tiers)
            var/list/tier_choices = list("Any Tier")
            for(var/i = 1, i <= length(tiers), i++)
                var/T = tiers[i]
                tier_choices += "Tier [T]"
            var/tier_pick = input(usr, "Filter by tier?", "Affix Tier") as null|anything in tier_choices
            if(!tier_pick)
                return
            var/min_tier = 1
            var/max_tier = 1000000000
            if(tier_pick != "Any Tier")
                // Parse number after "Tier "
                var/tier_text = copytext(tier_pick, 6)
                var/tier_num = text2num(tier_text)
                if(isnum(tier_num) && tier_num > 0)
                    min_tier = tier_num
                    max_tier = tier_num

            // Recompute eligible list with tier filter
            var/list/eligible = find_affixes_for_item(src, kind, min_tier, max_tier)
            if(!eligible || !length(eligible))
                to_chat(usr, span_warning("No affixes match that filter."))
                return

            // Build selection list: "Display Name [id] — summary"
            var/list/choice_map = list()
            var/list/choice_list = list()
            for(var/_id in eligible)
                var/datum/affix/A = eligible[_id]
                var/label = "[A.display_name || _id] ([A.id])"
                choice_map[label] = A
                choice_list += label
            choice_list = sortList(choice_list)

            var/sel_label = input(usr, "Choose an affix to apply", "Select Affix") as null|anything in choice_list
            if(!sel_label)
                return
            var/datum/affix/template = choice_map[sel_label]
            if(!template)
                return

            // Confirm replace if that slot is occupied
            var/occupied = (kind == AFFIX_KIND_PREFIX) ? (prefix_affix != null) : (suffix_affix != null)
            var/replace = FALSE
            if(occupied)
                replace = alert(usr, "[kind == AFFIX_KIND_PREFIX ? "Prefix" : "Suffix"] already present. Replace it?", "Confirm", "Yes", "No") == "Yes"
                if(!replace)
                    return

            var/success = apply_affix(template, replace)
            if(success)
                to_chat(usr, span_notice("Applied [template.display_name] to [src]."))
            else
                to_chat(usr, span_warning("Failed to apply [template.display_name] to [src]."))

        if("Roll Magic (1-2)")
            reroll_item_rarity(ITEM_RARITY_MAGIC)
            to_chat(usr, span_notice("Rolled Magic affixes for [src]."))

        if("Roll Rare (2-6)")
            reroll_item_rarity(ITEM_RARITY_RARE)
            to_chat(usr, span_notice("Rolled Rare affixes for [src]."))

        if("Remove affix (All)")
            if(prefix_affix || suffix_affix)
                remove_affix(AFFIX_KIND_PREFIX)
                remove_affix(AFFIX_KIND_SUFFIX)
                to_chat(usr, span_notice("Removed all affixes from [src]."))
            else
                to_chat(usr, span_info("[src] has no affixes."))

        if("Remove Suffix")
            if(suffix_affix)
                remove_affix(AFFIX_KIND_SUFFIX)
                to_chat(usr, span_notice("Removed suffix from [src]."))
            else
                to_chat(usr, span_info("[src] has no suffix."))

        if("Remove Prefix")
            if(prefix_affix)
                remove_affix(AFFIX_KIND_PREFIX)
                to_chat(usr, span_notice("Removed prefix from [src]."))
            else
                to_chat(usr, span_info("[src] has no prefix."))
