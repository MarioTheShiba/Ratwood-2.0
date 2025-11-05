// I played too much Diablo 2 so I might as well add gambling to the game. We need gambling.

/// Affix kinds
#define AFFIX_KIND_PREFIX "prefix"
#define AFFIX_KIND_SUFFIX "suffix"

/**
 * /datum/affix
 * Canonical definition for a single affix. Instances are stored in GLOB.affix_registry
 * and applied to items by future forge/loot systems.
 */
/datum/affix
    /// Unique string id (stable; used for save/load)
    var/id
    /// "prefix" or "suffix" (see AFFIX_KIND_* defines)
    var/kind
    /// Displayed part of the name (e.g., "Lucky", "of the Bear")
    var/display_name
    /// Optional short description for manuals/examine
    var/desc

    /// Which item type paths this affix can apply to (list of types)
    var/list/allowed_types
    /// Suggested power tier (1..N); used for gating/rolling
    var/tier = 1
    /// Relative weight for random selection (>=1)
    var/rarity_weight = 1

    /// Simple numeric modifiers keyed by name (e.g., "damage_bonus" = 2)
    var/list/stat_mods
    /// Freeform tags (e.g., list("elemental" = TRUE, "fire" = TRUE))
    var/list/tags
    /// List of affix ids or group tags that this affix cannot coexist with
    var/list/conflicts_with
    /// If TRUE, this datum is a template entry from the registry (not for direct mutation)
    var/is_template = TRUE
    /// If this is an instance rolled from a template, holds the source template id
    var/base_id

    /// Construct with optional props list (keys match var names)
    New(props)
        if(islist(props))
            for(var/K in props)
                if(istype(K, /list))
                    continue
                if(!(K in vars))
                    continue
                vars[K] = props[K]
        if(!stat_mods)
            stat_mods = list()
        if(!tags)
            tags = list()
        if(!conflicts_with)
            conflicts_with = list()
        if(!allowed_types)
            allowed_types = list()
        ..()

    /// Returns TRUE if this affix could be applied to the given item type
    proc/can_apply(obj/item/I)
        if(!I)
            return FALSE
        if(!kind || (kind != AFFIX_KIND_PREFIX && kind != AFFIX_KIND_SUFFIX))
            return FALSE
        if(!allowed_types || !length(allowed_types))
            // If nothing specified, assume it's globally valid (data authors should usually specify)
            return TRUE
        for(var/path in allowed_types)
            if(ispath(path) && istype(I, path))
                return TRUE
        return FALSE

    /// Short human-readable line for examine/manuals
    proc/get_effect_summary(obj/item/I)
        // Summarize stat_mods with pretty labels and formatting
        if(!stat_mods || !length(stat_mods))
            return desc
        var/list/parts = list()
        for(var/K in stat_mods)
            var/V = stat_mods[K]
            parts += format_stat_for_display(K, V)
        var/line = jointext(parts, ", ")
        if(desc)
            return "[desc] ([line])"
        return line

    /// Pretty-print a single stat line given key and value (number or 2-number range)
    proc/format_stat_for_display(stat_key, raw_value)
        var/list/meta = stat_display_meta(stat_key)
        var/label = meta["label"]
        var/is_percent = meta["percent"]
        var/precision = meta["precision"]

        // Range formatting for templates: "min..max Label"
        if(islist(raw_value) && length(raw_value) == 2 && isnum(raw_value[1]) && isnum(raw_value[2]))
            var/minv = min(raw_value[1], raw_value[2])
            var/maxv = max(raw_value[1], raw_value[2])
            if(is_percent)
                minv = round(minv * 100, 10**(-precision))
                maxv = round(maxv * 100, 10**(-precision))
                if(precision <= 0)
                    return "[round(minv)]..[round(maxv)]% [label]"
                else
                    return "[round(minv, 1.0)]..[round(maxv, 1.0)]% [label]"
            else
                if(precision <= 0)
                    return "[round(minv)]..[round(maxv)] [label]"
                else
                    return "[round(minv, 1.0)]..[round(maxv, 1.0)] [label]"

        // Scalar formatting for instances: include sign and optional %
        if(isnum(raw_value))
            var/val = raw_value
            if(is_percent)
                val = val * 100
            var/outval_value
            if(precision <= 0)
                outval_value = "[round(val)]"
            else
                outval_value = "[round(val, 1.0)]"
            var/sign = (raw_value >= 0) ? "+" : ""
            if(is_percent)
                return "[sign][outval_value]% [label]"
            return "[sign][outval_value] [label]"

        // Fallback
        return "[label]: [raw_value]"

    /// Mapping from internal stat keys to pretty labels and formatting hints
    proc/stat_display_meta(stat_key)
        // Defaults
        var/list/meta = list("label" = stat_key, "percent" = FALSE, "precision" = 0)
        switch(stat_key)
            if("damage_fire_bonus")
                meta["label"] = "Fire damage"
                meta["percent"] = FALSE
                meta["precision"] = 0
            if("damage_toxin_bonus")
                meta["label"] = "Poison damage"
                meta["percent"] = FALSE
                meta["precision"] = 0
            if("damage_oxy_bonus")
                meta["label"] = "Asphyxiation damage"
                meta["percent"] = FALSE
                meta["precision"] = 0
            if("damage_pct_bonus")
                meta["label"] = "Enhanced Damage"
                meta["percent"] = TRUE
                meta["precision"] = 0
            if("attack_speed_pct")
                meta["label"] = "Increased Attack Speed"
                meta["percent"] = TRUE
                meta["precision"] = 0
            if("armor_pct")
                meta["label"] = "Armor"
                meta["percent"] = TRUE
                meta["precision"] = 0
            if("knockback_resist")
                meta["label"] = "Knockback resist"
                meta["percent"] = TRUE
                meta["precision"] = 0
            if("reflect_flat")
                meta["label"] = "Thorns"
                meta["percent"] = FALSE
                meta["precision"] = 0
            if("gem_bonus_chance")
                meta["label"] = "Gem find chance"
                meta["percent"] = TRUE
                meta["precision"] = 0
            if("skill_knives_bonus")
                meta["label"] = "Knife-Fighting"
                meta["percent"] = FALSE
                meta["precision"] = 0
            if("skill_swords_bonus")
                meta["label"] = "Sword-Fighting"
                meta["percent"] = FALSE
                meta["precision"] = 0
            if("skill_bows_bonus")
                meta["label"] = "Archery"
                meta["percent"] = FALSE
                meta["precision"] = 0
            if("skill_athletics_bonus")
                meta["label"] = "Athletics"
                meta["percent"] = FALSE
                meta["precision"] = 0
        return meta

    /// Validate configuration; returns null on success or an error string
    proc/validate()
        if(!id || !istext(id))
            return "affix missing text id"
        if(kind != AFFIX_KIND_PREFIX && kind != AFFIX_KIND_SUFFIX)
            return "affix [id] has invalid kind: [kind]"
        if(rarity_weight <= 0)
            return "affix [id] has non-positive rarity_weight"
        if(allowed_types)
            for(var/T in allowed_types)
                if(!ispath(T))
                    return "affix [id] has non-type in allowed_types: [T]"
        return null

    // Hook stubs. Future item integration will call these where appropriate.

    /// Create a rolled instance of this affix, resolving any RNG ranges into fixed values
    proc/create_instance()
        var/datum/affix/inst = new
        // Copy scalar fields
        inst.id = id
        inst.base_id = id
        inst.kind = kind
        inst.display_name = display_name
        inst.desc = desc
        inst.tier = tier
        inst.rarity_weight = rarity_weight
        inst.is_template = FALSE
        // Copy lists safely
        inst.allowed_types = allowed_types ? allowed_types.Copy() : list()
        inst.tags = tags ? tags.Copy() : list()
        inst.conflicts_with = conflicts_with ? conflicts_with.Copy() : list()
        // Resolve stat_mods, turning ranges into concrete values
        inst.stat_mods = list()
        if(stat_mods)
            for(var/K in stat_mods)
                var/V = stat_mods[K]
                inst.stat_mods[K] = resolve_stat_value(V)
        return inst

    /// Resolve a stat value; if it's a 2-number list, roll a float in [min,max]
    proc/resolve_stat_value(V)
        if(isnum(V))
            return V
        if(islist(V) && length(V) == 2 && isnum(V[1]) && isnum(V[2]))
            var/minv = min(V[1], V[2])
            var/maxv = max(V[1], V[2])
            if(GLOB.affix_god_roll)
                return maxv
            return rand_float(minv, maxv)
        return V

    /// Random float helper in [min,max]
    proc/rand_float(minv, maxv)
        if(maxv <= minv)
            return minv
        // Generate a thousandth-resolution float to avoid heavy math
        var/roll = rand(0, 1000) / 1000.0
        return minv + (maxv - minv) * roll

    /// Called when affix is applied to the item (once). Return TRUE on success.
    proc/apply(obj/item/I)
        return TRUE

    /// Called when affix is removed from the item (once). Return TRUE on success.
    proc/unapply(obj/item/I)
        return TRUE

    /// Called when item is equipped
    proc/on_equip(obj/item/I, mob/living/user)
        return

    /// Called when item is unequipped
    proc/on_unequip(obj/item/I, mob/living/user)
        return

    /// Called when the item successfully hits a target
    proc/on_attack_hit(obj/item/I, mob/living/attacker, atom/movable/target, damage)
        return

    /// Called when the item (armor) wearer takes damage
    proc/on_take_damage(obj/item/I, mob/living/wearer, damage, damage_type)
        return

    /// Optional periodic processing while item exists/equipped
    proc/on_process(obj/item/I)
        return

    /// Color to use when displaying this affix in an item name; based on tier
    proc/get_name_color()
        // Simple rarity palette by tier; adjust to taste
        switch(tier)
            if(1)
                return "#c8c8c8" // common grey
            if(2)
                return "#5ac85a" // green
            if(3)
                return "#4aa3ff" // blue
            if(4)
                return "#b48ead" // purple
            if(5)
                return "#ffae00" // orange
        return "#ff4d4d" // red for tier 6+
