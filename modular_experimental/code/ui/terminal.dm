#define EXPERIMENTAL_TERMINAL_OFF 0
#define EXPERIMENTAL_TERMINAL_BOOTING 1
#define EXPERIMENTAL_TERMINAL_ON 2
#define EXPERIMENTAL_TERMINAL_COMMAND 0
#define EXPERIMENTAL_TERMINAL_USER_ID 1
#define EXPERIMENTAL_TERMINAL_PASSWORD 2




// I WOULD RATHER DIE THAN USE TGUI.

// KILL TGUI! KILL TGUI! KILL TGUI!

/datum/looping_sound/experimental_terminal_idle
	mid_sounds = list('modular_experimental/sounds/terminal/idle.ogg')
	mid_length = 22.6 SECONDS
	volume = 35
	extra_range = -4
	persistent_loop = TRUE


/obj/structure/roguemachine/experimental_terminal
	var/terminal_title = "MUNICIPAL TERMINAL"
	var/terminal_identity = "MUNICIPAL TERMINAL"
	var/terminal_prompt = "C:\\>"
	var/terminal_width = 1000
	var/terminal_height = 600
	var/terminal_boot_sound = 'modular_experimental/sounds/terminal/boot.ogg'
	var/terminal_boot_duration = 4.5 SECONDS
	var/terminal_shutdown_sound = 'modular_experimental/sounds/terminal/shutdown.ogg'
	var/terminal_shutdown_duration = 5.2 SECONDS
	var/terminal_state = EXPERIMENTAL_TERMINAL_OFF
	var/terminal_boot_started
	var/terminal_boot_generation = 0
	var/terminal_boot_timer
	var/terminal_boot_channel
	var/list/terminal_boot_listeners = list()
	var/list/terminal_sessions = list()
	var/datum/looping_sound/experimental_terminal_idle/terminal_idle
	var/terminal_shutdown_channel
	var/terminal_shutdown_timer
	var/list/terminal_shutdown_listeners = list()


/obj/structure/roguemachine/experimental_terminal/Destroy()
	terminal_state = EXPERIMENTAL_TERMINAL_OFF
	stop_terminal_boot()
	for(var/mob/viewer as anything in terminal_sessions.Copy())
		qdel(terminal_sessions[viewer])
	QDEL_NULL(terminal_idle)
	stop_terminal_shutdown()
	return ..()


/obj/structure/roguemachine/experimental_terminal/proc/get_terminal(mob/living/user)
	if(!ishuman(user) || !user.client || !user.canUseTopic(src, BE_CLOSE))
		return
	if(terminal_state == EXPERIMENTAL_TERMINAL_OFF)
		start_terminal_boot()

	var/datum/browser/experimental_terminal/popup = terminal_sessions[user]
	if(popup && popup.session_client != user.client)
		qdel(popup)
		popup = null
	if(!popup)
		popup = new(user, ckey("experimental_terminal_[REF(src)]"), terminal_title, terminal_width, terminal_height, src)
		popup.terminal_identity = terminal_identity
		popup.terminal_prompt = terminal_prompt
		terminal_sessions[user] = popup
	return popup


/obj/structure/roguemachine/experimental_terminal/proc/execute_terminal_command(datum/browser/experimental_terminal/popup, command, list/arguments)
	if(!(command in list("LOGIN", "LOGOUT", "CLS", "SHUTDOWN")))
		return FALSE
	if(length(arguments))
		popup.invalid_syntax(command)
		return TRUE
	switch(command)
		if("LOGIN")
			popup.input_mode = EXPERIMENTAL_TERMINAL_USER_ID
			popup.login_user_id = null
		if("LOGOUT")
			popup.reset_login()
			popup.add_history("NO ACTIVE LOGIN.")
		if("CLS")
			popup.command_history.Cut()
		if("SHUTDOWN")
			shutdown_terminal()
	return TRUE


