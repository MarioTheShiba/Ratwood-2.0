#define EXPERIMENTAL_SOURCE_ICON 'modular_experimental/sprites/source.dmi'

/turf/open/floor/rogue/experimental_greybox
	name = "greybox floor"
	desc = "A temporary development surface."
	icon = EXPERIMENTAL_SOURCE_ICON
	icon_state = "devturf1"
	smooth = SMOOTH_FALSE
	canSmoothWith = null
	tiled_dirt = FALSE
	footstep = FOOTSTEP_STONE
	barefootstep = FOOTSTEP_HARD_BAREFOOT
	clawfootstep = FOOTSTEP_HARD_CLAW
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY

/turf/open/floor/rogue/experimental_greybox/devturf1
	name = "greybox floor 1"
	icon_state = "devturf1"

/turf/open/floor/rogue/experimental_greybox/devturf2
	name = "greybox floor 2"
	icon_state = "devturf2"

/turf/open/floor/rogue/experimental_greybox/devturf3
	name = "greybox floor 3"
	icon_state = "devturf3"

/turf/open/floor/rogue/experimental_greybox/devturf4
	name = "greybox floor 4"
	icon_state = "devturf4"

/turf/open/floor/rogue/experimental_greybox/devstair1
	name = "greybox stair 1"
	icon_state = "devstair1"

/turf/open/floor/rogue/experimental_greybox/devstair2
	name = "greybox stair 2"
	icon_state = "devstair2"

/turf/closed/wall/experimental_greybox
	name = "greybox wall"
	desc = "A temporary development wall."
	icon = EXPERIMENTAL_SOURCE_ICON
	icon_state = "devwall1"
	smooth = SMOOTH_FALSE
	canSmoothWith = null
	baseturfs = /turf/open/floor/rogue/experimental_greybox/devturf1

/turf/closed/wall/experimental_greybox/devwall1
	name = "greybox wall 1"
	icon_state = "devwall1"

/turf/closed/wall/experimental_greybox/devwall2
	name = "greybox wall 2"
	icon_state = "devwall2"

/turf/closed/wall/experimental_greybox/devwall3
	name = "greybox wall 3"
	icon_state = "devwall3"

/obj/effect/experimental_source_marker
	name = "source marker"
	icon = EXPERIMENTAL_SOURCE_ICON
	icon_state = "trigger"
	anchored = TRUE
	density = FALSE
	mouse_opacity = MOUSE_OPACITY_ICON

/obj/effect/experimental_source_marker/nodraw
	name = "nodraw"
	icon_state = "nodraw"

/obj/effect/experimental_source_marker/skybox
	name = "skybox"
	icon_state = "skybox"

/obj/effect/experimental_source_marker/trigger
	name = "trigger"
	icon_state = "trigger"

/obj/effect/experimental_source_marker/clip
	name = "clip"
	icon_state = "clip"

/obj/effect/experimental_source_marker/playerclip
	name = "playerclip"
	icon_state = "playerclip"

/obj/effect/experimental_source_marker/landmark
	name = "landmark"
	icon_state = "landmark"

/obj/effect/experimental_source_marker/cubemap
	name = "cubemap"
	icon_state = "cubemap"

/obj/effect/experimental_source_marker/error
	name = "error"
	icon_state = "error"

/obj/effect/experimental_source_marker/block_bullets
	name = "block_bullets"
	icon_state = "block_bullets"

/obj/effect/experimental_source_marker/nd1
	name = "nd1"
	icon_state = "nd1"

/obj/effect/experimental_source_marker/nd2
	name = "nd2"
	icon_state = "nd2"

/obj/effect/experimental_source_marker/nd3
	name = "nd3"
	icon_state = "nd3"

/obj/effect/experimental_source_marker/nd4
	name = "nd4"
	icon_state = "nd4"

/obj/effect/experimental_source_marker/ghostclip
	name = "ghostclip"
	icon_state = "ghostclip"

/obj/effect/experimental_source_marker/tools_black
	name = "tools/black"
	icon_state = "tools/black"

/obj/effect/experimental_source_marker/gradient
	name = "gradient"
	icon_state = "gradient"

/obj/effect/experimental_source_marker/env_leak
	name = "env_leak"
	icon_state = "env_leak"

/obj/effect/experimental_source_marker/env_canal
	name = "env_canal"
	icon_state = "env_canal"

/obj/effect/experimental_source_marker/missingasset
	name = "missingasset"
	icon_state = "missingasset"

/obj/effect/experimental_source_marker/missing1
	name = "missing1"
	icon_state = "missing1"

/obj/effect/experimental_source_marker/missing2
	name = "missing2"
	icon_state = "missing2"

/obj/effect/experimental_source_marker/missing3
	name = "missing3"
	icon_state = "missing3"

/obj/effect/experimental_source_marker/blue
	name = "blue"
	icon_state = "blue"

/obj/effect/experimental_source_marker/red
	name = "red"
	icon_state = "red"

/obj/effect/experimental_source_marker/noteam
	name = "noteam"
	icon_state = "noteam"

/obj/effect/experimental_source_marker/choreo
	name = "choreo"
	icon_state = "choreo"

/obj/effect/experimental_source_marker/env_light
	name = "env_light"
	icon_state = "env_light"

/obj/effect/experimental_source_marker/obselete
	name = "obselete"
	icon_state = "obselete"

/obj/effect/experimental_source_marker/obselete_good
	name = "obselete_good"
	icon_state = "obselete_good"

/obj/effect/experimental_source_marker/explosion
	name = "explosion"
	icon_state = "explosion"

/obj/effect/experimental_source_marker/env_sun
	name = "env_sun"
	icon_state = "env_sun"

