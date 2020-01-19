#!/bin/bash
# LinuxGSM update_minecraft.sh function
# Author: Daniel Gibbs
# Website: https://linuxgsm.com
# Description: Handles updating of Minecraft servers.

local commandname="UPDATE"
local commandaction="Update"
local function_selfname=$(basename "$(readlink -f "${BASH_SOURCE[0]}")")

fn_update_minecraft_dl(){
	latestdetails=$(curl -s ${update_url}/lastSuccessfulBuild/api/json)
	buildartifact=$(echo -n ${latestdetails} | jq -r '.artifacts[0].fileName' | sed 's/.$//')
	buildurl="$(echo -n ${latestdetails} | jq -r '.url' | sed 's/.$//')"
	artifacturl="${buildurl::-1}/artifact/${buildartifact}"
	fn_fetch_file "${artifacturl}" "${tmpdir}" "${buildartifact}"
	echo -e "copying to ${serverfiles}...\c"
	cp "${tmpdir}/${buildartifact}" "${serverfiles}/paperclip.jar"
	local exitcode=$?
	if [ "${exitcode}" == "0" ]; then
		fn_print_ok_eol_nl
		fn_script_log_pass "Copying to ${serverfiles}"
		chmod u+x "${serverfiles}/paperclip.jar"
		fn_clear_tmp
	else
		fn_print_fail_eol_nl
		fn_script_log_fatal "Copying to ${serverfiles}"
		core_exit.sh
	fi
}

fn_update_minecraft_compare(){
	# Removes dots so if statement can compare version numbers.
	fn_print_dots "Checking for update: ${remotelocation}"
	localbuild=$(unzip -p ${serverfiles}/paperclip.jar version.json || echo -n "unknown")
	if [ ${localbuild} -eq "unknown" ]; then 
		localbuilddigit="unknown"
	else
		localbuilddigit=$(echo -n ${localbuild} | jq -r '.number' | sed 's/.$//')
	fi
	remotebuild=$(curl -s 'https://papermc.io/ci/job/Paper-1.15/lastSuccessfulBuild/api/json')
	remotebuilddigit=$(echo -n ${remotebuild} | jq -r '.number' | sed 's/.$//')
	if [ "${localbuilddigit}" -ne "${remotebuilddigit}" ]||[ "${forceupdate}" == "1" ]; then
		fn_print_ok_nl "Checking for update: ${remotelocation}"
		echo -en "\n"
		echo -e "Update available"
		echo -e "* Local build: ${red}${localbuilddigit}${default}"
		echo -e "* Remote build: ${green}${remotebuilddigt}${default}"
		fn_script_log_info "Update available"
		fn_script_log_info "Local build: ${localbuilddigit}"
		fn_script_log_info "Remote build: ${remotebuilddigt}"
		fn_script_log_info "${localbuilddigit} > ${remotebuilddigt}"
		fn_sleep_time
		echo -en "\n"
		echo -en "applying update.\r"
		sleep 1
		echo -en "applying update..\r"
		sleep 1
		echo -en "applying update...\r"
		sleep 1
		echo -en "\n"

		unset updateonstart

		check_status.sh
		# If server stopped.
		if [ "${status}" == "0" ]; then
			exitbypass=1
			fn_update_minecraft_dl
			exitbypass=1
			command_start.sh
			exitbypass=1
			command_stop.sh
		# If server started.
		else
			exitbypass=1
			command_stop.sh
			exitbypass=1
			fn_update_minecraft_dl
			exitbypass=1
			command_start.sh
		fi
		alert="update"
		alert.sh
	else
		fn_print_ok_nl "Checking for update: ${remotelocation}"
		echo -en "\n"
		echo -e "No update available"
		echo -e "* Local build: ${green}${localbuilddigt}${default}"
		echo -e "* Remote build: ${green}${remotebuilddigt}${default}"
		fn_script_log_info "No update available"
		fn_script_log_info "Local build: ${localbuilddigt}"
		fn_script_log_info "Remote build: ${remotebuilddigt}"
	fi
}

# The location where the builds are checked and downloaded.
remotelocation="papermc.io"

if [ "${installer}" == "1" ]; then
	fn_update_minecraft_dl
else
	fn_print_dots "Checking for update: ${remotelocation}"
	fn_script_log_info "Checking for update: ${remotelocation}"
	fn_update_minecraft_compare
fi