/obj/structure/roguemachine/experimental_terminal/proc/start_terminal_boot()
	if(terminal_state != EXPERIMENTAL_TERMINAL_OFF)
		return
	stop_terminal_shutdown()
	terminal_state = EXPERIMENTAL_TERMINAL_BOOTING
	terminal_boot_generation++
	terminal_boot_started = world.time
	terminal_boot_channel = SSsounds.reserve_sound_channel(src)
	if(terminal_boot_channel)
		var/list/listeners = playsound(src, terminal_boot_sound, 45, FALSE, channel = terminal_boot_channel)
		for(var/mob/listener as anything in listeners)
			if(listener.client)
				terminal_boot_listeners |= listener.client
	terminal_boot_timer = addtimer(CALLBACK(src, PROC_REF(finish_terminal_boot), terminal_boot_generation), terminal_boot_duration, TIMER_STOPPABLE)


/obj/structure/roguemachine/experimental_terminal/proc/stop_terminal_boot()
	terminal_boot_generation++
	if(terminal_boot_timer)
		deltimer(terminal_boot_timer)
		terminal_boot_timer = null
	if(terminal_boot_channel)
		for(var/client/listener as anything in terminal_boot_listeners)
			if(listener)
				SEND_SOUND(listener, sound(null, channel = terminal_boot_channel))
		SSsounds.free_sound_channel(terminal_boot_channel)
		terminal_boot_channel = null
	terminal_boot_listeners.Cut()


/obj/structure/roguemachine/experimental_terminal/proc/finish_terminal_boot(generation)
	if(QDELETED(src) || terminal_state != EXPERIMENTAL_TERMINAL_BOOTING || generation != terminal_boot_generation)
		return
	terminal_state = EXPERIMENTAL_TERMINAL_ON
	stop_terminal_boot()
	start_terminal_idle()
	for(var/mob/viewer as anything in terminal_sessions.Copy())
		var/datum/browser/experimental_terminal/popup = terminal_sessions[viewer]
		if(!popup?.is_active() || !viewer.canUseTopic(src, BE_CLOSE))
			qdel(popup)
			continue
		popup.open()


/obj/structure/roguemachine/experimental_terminal/proc/start_terminal_idle()
	if(terminal_state != EXPERIMENTAL_TERMINAL_ON || terminal_idle)
		return
	terminal_idle = new(src)
	if(!terminal_idle.channel)
		QDEL_NULL(terminal_idle)
		return
	terminal_idle.start()


/obj/structure/roguemachine/experimental_terminal/proc/shutdown_terminal()
	if(terminal_state == EXPERIMENTAL_TERMINAL_OFF)
		return
	terminal_state = EXPERIMENTAL_TERMINAL_OFF
	stop_terminal_boot()
	for(var/mob/viewer as anything in terminal_sessions.Copy())
		qdel(terminal_sessions[viewer])
	QDEL_NULL(terminal_idle)
	stop_terminal_shutdown()
	terminal_shutdown_channel = SSsounds.reserve_sound_channel(src)
	if(!terminal_shutdown_channel)
		return
	var/list/listeners = playsound(src, terminal_shutdown_sound, 40, FALSE, channel = terminal_shutdown_channel)
	for(var/mob/listener as anything in listeners)
		if(listener.client)
			terminal_shutdown_listeners |= listener.client
	terminal_shutdown_timer = addtimer(CALLBACK(src, PROC_REF(stop_terminal_shutdown)), terminal_shutdown_duration, TIMER_STOPPABLE)


/obj/structure/roguemachine/experimental_terminal/proc/stop_terminal_shutdown()
	if(terminal_shutdown_timer)
		deltimer(terminal_shutdown_timer)
		terminal_shutdown_timer = null
	if(terminal_shutdown_channel)
		for(var/client/listener as anything in terminal_shutdown_listeners)
			if(listener)
				SEND_SOUND(listener, sound(null, channel = terminal_shutdown_channel))
		SSsounds.free_sound_channel(terminal_shutdown_channel)
		terminal_shutdown_channel = null
	terminal_shutdown_listeners.Cut()


