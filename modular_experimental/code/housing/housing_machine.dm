/obj/structure/roguemachine/experimental_housing
	parent_type = /obj/structure/roguemachine/experimental_terminal
	name = "HOUSING REGISTRY"
	desc = "An Experimental municipal property terminal. Whoever invented this clearly is very wealthy - or very lucky."
	icon = 'icons/roguetown/misc/machines.dmi'
	icon_state = "streetvendor1"
	density = TRUE
	layer = BELOW_OBJ_LAYER
	blade_dulling = DULLING_BASH
	terminal_title = "PROPERTY REGISTRY TERMINAL"
	terminal_identity = "HOUSING / MUNICIPAL RECORDS"
	terminal_prompt = "C:\\HOUSING>"


/obj/structure/roguemachine/experimental_housing/attack_hand(mob/living/user)
	. = ..()

	if(.)
		return

	user.changeNext_move(CLICK_CD_INTENTCAP)
	var/datum/browser/experimental_terminal/popup = get_terminal(user)
	if(popup)
		popup.open()


/obj/structure/roguemachine/experimental_housing/execute_terminal_command(datum/browser/experimental_terminal/popup, command, list/arguments)
	if(..())
		return TRUE
	switch(command)
		if("HELP", "LIST")
			if(length(arguments))
				popup.invalid_syntax(command)
				return TRUE
		if("VIEW", "KEY")
			if(length(arguments) != 1)
				popup.invalid_syntax("[command] <property_id>")
				return TRUE
		else
			return FALSE

	switch(command)
		if("HELP")
			popup.add_history("AVAILABLE COMMANDS:\n\nHELP\nLIST\nVIEW <property_id>\nKEY <property_id>\nLOGIN\nLOGOUT\nCLS\nSHUTDOWN")
		if("LIST")
			var/list/properties = SShousing.get_property_management_data(popup.user)
			if(!length(properties))
				popup.add_history("NO REGISTERED PROPERTIES.")
				return TRUE
			var/list/output = list()
			var/index = 0
			for(var/list/property as anything in properties)
				index++
				var/number = add_zero("[index]", 2)
				var/status = property["is_vacant"] ? "VACANT" : uppertext(property["tenure_type"])
				var/holder = property["is_vacant"] || !property["holder_name"] ? "NONE" : property["holder_name"]
				output += "\[[number]\] [property["property_id"]]\n     TYPE ........ [uppertext(property["property_type"])]\n     STATUS ...... [status]\n     HOLDER ...... [holder]\n     RENT ........ [property["rent_amount"]]\n     DELINQUENCY . [property["delinquent_rounds"]]\n"
			popup.add_history(output.Join("\n"))
		if("VIEW")
			var/datum/experimental_property_record/record = SShousing.get_property_record(arguments[1])
			if(!record)
				popup.add_history("PROPERTY NOT FOUND.")
			else
				var/holder = record.tenure_type == EXP_PROPERTY_TENURE_VACANT || !record.holder_name ? "NONE" : record.holder_name
				popup.add_history("PROPERTY RECORD\n\nID .............. [record.property_id]\nTYPE ............ [record.property_type]\nSTATUS .......... [record.tenure_type]\nHOLDER .......... [holder]\nRENT ............ [record.rent_amount]\nDELINQUENCY ..... [record.delinquent_rounds] / [record.max_delinquent_rounds]")
		if("KEY")
			if(SShousing.issue_property_key(arguments[1], popup.user))
				popup.add_history("KEY ISSUED.")
			else
				popup.add_history("KEY REQUEST DENIED.")
	return TRUE
