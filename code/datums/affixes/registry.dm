// Affix registry: global list, builders, and helpers

/// Build and return the affix registry list keyed by id -> /datum/affix
proc/build_affix_registry()
    var/list/L = list()
    // Seed example affixes. Keep deterministic and idempotent.

    // Flaming (prefix) — weapons only; straight +fire damage (RNG 5..15)
    var/datum/affix/A = new /datum/affix(list(
        "id" = "flaming",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Flaming",
        "desc" = "Attacks deal extra fire damage.",
        "allowed_types" = list(/obj/item/rogueweapon),
        "tier" = 2,
        "rarity_weight" = 10,
        "stat_mods" = list(
            // Extra fire (burn) damage applied on hit
            "damage_fire_bonus" = list(5, 15),
        ),
        "tags" = list("elemental" = TRUE, "fire" = TRUE)
    ))
    L[A.id] = A

    // Venomous (prefix) — weapons; extra toxin damage per hit
    A = new /datum/affix(list(
        "id" = "venomous",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Venomous",
        "desc" = "Attacks deal extra poison damage.",
        "allowed_types" = list(/obj/item/rogueweapon),
        "tier" = 2,
        "rarity_weight" = 10,
        "stat_mods" = list(
            "damage_toxin_bonus" = list(2, 6),
        ),
        "tags" = list("elemental" = TRUE, "toxin" = TRUE)
    ))
    L[A.id] = A

    // Choking (prefix) — weapons; extra oxygen (asphyxiation) damage per hit
    A = new /datum/affix(list(
        "id" = "choking",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Choking",
        "desc" = "Attacks suffocate the target slightly.",
        "allowed_types" = list(/obj/item/rogueweapon),
        "tier" = 2,
        "rarity_weight" = 9,
        "stat_mods" = list(
            "damage_oxy_bonus" = list(2, 6),
        ),
        "tags" = list("elemental" = TRUE, "oxygen" = TRUE)
    ))
    L[A.id] = A

    // Quick (prefix) — weapons; increased attack speed (reduces click cooldown)
    A = new /datum/affix(list(
        "id" = "quick",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Quick",
        "desc" = "Strikes faster than normal.",
        "allowed_types" = list(
            /obj/item/rogueweapon,
            /obj/item/gun/ballistic/revolver/grenadelauncher/bow,
            /obj/item/gun/ballistic/revolver/grenadelauncher/crossbow
        ),
        "tier" = 2,
        "rarity_weight" = 12,
        "stat_mods" = list(
            "attack_speed_pct" = list(0.05, 0.20)
        )
    ))
    L[A.id] = A

    // of Thorns (suffix) — torso armor; flat reflect to attackers
    A = new /datum/affix(list(
        "id" = "of_thorns",
        "kind" = AFFIX_KIND_SUFFIX,
        "display_name" = "of Thorns",
        "desc" = "Returns some damage to attackers.",
        "allowed_types" = list(/obj/item/clothing/suit/roguetown/armor),
        "tier" = 2,
        "rarity_weight" = 10,
        "stat_mods" = list(
            "reflect_flat" = list(1, 3)
        ),
        "tags" = list("defensive" = TRUE)
    ))
    L[A.id] = A

    // Enhanced Damage% prefix line (applies to melee weapons, bows, crossbows)
    // T1: Jagged — +1%..5%
    A = new /datum/affix(list(
        "id" = "jagged",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Jagged",
        "desc" = "Serrated edge or tuned draw; slightly more damaging.",
        "allowed_types" = list(
            /obj/item/rogueweapon,
            /obj/item/gun/ballistic/revolver/grenadelauncher/bow,
            /obj/item/gun/ballistic/revolver/grenadelauncher/crossbow
        ),
        "tier" = 1,
        "rarity_weight" = 20,
        "stat_mods" = list(
            "damage_pct_bonus" = list(0.01, 0.05)
        )
    ))
    L[A.id] = A

    // T2: Deadly — +6%..10%
    A = new /datum/affix(list(
        "id" = "deadly",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Deadly",
        "desc" = "Notably more deadly.",
        "allowed_types" = list(
            /obj/item/rogueweapon,
            /obj/item/gun/ballistic/revolver/grenadelauncher/bow,
            /obj/item/gun/ballistic/revolver/grenadelauncher/crossbow
        ),
        "tier" = 2,
        "rarity_weight" = 15,
        "stat_mods" = list(
            "damage_pct_bonus" = list(0.06, 0.10)
        )
    ))
    L[A.id] = A

    // T3: Vicious — +11%..20%
    A = new /datum/affix(list(
        "id" = "vicious",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Vicious",
        "desc" = "Cruel craftsmanship, much more damaging.",
        "allowed_types" = list(
            /obj/item/rogueweapon,
            /obj/item/gun/ballistic/revolver/grenadelauncher/bow,
            /obj/item/gun/ballistic/revolver/grenadelauncher/crossbow
        ),
        "tier" = 3,
        "rarity_weight" = 10,
        "stat_mods" = list(
            "damage_pct_bonus" = list(0.11, 0.20)
        )
    ))
    L[A.id] = A

    // T4: Savage — +21%..50%
    A = new /datum/affix(list(
        "id" = "savage",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Savage",
        "desc" = "Savage power courses through it.",
        "allowed_types" = list(
            /obj/item/rogueweapon,
            /obj/item/gun/ballistic/revolver/grenadelauncher/bow,
            /obj/item/gun/ballistic/revolver/grenadelauncher/crossbow
        ),
        "tier" = 4,
        "rarity_weight" = 6,
        "stat_mods" = list(
            "damage_pct_bonus" = list(0.21, 0.50)
        )
    ))
    L[A.id] = A

    // T5: Ferocious — +50%..105%
    A = new /datum/affix(list(
        "id" = "ferocious",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Ferocious",
        "desc" = "Unbridled ferocity; massively increased damage.",
        "allowed_types" = list(
            /obj/item/rogueweapon,
            /obj/item/gun/ballistic/revolver/grenadelauncher/bow,
            /obj/item/gun/ballistic/revolver/grenadelauncher/crossbow
        ),
        "tier" = 5,
        "rarity_weight" = 3,
        "stat_mods" = list(
            "damage_pct_bonus" = list(0.50, 1.05)
        )
    ))
    L[A.id] = A

    // T6: Graggarite — +105%..300% (admin-only)
    A = new /datum/affix(list(
        "id" = "graggarite",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Graggarite",
        "desc" = "Legendary workmanship; beyond mortal ken.",
        "allowed_types" = list(
            /obj/item/rogueweapon,
            /obj/item/gun/ballistic/revolver/grenadelauncher/bow,
            /obj/item/gun/ballistic/revolver/grenadelauncher/crossbow
        ),
        "tier" = 6,
        "rarity_weight" = 1,
        "stat_mods" = list(
            "damage_pct_bonus" = list(1.05, 3.00)
        ),
        "tags" = list("unobtainium" = TRUE, "admin_only" = TRUE)
    ))
    L[A.id] = A

    // Skill prefixes: +Knife/Sword/Bows; +Athletics (boots/amulets). T3/T4/T5 = +1/+2/+3
    // Knife-Fighting (daggers/knives)
    A = new /datum/affix(list(
        "id" = "adept_knifefighter",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Adept",
        "desc" = "+1 Knife-Fighting.",
        "allowed_types" = list(/obj/item/rogueweapon/huntingknife),
        "tier" = 3,
        "rarity_weight" = 10,
        "stat_mods" = list("skill_knives_bonus" = 1)
    ))
    L[A.id] = A
    A = new /datum/affix(list(
        "id" = "expert_knifefighter",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Expert",
        "desc" = "+2 Knife-Fighting.",
        "allowed_types" = list(/obj/item/rogueweapon/huntingknife),
        "tier" = 4,
        "rarity_weight" = 6,
        "stat_mods" = list("skill_knives_bonus" = 2)
    ))
    L[A.id] = A
    A = new /datum/affix(list(
        "id" = "master_knifefighter",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Master",
        "desc" = "+3 Knife-Fighting.",
        "allowed_types" = list(/obj/item/rogueweapon/huntingknife),
        "tier" = 5,
        "rarity_weight" = 3,
        "stat_mods" = list("skill_knives_bonus" = 3)
    ))
    L[A.id] = A

    // Sword-Fighting (swords)
    A = new /datum/affix(list(
        "id" = "adept_swordfighter",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Adept",
        "desc" = "+1 Sword-Fighting.",
        "allowed_types" = list(/obj/item/rogueweapon/sword),
        "tier" = 3,
        "rarity_weight" = 10,
        "stat_mods" = list("skill_swords_bonus" = 1)
    ))
    L[A.id] = A
    A = new /datum/affix(list(
        "id" = "expert_swordfighter",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Expert",
        "desc" = "+2 Sword-Fighting.",
        "allowed_types" = list(/obj/item/rogueweapon/sword),
        "tier" = 4,
        "rarity_weight" = 6,
        "stat_mods" = list("skill_swords_bonus" = 2)
    ))
    L[A.id] = A
    A = new /datum/affix(list(
        "id" = "master_swordfighter",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Master",
        "desc" = "+3 Sword-Fighting.",
        "allowed_types" = list(/obj/item/rogueweapon/sword),
        "tier" = 5,
        "rarity_weight" = 3,
        "stat_mods" = list("skill_swords_bonus" = 3)
    ))
    L[A.id] = A

    // Archery (bows)
    A = new /datum/affix(list(
        "id" = "adept_archer",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Adept",
        "desc" = "+1 Archery.",
        "allowed_types" = list(/obj/item/gun/ballistic/revolver/grenadelauncher/bow),
        "tier" = 3,
        "rarity_weight" = 10,
        "stat_mods" = list("skill_bows_bonus" = 1)
    ))
    L[A.id] = A
    A = new /datum/affix(list(
        "id" = "expert_archer",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Expert",
        "desc" = "+2 Archery.",
        "allowed_types" = list(/obj/item/gun/ballistic/revolver/grenadelauncher/bow),
        "tier" = 4,
        "rarity_weight" = 6,
        "stat_mods" = list("skill_bows_bonus" = 2)
    ))
    L[A.id] = A
    A = new /datum/affix(list(
        "id" = "master_archer",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Master",
        "desc" = "+3 Archery.",
        "allowed_types" = list(/obj/item/gun/ballistic/revolver/grenadelauncher/bow),
        "tier" = 5,
        "rarity_weight" = 3,
        "stat_mods" = list("skill_bows_bonus" = 3)
    ))
    L[A.id] = A

    // Athletics (boots, amulets)
    A = new /datum/affix(list(
        "id" = "fleet",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Fleet",
        "desc" = "+1 Athletics.",
        "allowed_types" = list(/obj/item/clothing/shoes/roguetown/boots, /obj/item/clothing/neck/roguetown),
        "tier" = 3,
        "rarity_weight" = 10,
        "stat_mods" = list("skill_athletics_bonus" = 1)
    ))
    L[A.id] = A
    A = new /datum/affix(list(
        "id" = "swift",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Swift",
        "desc" = "+2 Athletics.",
        "allowed_types" = list(/obj/item/clothing/shoes/roguetown/boots, /obj/item/clothing/neck/roguetown),
        "tier" = 4,
        "rarity_weight" = 6,
        "stat_mods" = list("skill_athletics_bonus" = 2)
    ))
    L[A.id] = A
    A = new /datum/affix(list(
        "id" = "lightfoot",
        "kind" = AFFIX_KIND_PREFIX,
        "display_name" = "Lightfoot",
        "desc" = "+3 Athletics.",
        "allowed_types" = list(/obj/item/clothing/shoes/roguetown/boots, /obj/item/clothing/neck/roguetown),
        "tier" = 5,
        "rarity_weight" = 3,
        "stat_mods" = list("skill_athletics_bonus" = 3)
    ))
    L[A.id] = A

    // of the Bear (suffix) — torso armor only (roguetown armor suits)
    A = new /datum/affix(list(
        "id" = "of_bear",
        "kind" = AFFIX_KIND_SUFFIX,
        "display_name" = "of the Bear",
        "desc" = "Stout and sturdy, it bolsters protection.",
        "allowed_types" = list(/obj/item/clothing/suit/roguetown/armor),
        "tier" = 2,
        "rarity_weight" = 12,
        "stat_mods" = list(
            "armor_pct" = 0.1,
            "knockback_resist" = 0.2,
        ),
        "tags" = list("defensive" = TRUE)
    ))
    L[A.id] = A

    // Miner's Luck line (suffix) — pickaxes only; tiered gem chance
    // Tier 1: Miner's Luck — 1%..5%
    A = new /datum/affix(list(
        "id" = "of_miners_luck",
        "kind" = AFFIX_KIND_SUFFIX,
        "display_name" = "of Miner's Luck",
        "desc" = "A faint blessing; sometimes reveals gems.",
        "allowed_types" = list(/obj/item/rogueweapon/pick),
        "tier" = 1,
        "rarity_weight" = 20,
        "stat_mods" = list(
            "gem_bonus_chance" = list(0.01, 0.05)
        ),
        "tags" = list("utility" = TRUE, "mining" = TRUE)
    ))
    L[A.id] = A

    // Tier 2: Miner's Fortune — 5%..15%
    A = new /datum/affix(list(
        "id" = "of_miners_fortune",
        "kind" = AFFIX_KIND_SUFFIX,
        "display_name" = "of Miner's Fortune",
        "desc" = "Blessed by fortune; more likely to find gems.",
        "allowed_types" = list(/obj/item/rogueweapon/pick),
        "tier" = 2,
        "rarity_weight" = 10,
        "stat_mods" = list(
            "gem_bonus_chance" = list(0.05, 0.15)
        ),
        "tags" = list("utility" = TRUE, "mining" = TRUE)
    ))
    L[A.id] = A

    // Tier 3: Miner's Greed — 15%..35%
    A = new /datum/affix(list(
        "id" = "of_miners_greed",
        "kind" = AFFIX_KIND_SUFFIX,
        "display_name" = "of Miner's Greed",
        "desc" = "Greedy hands find hidden veins.",
        "allowed_types" = list(/obj/item/rogueweapon/pick),
        "tier" = 3,
        "rarity_weight" = 8,
        "stat_mods" = list(
            "gem_bonus_chance" = list(0.15, 0.35)
        ),
        "tags" = list("utility" = TRUE, "mining" = TRUE)
    ))
    L[A.id] = A

    // Tier 4: Miner's Avarice — 35%..50%
    A = new /datum/affix(list(
        "id" = "of_miners_avarice",
        "kind" = AFFIX_KIND_SUFFIX,
        "display_name" = "of Miner's Avarice",
        "desc" = "Avarice sharpens your eye for gemstones.",
        "allowed_types" = list(/obj/item/rogueweapon/pick),
        "tier" = 4,
        "rarity_weight" = 5,
        "stat_mods" = list(
            "gem_bonus_chance" = list(0.35, 0.50)
        ),
        "tags" = list("utility" = TRUE, "mining" = TRUE)
    ))
    L[A.id] = A

    // Tier 5: Miner's Wealth — 50%..65%
    A = new /datum/affix(list(
        "id" = "of_miners_wealth",
        "kind" = AFFIX_KIND_SUFFIX,
        "display_name" = "of Miner's Wealth",
        "desc" = "Riches seem to follow your strikes.",
        "allowed_types" = list(/obj/item/rogueweapon/pick),
        "tier" = 5,
        "rarity_weight" = 2,
        "stat_mods" = list(
            "gem_bonus_chance" = list(0.50, 0.65)
        ),
        "tags" = list("utility" = TRUE, "mining" = TRUE)
    ))
    L[A.id] = A

    // Tier 6: Miner's Ascendance — 65%..99% (unobtainium/admin-only)
    A = new /datum/affix(list(
        "id" = "of_miners_ascendance",
        "kind" = AFFIX_KIND_SUFFIX,
        "display_name" = "of Miner's Ascendance",
        "desc" = "A legendary blessing; gems all but leap free.",
        "allowed_types" = list(/obj/item/rogueweapon/pick),
        "tier" = 6,
        "rarity_weight" = 1,
        "stat_mods" = list(
            "gem_bonus_chance" = list(0.65, 0.99)
        ),
        "tags" = list("utility" = TRUE, "mining" = TRUE, "unobtainium" = TRUE, "admin_only" = TRUE)
    ))
    L[A.id] = A

    // Validation pass
    var/list/ids = list()
    for(var/_id in L)
        if(_id in ids)
            CRASH("Duplicate affix id in registry: [_id]")
        ids += _id
        var/datum/affix/AA = L[_id]
        var/err = AA.validate()
        if(err)
            CRASH("Invalid affix entry '[_id]': [err]")
    return L

/// Get an affix by id (or null)
proc/get_affix_by_id(id)
    if(!id || !GLOB.affix_registry)
        return null
    return GLOB.affix_registry[id]

/// Return a list of affixes eligible for the given item and kind (prefix/suffix)
proc/find_affixes_for_item(obj/item/I, kind, min_tier = 1, max_tier = 1.0e9)
    var/list/out = list()
    if(!I || !GLOB.affix_registry)
        return out
    for(var/_id in GLOB.affix_registry)
        var/datum/affix/A = GLOB.affix_registry[_id]
        if(A.kind != kind)
            continue
        if(A.tier < min_tier || A.tier > max_tier)
            continue
        if(!A.can_apply(I))
            continue
        out[_id] = A
    return out