/datum/browser/experimental_terminal
	no_close_movement = TRUE
	window_options = "can_close=1;can_minimize=0;can_maximize=0;can_resize=0;titlebar=0;border=0;"
	var/obj/structure/roguemachine/experimental_terminal/terminal
	var/client/session_client
	var/session_open = FALSE
	var/terminal_identity = "MUNICIPAL TERMINAL"
	var/terminal_status = "READY"
	var/terminal_prompt = "C:\\>"
	var/list/command_history = list("READY.")
	var/history_limit = 50
	var/input_mode = EXPERIMENTAL_TERMINAL_COMMAND
	var/input_generation = 0
	var/login_user_id
	var/list/boot_lines = list(
		"ROM CHECK ............... OK",
		"MEMORY TEST ............. 640K OK",
		"SERIAL BUS .............. OK",
		"NETWORK LINK ............ ESTABLISHED",
		"LOCAL INDEX ............. MOUNTED",
		"READY_"
	)


/datum/browser/experimental_terminal/New(nuser, nwindow_id, ntitle = 0, nwidth = 0, nheight = 0, atom/nref = null)
	..()
	terminal = nref
	session_client = user?.client
	if(user)
		RegisterSignal(user, list(COMSIG_MOVABLE_MOVED, COMSIG_MOB_LOGOUT), PROC_REF(end_session))


/datum/browser/experimental_terminal/Destroy()
	session_open = FALSE
	reset_login()
	command_history.Cut()
	if(user?.client == session_client && session_client)
		user << browse(null, "window=[window_id]")
	if(terminal?.terminal_sessions[user] == src)
		terminal.terminal_sessions -= user
	terminal = null
	session_client = null
	return ..()


/datum/browser/experimental_terminal/proc/is_active()
	return session_open && !QDELETED(terminal) && user?.client && user.client == session_client && terminal.terminal_sessions[user] == src


/datum/browser/experimental_terminal/open(use_onclose = TRUE)
	if(!user?.client || user.client != session_client || QDELETED(terminal))
		qdel(src)
		return

	session_open = TRUE
	return ..(use_onclose)


/datum/browser/experimental_terminal/setup_onclose()
	set waitfor = FALSE
	for(var/i in 1 to 10)
		if(!is_active())
			return
		if(winexists(user, window_id))
			if(is_active())
				winset(user, window_id, "on-close=\".windowclose [REF(src)]\"")
			return


/datum/browser/experimental_terminal/close()
	qdel(src)


/datum/browser/experimental_terminal/user_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)


/datum/browser/experimental_terminal/ref_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)


/datum/browser/experimental_terminal/proc/end_session(datum/source)
	SIGNAL_HANDLER
	qdel(src)


/datum/browser/experimental_terminal/Topic(href, href_list)
	. = ..()
	if(usr != user || !session_client || usr.client != session_client)
		return
	if(href_list["close"])
		qdel(src)
		return
	if(!is_active() || !usr.canUseTopic(terminal, BE_CLOSE))
		qdel(src)
		return
	switch(href_list["terminal_action"])
		if("input")
			if(terminal.terminal_state != EXPERIMENTAL_TERMINAL_ON || text2num(href_list["input_generation"]) != input_generation)
				return
			input_generation++
			handle_terminal_input(href_list["command"])
			if(!QDELETED(src))
				open()
		if("resize")
			var/new_width = text2num(href_list["width"])
			var/new_height = text2num(href_list["height"])
			if(isnum(new_width) && isnum(new_height))
				width = clamp(round(new_width), 320, 8192)
				height = clamp(round(new_height), 240, 8192)
		if("skip_post")
			terminal.finish_terminal_boot(terminal.terminal_boot_generation)


/datum/browser/experimental_terminal/proc/add_history(text)
	command_history += "[text]"
	if(length(command_history) > history_limit)
		command_history.Cut(1, 2)


/datum/browser/experimental_terminal/proc/invalid_syntax(usage)
	add_history("INVALID SYNTAX.\nUSAGE: [usage]")


/datum/browser/experimental_terminal/proc/reset_login()
	input_mode = EXPERIMENTAL_TERMINAL_COMMAND
	login_user_id = null


