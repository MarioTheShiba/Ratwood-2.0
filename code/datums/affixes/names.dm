// Large pools of rare item names for weapons and armors

// Weapon name parts
GLOBAL_LIST_INIT(affix_weapon_adjectives, list(
    "Ancient","Anointed","Ashen","Baleful","Baneful","Barbaric","Bitter","Blacksteel","Bloodforged","Bloodletter",
    "Blazing","Bonecarved","Brutal","Celestial","Cinderforged","Cobalt","Coldsung","Crazed","Crimson","Crushing",
    "Cursed","Dawnforged","Deadly","Deathbound","Deathsong","Defiant","Demonbane","Dire","Divine","Doomforged",
    "Dragonforged","Dread","Duskwrought","Ebon","Eclipse","Eldritch","Emerald","Empyreal","Enchanted","Endless",
    "Feral","Fiery","Gilded","Gloomforged","Golden","Grim","Hallowed","Haunted","Hellforged","Heroic",
    "Howling","Huntsman’s","Iceborn","Infernal","Ironbound","Ivory","Jagged","Kingslayer’s","Knight’s","Lifebound",
    "Lightning","Lionheart","Malefic","Merciless","Moonlit","Mythic","Nightfall","Obsidian","Omenforged","Onyx",
    "Pale","Phoenix","Plagueborne","Queenslayer’s","Raging","Runed","Sanguine","Savage","Shadowed","Shatterborn",
    "Silent","Silvered","Skyforged","Solar","Soulbound","Spellforged","Spiteful","Starforged","Steelbound","Stormforged",
    "Stormkissed","Sunforged","Thunderous","Titanic","Twilight","Unending","Vengeful","Verdant","Vicious","Viridian",
    "Voidforged","Warsong","Wicked","Wild","Winterborn","Wyrmforged"
))

GLOBAL_LIST_INIT(affix_weapon_nouns, list(
    "Aegis","Annihilator","Arc","Bane","Barb","Bite","Blade","Brand","Breaker","Calamity",
    "Carver","Cleave","Claw","Crescent","Crush","Cutlass","Damnation","Dawn","Defiance","Deluge",
    "Demise","Devotion","Dirk","Doom","Edge","Ember","Fang","Fate","Feast","Fervor",
    "Fury","Gale","Gash","Glaive","Glory","Grief","Guillotine","Halo","Harbinger","Harmony",
    "Heart","Horizon","Howl","Hunger","Judgment","Kiss","Lament","Legacy","Maelstrom","Maul",
    "Might","Night","Oath","Onslaught","Paradox","Piercer","Pledge","Promise","Rage","Raptor",
    "Reckoning","Relic","Requiem","Revenant","Rift","Roar","Saber","Scorn","Scream","Scythe",
    "Shade","Shard","Silence","Sorrow","Soul","Spear","Spite","Spirit","Storm","Strike",
    "Sunder","Surge","Tempest","Terror","Thirst","Thunder","Torment","Tsunami","Valor","Vengeance",
    "Vigil","Viper","Vortex","Whisper","Widow","Wrath"
))

GLOBAL_LIST_INIT(affix_weapon_epithets, list(
    "King’s","Queen’s","Warlord’s","Knight’s","Dragon’s","Serpent’s","Wolf’s","Bear’s","Eagle’s","Crow’s",
    "Saint’s","Sinner’s","Warrior’s","Hunter’s","Assassin’s","Watcher’s","Seeker’s","Warden’s","Reaper’s","Dreadlord’s",
    "Storm’s","Sun’s","Moon’s","Night’s","Dawn’s","Dusk’s","Fate’s","Destiny’s","Grave’s","Hell’s"
))

// Armor name parts
GLOBAL_LIST_INIT(affix_armor_adjectives, list(
    "Adamant","Aegisbound","Ancestral","Angelic","Bastion","Blessed","Brazen","Bulwark’s","Burnished","Ceremonial",
    "Coalescent","Defiant","Deflecting","Diamond","Dreadnought","Earthen","Eminent","Farsight","Fortified","Gilded",
    "Glacial","Glorious","Guardian’s","Hallowed","Immovable","Imperial","Imposing","Ironclad","Ironsong","Ivory",
    "Juggernaut’s","Knightly","Lion’s","Magnificent","Martyr’s","Oaken","Oathbound","Obsidian","Ornate","Petrified",
    "Radiant","Reinforced","Runed","Sacred","Sanctified","Shining","Silvered","Solar","Solid","Stalwart",
    "Starbound","Steadfast","Stoneguard","Stormward","Sunlit","Titanforged","Umbral","Unbroken","Vigilant","Wardwoven"
))

GLOBAL_LIST_INIT(affix_armor_nouns, list(
    "Aegis","Armor","Bastion","Blessing","Bulwark","Carapace","Coat","Cuirass","Defender","Embrace",
    "Fortress","Guard","Harness","Hauberk","Heart","Mantle","Oath","Palisade","Panoply","Pledge",
    "Plate","Rampart","Raiment","Rampart","Regalia","Safeguard","Sanctuary","Shell","Shield","Shroud",
    "Sigil","Stand","Stature","Surcoat","Vanguard","Vestment","Vigil","Visage","Ward","Warding"
))

// Virtues/abstracts shared
GLOBAL_LIST_INIT(affix_virtues, list(
    "Valor","Honor","Resolve","Mercy","Zeal","Grace","Glory","Truth","Silence","Hope",
    "Fortitude","Justice","Faith","Dawn","Dusk","Storms","Ashes","Winter","Thorns","Embers",
    "Shadows","Light","Frost","Flames","Stone","Iron","Oak","Storm","Sun","Moon"
))

/// Compose a rare weapon name without using the base name
/proc/affix_generate_weapon_rare_name()
    var/style = rand(1, 4)
    if(style == 1)
        return "[pick(GLOB.affix_weapon_adjectives)] [pick(GLOB.affix_weapon_nouns)]"
    if(style == 2)
        return "[pick(GLOB.affix_weapon_nouns)] of [pick(GLOB.affix_virtues)]"
    if(style == 3)
        return "[pick(GLOB.affix_weapon_epithets)] [pick(GLOB.affix_weapon_nouns)]"
    // The [Noun]
    return "The [pick(GLOB.affix_weapon_nouns)]"

/// Compose a rare armor name without using the base name
/proc/affix_generate_armor_rare_name()
    var/style = rand(1, 4)
    if(style == 1)
        return "[pick(GLOB.affix_armor_adjectives)] [pick(GLOB.affix_armor_nouns)]"
    if(style == 2)
        return "[pick(GLOB.affix_armor_nouns)] of [pick(GLOB.affix_virtues)]"
    if(style == 3)
        return "[pick(GLOB.affix_weapon_epithets)] [pick(GLOB.affix_armor_nouns)]"
    return "The [pick(GLOB.affix_armor_nouns)]"

/// Generic fallback if classification fails
/proc/affix_generate_generic_rare_name()
    var/style = rand(1, 3)
    if(style == 1)
        return "[pick(GLOB.affix_weapon_adjectives)] [pick(GLOB.affix_weapon_nouns)]"
    if(style == 2)
        return "[pick(GLOB.affix_armor_adjectives)] [pick(GLOB.affix_armor_nouns)]"
    return "[pick(GLOB.affix_weapon_nouns)] of [pick(GLOB.affix_virtues)]"