/obj/effect/experimental_source_marker/colorcorrect
	name = "colorcorrect"
	icon_state = "colorcorrect"

/obj/effect/experimental_source_marker/light
	name = "light"
	icon_state = "light"

/obj/effect/experimental_source_marker/sound
	name = "sound"
	icon_state = "sound"

/obj/effect/experimental_source_marker/env_machinehum
	name = "env_machinehum"
	icon_state = "env_machinehum"

/obj/effect/experimental_source_marker/env_radiostatic
	name = "env_radiostatic"
	icon_state = "env_radiostatic"

/obj/effect/experimental_source_marker/runtime
	name = "runtime"
	icon_state = "runtime"

/obj/effect/experimental_source_marker/dev_text
	name = "dev_text"
	icon_state = "dev_text"

/obj/effect/experimental_source_marker/landmark2
	name = "landmark2"
	icon_state = "landmark2"

/obj/effect/experimental_source_marker/fire
	name = "fire"
	icon_state = "fire"

/obj/effect/experimental_source_marker/logic_relay
	name = "logic_relay"
	icon_state = "logic_relay"

/obj/effect/experimental_source_marker/round_events
	name = "round_events"
	icon_state = "round_events"

/obj/effect/experimental_source_marker/world_events
	name = "world_events"
	icon_state = "world_events"

/obj/effect/experimental_source_marker/logic_timer
	name = "logic_timer"
	icon_state = "logic_timer"

/obj/effect/experimental_source_marker/logic_compare
	name = "logic_compare"
	icon_state = "logic_compare"

/obj/effect/experimental_source_marker/logic_branch
	name = "logic_branch"
	icon_state = "logic_branch"

/obj/effect/experimental_source_marker/math_counter
	name = "math_counter"
	icon_state = "math_counter"

/obj/effect/experimental_source_marker/logic_case
	name = "logic_case"
	icon_state = "logic_case"

/obj/effect/experimental_source_marker/axis
	name = "axis"
	icon_state = "axis"

/obj/effect/experimental_source_marker/x
	name = "x"
	icon_state = "x"

/obj/effect/experimental_source_marker/fog
	name = "fog"
	icon_state = "fog"

/obj/effect/experimental_source_marker/sequence
	name = "sequence"
	icon_state = "sequence"

/obj/effect/experimental_source_marker/target_info
	name = "target_info"
	icon_state = "target_info"

/obj/effect/experimental_source_marker/fade
	name = "fade"
	icon_state = "fade"

/obj/effect/experimental_source_marker/env_soundscape
	name = "env_soundscape"
	icon_state = "env_soundscape"

/obj/effect/experimental_source_marker/particles
	name = "particles"
	icon_state = "particles"

/obj/effect/experimental_source_marker/loudspeaker
	name = "loudspeaker"
	icon_state = "loudspeaker"

/obj/effect/experimental_source_marker/oneway
	name = "oneway"
	icon_state = "oneway"

/obj/effect/experimental_source_marker/camera
	name = "camera"
	icon_state = "camera"

/obj/effect/experimental_source_marker/oneway_thin
	name = "oneway_thin"
	icon_state = "oneway_thin"

/obj/effect/experimental_source_marker/objective_ctf
	name = "objective_ctf"
	icon_state = "objective_ctf"

/obj/effect/experimental_source_marker/sfx
	name = "sfx"
	icon_state = "sfx"

/obj/effect/experimental_source_marker/fx
	name = "fx"
	icon_state = "fx"

/obj/effect/experimental_source_marker/game_event_litener
	name = "game_event_litener"
	icon_state = "game_event_litener"

/obj/effect/experimental_source_marker/objective_destruction
	name = "objective_destruction"
	icon_state = "objective_destruction"

/obj/effect/experimental_source_marker/objective_delivery
	name = "objective_delivery"
	icon_state = "objective_delivery"

/obj/effect/experimental_source_marker/objective_sequence
	name = "objective_sequence"
	icon_state = "objective_sequence"

/obj/effect/experimental_source_marker/objective
	name = "objective"
	icon_state = "objective"

/obj/effect/experimental_source_marker/briefcase_zone
	name = "briefcase_zone"
	icon_state = "briefcase_zone"

/obj/effect/experimental_source_marker/ctf_home
	name = "ctf_home"
	icon_state = "ctf_home"

/obj/effect/experimental_source_marker/lives
	name = "lives"
	icon_state = "lives"

/obj/effect/experimental_source_marker/hint
	name = "hint"
	icon_state = "hint"

/obj/effect/experimental_source_marker/hint_small
	name = "hint_small"
	icon_state = "hint_small"

/obj/effect/experimental_source_marker/pickup_small
	name = "pickup_small"
	icon_state = "pickup_small"

/obj/effect/experimental_source_marker/pickup
	name = "pickup"
	icon_state = "pickup"

/obj/effect/experimental_source_marker/press_small
	name = "press_small"
	icon_state = "press_small"

/obj/effect/experimental_source_marker/press
	name = "press"
	icon_state = "press"

/obj/effect/experimental_source_marker/door_small
	name = "door_small"
	icon_state = "door_small"

/obj/effect/experimental_source_marker/door
	name = "door"
	icon_state = "door"

/obj/effect/experimental_source_marker/danger_small
	name = "danger_small"
	icon_state = "danger_small"

/obj/effect/experimental_source_marker/danger
	name = "danger"
	icon_state = "danger"

/obj/effect/experimental_source_marker/info_small
	name = "info_small"
	icon_state = "info_small"

/obj/effect/experimental_source_marker/info
	name = "info"
	icon_state = "info"

/obj/effect/experimental_source_marker/hint_payload
	name = "hint_payload"
	icon_state = "hint_payload"

#undef EXPERIMENTAL_SOURCE_ICON