/datum/browser/experimental_terminal/proc/parse_command(text)
	if(!istext(text) || length(text) > 256 || findtext(text, "\n") || findtext(text, ascii2text(13)))
		return null
	text = trim(text)
	if(!length(text))
		return list()
	return splittext(text, regex(@"[ \t]+"))


/datum/browser/experimental_terminal/proc/handle_terminal_input(text)
	if(input_mode == EXPERIMENTAL_TERMINAL_PASSWORD)
		reset_login()
		add_history("AUTHENTICATION UNAVAILABLE.")
		return
	if(input_mode == EXPERIMENTAL_TERMINAL_USER_ID)
		if(!istext(text) || !length(trim(text)) || length(text) > 64 || findtext(text, "\n") || findtext(text, ascii2text(13)))
			add_history("INVALID USER ID.")
			return
		login_user_id = trim(text)
		add_history("USER ID: [login_user_id]")
		input_mode = EXPERIMENTAL_TERMINAL_PASSWORD
		return

	var/list/words = parse_command(text)
	if(isnull(words))
		add_history("INVALID COMMAND INPUT.")
		return
	if(!length(words))
		return
	add_history("[terminal_prompt] [trim(text)]")
	var/command = uppertext(words[1])
	var/list/arguments = words.Copy(2)
	if(!terminal.execute_terminal_command(src, command, arguments))
		add_history("UNKNOWN COMMAND.\nTYPE HELP FOR AVAILABLE COMMANDS.")


