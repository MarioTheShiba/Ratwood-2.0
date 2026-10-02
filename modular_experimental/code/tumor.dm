#define TUMOR_EYE_RANGE_X 7
#define TUMOR_EYE_RANGE_Y 5

#define TUMOR_EYE_FULL_TRAVEL_DISTANCE 140
// ^ how far the cursor needs to be from screen center before the eye 
// reaches the edge of its allowed movement.
// large = more subtle/slower tracking

/mob/living/simple_animal/tumor
	name = "The Watcher"
	desc = "A vast mass of living flesh, arcyne machinery, and civic apparatus. It watches in thoughtful - and most likely painful - silence."
	gender = NEUTER
	density = TRUE
	anchored = TRUE
	// he fat
	move_resist = MOVE_FORCE_OVERPOWERING
	status_flags = 0
	mob_size = MOB_SIZE_LARGE
	health = 1000
	maxHealth = 1000
	pixel_x = -32
	pixel_y = 0

	icon = 'modular_experimental/sprites/thetumor.dmi'
	icon_state = "thetumor"
	icon_living = "thetumor"
	icon_dead = "thetumor" // the eye goes away when ded.

	// supposed to be player countrolled
	wander = FALSE
	stop_automated_movement = TRUE
	can_have_ai = FALSE
	AIStatus = AI_OFF

	// he a blob of flesh he can't exactly fight.
	melee_damage_lower = 0
	melee_damage_upper = 0
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	base_intents = list(/datum/intent/use)

	// maybe give him random gurgles and stuff eventually?
	speak_chance = 0
	speak_emote = list("states")
	emote_hear = null
	emote_see = null

	// it's a living machine pretty much, not an animal. (at least not externally)
	food_type = null
	pooptype = null

	// decent natural vision for its chamber
	see_in_dark = 8
	faction = list("overseer")

	var/obj/effect/overseer_eye/eye_visual
	var/eye_target_x = 0
	var/eye_target_y = 0


/mob/living/simple_animal/tumor/Initialize(mapload)
	. = ..()

	// for now we give it some helping traits
	ADD_TRAIT(src, TRAIT_NOBREATH, TRAIT_GENERIC)
	ADD_TRAIT(src, TRAIT_NOHUNGER, TRAIT_GENERIC)
	ADD_TRAIT(src, TRAIT_NOMOOD, TRAIT_GENERIC)

	// make absolutely doubly sure nothing tries to wake its AI up.
	AIStatus = AI_OFF
	can_have_ai = FALSE
	eye_visual = new
	vis_contents += eye_visual


/mob/living/simple_animal/tumor/Move(atom/newloc, direct = 0, glide_size_override = 0)
	// the tumor's 'body' is permanently incorporated into its apparatus.
	return FALSE


// the eye!!

/mob/living/simple_animal/tumor/Destroy()
	if(eye_visual)
		vis_contents -= eye_visual
		QDEL_NULL(eye_visual)

	return ..()

/mob/living/simple_animal/tumor/do_time_change()
	return // avoid runtime.


/mob/living/simple_animal/tumor/face_atom(atom/A)
	return FALSE // so it dont go away (the eye that is)

// i coded this while listening to this: https://www.youtube.com/watch?v=rzLd1mCCOHw
/obj/effect/overseer_eye
	name = ""
	icon = 'modular_experimental/sprites/thetumor.dmi'
	icon_state = "eye"

	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

	// keep it on the same plane as the parent, but drawing above the body.
	vis_flags = VIS_INHERIT_PLANE
	layer = ABOVE_MOB_LAYER
	dir = SOUTH


/client/MouseMove(object, location, control, params) // fairly invasive implementation but it's meant for an immersive experience.
	. = ..()

	if (!istype(mob, /mob/living/simple_animal/tumor))
		return
	
	var/mob/living/simple_animal/tumor/t = mob
	t.update_eye_from_mouse(src, params)



/mob/living/simple_animal/tumor/proc/update_eye_from_mouse(client/C, params)
	if(!C || !eye_visual || stat == DEAD)
		return

	var/list/modifiers = params2list(params)
	var/screen_loc = modifiers["screen-loc"]

	if(!screen_loc)
		return

	var/list/screen_loc_parts = splittext(screen_loc, ",")
	if(length(screen_loc_parts) < 2)
		return

	var/list/screen_x_parts = splittext(screen_loc_parts[1], ":")
	var/list/screen_y_parts = splittext(screen_loc_parts[2], ":")

	if(length(screen_x_parts) < 2 || length(screen_y_parts) < 2)
		return

	var/screen_tile_x = text2num(screen_x_parts[1])
	var/screen_tile_y = text2num(screen_y_parts[1])

	var/screen_pixel_x = text2num(screen_x_parts[2])
	var/screen_pixel_y = text2num(screen_y_parts[2])

	var/mouse_x = ((screen_tile_x - 1) * world.icon_size) + screen_pixel_x
	var/mouse_y = ((screen_tile_y - 1) * world.icon_size) + screen_pixel_y

	var/list/screen_view = getviewsize(C.view)

	var/view_width_pixels = screen_view[1] * world.icon_size
	var/view_height_pixels = screen_view[2] * world.icon_size

	var/origin_x = round(view_width_pixels / 2) - C.pixel_x
	var/origin_y = round(view_height_pixels / 2) - C.pixel_y

	var/delta_x = mouse_x - origin_x
	var/delta_y = mouse_y - origin_y

	var/distance = sqrt((delta_x * delta_x) + (delta_y * delta_y))

	if(distance <= 0)
		set_eye_position(0, 0)
		return

	var/strength = min(1, distance / TUMOR_EYE_FULL_TRAVEL_DISTANCE)

	var/normal_x = delta_x / distance
	var/normal_y = delta_y / distance

	var/new_x = round(normal_x * TUMOR_EYE_RANGE_X * strength)
	var/new_y = round(normal_y * TUMOR_EYE_RANGE_Y * strength)

	set_eye_position(new_x, new_y)


/mob/living/simple_animal/tumor/proc/set_eye_position(new_x, new_y)
	if(!eye_visual)
		return

	new_x = clamp(new_x, -TUMOR_EYE_RANGE_X, TUMOR_EYE_RANGE_X)
	new_y = clamp(new_y, -TUMOR_EYE_RANGE_Y, TUMOR_EYE_RANGE_Y)

	if(new_x == eye_target_x && new_y == eye_target_y)
		return

	eye_target_x = new_x
	eye_target_y = new_y

	animate(eye_visual, flags = ANIMATION_END_NOW)
	animate(
		eye_visual,
		pixel_x = eye_target_x,
		pixel_y = eye_target_y,
		time = 0.5,
		easing = SINE_EASING
	)