/datum/browser/experimental_terminal/proc/command_page()
	var/prompt = terminal_prompt
	var/input_type = "text"
	var/input_name = " name='command'"
	var/input_limit = 256
	if(input_mode == EXPERIMENTAL_TERMINAL_USER_ID)
		prompt = "USER ID:"
		input_limit = 64
	else if(input_mode == EXPERIMENTAL_TERMINAL_PASSWORD)
		prompt = "PASSWORD:"
		input_type = "password"
		// Unnamed fields are never submitted, including when JavaScript is disabled.
		input_name = ""
	return {"
<pre id="terminal-history" class="terminal-history">[html_encode(command_history.Join("\n"))]</pre>
<form id="terminal-form" class="terminal-form" action="byond://?" method="get" autocomplete="off">
	<input type="hidden" name="src" value="[REF(src)]">
	<input type="hidden" name="terminal_action" value="input">
	<input type="hidden" name="input_generation" value="[input_generation]">
	<label for="terminal-input">[html_encode(prompt)]</label>
	<input id="terminal-input" type="[input_type]"[input_name] maxlength="[input_limit]" autocomplete="off" spellcheck="false" aria-label="[html_encode(prompt)]">
</form>
"}


/datum/browser/experimental_terminal/proc/terminal_link(datum/target, label, list/parameters)
	var/list/query = parameters ? parameters.Copy() : list()
	query["src"] = REF(target)
	query["terminal_session"] = REF(src)

	return "<a class='terminal-button' href=\"?[html_encode(list2params(query))]\">[html_encode("[label]")]</a>"


/datum/browser/experimental_terminal/get_content()
	var/boot_html = ""
	var/boot_script = ""
	var/page_style = ""

	if(terminal.terminal_state == EXPERIMENTAL_TERMINAL_BOOTING)
		var/post_duration = max(1, terminal.terminal_boot_duration * 100)
		var/post_elapsed = max(0, (world.time - terminal.terminal_boot_started) * 100)
		page_style = " style='display:none'"
		boot_html = "<div class='terminal-panel' id='terminal-boot'><h2>POWER-ON SELF TEST</h2>"

		for(var/line in boot_lines)
			boot_html += "<p class='terminal-post-line'>[html_encode("[line]")]</p>"

		boot_html += "<div id='terminal-skip'>[terminal_link(src, "SKIP POST", list("terminal_action" = "skip_post"))]</div></div>"
		boot_html += "<noscript><style>#terminal-boot{display:none}#terminal-page{display:flex!important}</style></noscript>"

		boot_script = {"
<script type="text/javascript">
(function () {
	var boot = document.getElementById('terminal-boot');
	var page = document.getElementById('terminal-page');
	var lines = boot.getElementsByTagName('p');
	var step = 0;
	var timer = null;
	var duration = [post_duration];
	var elapsed = [post_elapsed];
	var started = new Date().getTime();

	function finish() {
		window.clearTimeout(timer);
		boot.style.display = 'none';
		page.style.display = 'flex';
		var input = document.getElementById('terminal-input');
		if (input) {
			input.focus();
		}
		return false;
	}

	function advance() {
		var progress = elapsed + new Date().getTime() - started;
		while (step < lines.length && progress >= step * duration / lines.length) {
			lines.item(step++).style.visibility = 'visible';
		}
		if (progress >= duration) {
			finish();
			return;
		}
		timer = window.setTimeout(advance, 80);
	}

	document.getElementById('terminal-skip').onclick = function () {
		finish();
		return true;
	};
	advance();
})();
</script>
"}

	return {"
<!DOCTYPE html>
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<title>[html_encode("[title]")]</title>
	<style>
		html, body {
			margin: 0;
			padding: 0;
			border: 0;
			width: 100%;
			min-height: 100%;
			background: #000;
			color: #edbd69;
			font: 14px/1.5 "Courier New", monospace;
		}
		html {
			height: 100%;
		}
		.terminal {
			box-sizing: border-box;
			display: flex;
			flex-direction: column;
			width: 100%;
			height: 100vh;
			margin: 0;
			padding: 0 16px 16px;
			background: #000;
			word-wrap: break-word;
		}
		.terminal-header {
			flex: 0 0 auto;
			border: 2px solid #a27c39;
			border-top: 0;
			background: #000;
			padding: 10px 12px;
			margin: 0 -16px 14px;
		}
		.terminal-titlebar {
			display: flex;
			flex-wrap: wrap;
			align-items: center;
			gap: 8px;
		}
		.terminal-titlebar {
			justify-content: space-between;
		}
		.terminal-header h1 {
			font-size: 20px;
			line-height: 1.3;
			margin: 6px 0;
		}
		.terminal-identity {
			color: #b99554;
		}
		.terminal-panel {
			border: 1px solid #a27c39;
			padding: 12px;
			margin: 12px 0;
		}
		.terminal-panel h2 {
			font-size: 14px;
			margin: 0 0 12px;
			padding-bottom: 6px;
			border-bottom: 1px solid #594725;
		}
		.terminal-button {
			display: inline-block;
			border: 1px solid #a27c39;
			background: #171b10;
			color: #edbd69;
			font-size: 12px;
			padding: 4px 6px;
			margin: 2px 0;
			text-decoration: none;
			white-space: nowrap;
		}
		.terminal-button:hover, .terminal-button:focus {
			background: #edbd69;
			color: #070906;
		}
		#terminal-page {
			display: flex;
			flex-direction: column;
			flex: 1 1 auto;
			min-height: 0;
		}
		.terminal-history {
			flex: 1 1 auto;
			min-height: 0;
			overflow-y: auto;
			white-space: pre-wrap;
			word-wrap: break-word;
			font: inherit;
			margin: 0;
		}
		.terminal-form {
			display: flex;
			flex: 0 0 auto;
			align-items: baseline;
			gap: 8px;
			margin: 12px 0 0;
		}
		.terminal-form label {
			flex: 0 0 auto;
		}
		#terminal-input {
			flex: 1 1 auto;
			min-width: 0;
			background: #000;
			color: #edbd69;
			caret-color: #edbd69;
			font: inherit;
			border: 0;
			border-bottom: 1px solid #594725;
			border-radius: 0;
			padding: 0;
			outline: none;
		}
		#terminal-input:focus {
			border-bottom-color: #edbd69;
		}
		.terminal-footer {
			flex: 0 0 auto;
			border-top: 1px solid #a27c39;
			padding-top: 10px;
			margin-top: 14px;
		}
		.terminal-post-line {
			visibility: hidden;
			white-space: pre-wrap;
			margin: 0 0 6px;
		}
		.terminal-cursor {
			display: inline-block;
			margin-left: 3px;
			animation: terminal-blink 1s steps(1, end) infinite;
		}
		.terminal-resize {
			position: fixed;
			right: 0;
			bottom: 0;
			width: 20px;
			height: 20px;
			line-height: 20px;
			text-align: right;
			background: #000;
			cursor: se-resize;
			user-select: none;
		}
		@keyframes terminal-blink {
			0%, 49% {
				opacity: 1;
			}
			50%, 100% {
				opacity: 0;
			}
		}
	</style>
</head>
<body>
	<div class="terminal">
		<div class="terminal-header">
			<div>EXPERIMENTAL MUNICIPAL SYSTEMS</div>
			<div class="terminal-titlebar">
				<h1>[html_encode("[title]")]</h1>
				<div class="terminal-controls">
					[terminal_link(src, "CLOSE VIEW", list("close" = "1"))]
				</div>
			</div>
			<div class="terminal-identity">[html_encode("[terminal_identity]")]</div>
		</div>
		[boot_html]
		<div id="terminal-page"[page_style]>[command_page()]</div>
		<div class="terminal-footer" role="status">[html_encode("[terminal_status]")]<span class="terminal-cursor">█</span></div>
	</div>
	<div id="terminal-resize" class="terminal-resize" title="Resize terminal" data-window-id="[html_encode(window_id)]" data-topic="[html_encode(list2params(list("src" = REF(src), "terminal_action" = "resize")))]">&#9698;</div>
	[boot_script]
	<script id="terminal-window-script" type="text/javascript">
(function () {
	var input = document.getElementById('terminal-input');
	var history = document.getElementById('terminal-history');
	history.scrollTop = history.scrollHeight;
	if (!document.getElementById('terminal-boot')) {
		input.focus();
	}
	document.getElementById('terminal-form').onsubmit = function () {
		if (input.type === 'password') {
			input.value = '';
		}
		return true;
	};
	var grip = document.getElementById('terminal-resize');
	var ratio = window.devicePixelRatio || 1;
	var resizing = false;
	var startX, startY, startWidth, startHeight, width, height;

	function nativeCall(url) {
		if (window.cef_to_byond) {
			window.cef_to_byond(url);
		} else {
			window.location.href = url;
		}
	}

	function move(event) {
		if (!resizing) {
			return;
		}
		event.preventDefault();
		width = Math.min(8192, Math.max(320, Math.round(startWidth + (event.screenX - startX) * ratio)));
		height = Math.min(8192, Math.max(240, Math.round(startHeight + (event.screenY - startY) * ratio)));
		nativeCall('byond://winset?id=' + encodeURIComponent(grip.getAttribute('data-window-id')) + '&size=' + width + 'x' + height);
	}

	function finish() {
		if (!resizing) {
			return;
		}
		resizing = false;
		document.removeEventListener('mousemove', move);
		document.removeEventListener('mouseup', finish);
		nativeCall('byond://?' + grip.getAttribute('data-topic') + '&width=' + width + '&height=' + height);
	}

	grip.onmousedown = function (event) {
		if (event.button !== 0) {
			return;
		}
		event.preventDefault();
		resizing = true;
		startX = event.screenX;
		startY = event.screenY;
		width = startWidth = Math.round(window.innerWidth * ratio);
		height = startHeight = Math.round(window.innerHeight * ratio);
		document.addEventListener('mousemove', move);
		document.addEventListener('mouseup', finish);
	};
	window.addEventListener('blur', finish);
})();
	</script>
</body>
</html>
"}

// one of the few times i actually know what i'm doing. i went to school for this and i'm really proud of it.


#undef EXPERIMENTAL_TERMINAL_OFF
#undef EXPERIMENTAL_TERMINAL_BOOTING
#undef EXPERIMENTAL_TERMINAL_ON
#undef EXPERIMENTAL_TERMINAL_COMMAND
#undef EXPERIMENTAL_TERMINAL_USER_ID
#undef EXPERIMENTAL_TERMINAL_PASSWORD
