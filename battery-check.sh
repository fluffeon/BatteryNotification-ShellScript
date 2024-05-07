#!/bin/sh

pw_IconDir="/usr/local/share/icons/Adwaita"
pw_ExtraDir="/scalable/status"

# The name of the program, needs to be reachable in $PATH
pw_SoundEnabled="True"
pw_CustomMusicProgram="paplay" # Required if active
pw_SoundLocation="/home/fen/My working dirs/BatteryScript/Charging.wav" # Required if active

# Your program needs arguments? Parse them below.
pw_ArgumentsBeforeFile="" #Optional
pw_ArgumentsAfterFile="" # Optional

pw_LowBatteryPercentage=20
pw_CriticalLowBatteryPercentage=10

pw_CheckStatus() {
	case $pw_DebugMode in
	"True")

		case $1 in
		"BatteryLevel")
			pw_BatteryLevel="$(cat /tmp/pw_BatteryLevelDebug)";;
		"BatteryStatus")
			if [ "$pw_ACStatus" -eq 1 ]; then
				pw_BatteryStatus=3
			elif [ "$pw_BatteryLevel" -gt "$pw_LowBatteryPercentage" ] && [ "$pw_ACStatus" != 1 ]; then
				pw_BatteryStatus=0
			elif [ "$pw_BatteryLevel" -lt "$pw_CriticalLowBatteryPercentage" ] && [ "$pw_ACStatus" != 1 ]; then
				pw_BatteryStatus=2
			elif [ "$pw_BatteryLevel" -lt "$pw_LowBatteryPercentage" ] && [ "$pw_ACStatus" != 1 ]; then
				pw_BatteryStatus=1
			fi;;
		"ACStatus")
			pw_ACStatus="$(cat /tmp/pw_ACStatusDebug)";;
		*)
			pw_BatteryLevel="$(cat /tmp/pw_BatteryLevelDebug)"
    		pw_ACStatus="$(cat /tmp/pw_ACStatusDebug)"

			if [ "$pw_ACStatus" -eq 1 ]; then
				pw_BatteryStatus=3
			elif [ "$pw_BatteryLevel" -gt "$pw_LowBatteryPercentage" ] && [ "$pw_ACStatus" != 1 ]; then
				pw_BatteryStatus=0
			elif [ "$pw_BatteryLevel" -lt "$pw_CriticalLowBatteryPercentage" ]; then
				pw_BatteryStatus=2
			elif [ "$pw_BatteryLevel" -lt "$pw_LowBatteryPercentage" ] && [ "$pw_ACStatus" != 1 ]; then
				pw_BatteryStatus=1
			fi;;
		esac;;

	*)
	case $1 in
	"BatteryLevel")
		pw_BatteryLevel="$(apm -l)";;
  
	"BatteryStatus")
		# Battery Status
		# 0 = High
		# 1 = Low
		# 2 = Critical
		# 3 = Charging
		if [ "$pw_ACStatus" -eq 1 ]; then
			pw_BatteryStatus=3
		elif [ "$pw_BatteryLevel" -gt "$pw_LowBatteryPercentage" ] && [ "$pw_ACStatus" != 1 ]; then
			pw_BatteryStatus=0
		elif [ "$pw_BatteryLevel" -lt "$pw_CriticalLowBatteryPercentage" ] && [ "$pw_ACStatus" != 1 ]; then
			pw_BatteryStatus=2
		elif [ "$pw_BatteryLevel" -lt "$pw_LowBatteryPercentage" ] && [ "$pw_ACStatus" != 1 ]; then
			pw_BatteryStatus=1
		fi;;
      
	"ACStatus")
		# AC Status
		# 0 - Off-Line
		# 1 - On-Line
		# 2 - Backup Power
		pw_ACStatus="$(apm -a)";;

	*)
		pw_BatteryLevel="$(apm -l)"
    	pw_ACStatus="$(apm -a)"

		if [ "$pw_ACStatus" -eq 1 ]; then
			pw_BatteryStatus=3
		elif [ "$pw_BatteryLevel" -gt "$pw_LowBatteryPercentage" ] && [ "$pw_ACStatus" != 1 ]; then
			pw_BatteryStatus=0
		elif [ "$pw_BatteryLevel" -lt "$pw_CriticalLowBatteryPercentage" ]; then
			pw_BatteryStatus=2
		elif [ "$pw_BatteryLevel" -lt "$pw_LowBatteryPercentage" ] && [ "$pw_ACStatus" != 1 ]; then
			pw_BatteryStatus=1
		fi

	esac
	esac
}

pw_ChangeIcon() {
	if [ "$pw_BatteryStatus" -eq 3 ] || [ "$pw_ACStatus" -eq 1 ]; then
		local pw_Suffix="-charging"
	else
		local pw_Suffix=""
	fi

	if [ "$pw_ACStatus" -eq 1 ] && [ "$pw_BatteryStatus" -eq 3 ] && [ "$pw_BatteryLevel" -eq 100 ]; then
    	local pw_PercentageNumberIcon="100-charged"
	else
		local pw_BatteryLevel2=$(($pw_BatteryLevel / 10 * 10))
		local pw_PercentageNumberIcon="$pw_BatteryLevel2$pw_Suffix"
	fi

	pw_NotifIcon="$pw_IconDir$pw_ExtraDir/battery-level-$pw_PercentageNumberIcon-symbolic.svg"
}

pw_SummonNotif() {

	# Arguments
	local pw_NotifTitle="$1"
	local pw_NotifSubtitle="$2"
	local pw_NotifUrgency="$3"

	# Notify routines
	if [ -z "$pw_NotifTitle" ] && [ -z "$pw_NotifSubtitle" ]; then
		echo "Missing arguments"
	else
		notify-send -r 27078 "$pw_NotifTitle" "$pw_NotifSubtitle" -i "$pw_NotifIcon" -u "$pw_NotifUrgency" &
	fi

}

pw_ForbiddenPrograms="echo rm touch cp mv mkdir printf rmdir"

pw_OneWordCheck() {
	
	if [ -z "$pw_CustomMusicProgram" ] || [ -z "$pw_SoundLocation" ]; then
		echo "[Error] One or more required variables are empty."
		exit 1
	else
	
		local pw_Counter=0
	
		for pw_CommandIteration1 in $pw_CustomMusicProgram; do
			if [ $pw_Counter != 0 ]; then
				echo "[Error] Command is longer than one word."
				exit 1
			fi
			local pw_Counter=$(($pw_Counter + 1))
		done

		for pw_CommandIteration2 in $pw_ForbiddenPrograms; do
			if [ "$pw_CustomMusicProgram" = "$pw_CommandIteration2" ]; then
				echo "[Error] ""'"$pw_CommandIteration2"'"" is not allowed."
				exit 1
			fi
		done
	fi

	for pw_Word in $pw_ForbiddenPrograms; do
    	echo "$pw_ArgumentsAfterFile" | grep -q "$pw_Word"
    
		if [ $? -eq 0 ]; then
        	echo "[Error] ""'"$pw_ArgumentsAfterFile"'"" is not allowed."
			exit 1
    	fi
	done

	for pw_Word in $pw_ForbiddenPrograms; do
    	echo "$pw_ArgumentsBeforeFile" | grep -q "$pw_Word"
    	
		if [ $? -eq 0 ]; then
        	echo "[Error] ""'"$ArgumentsBeforeFile"'"" is not allowed."
			exit 1
    	fi
	done

}

if [ $pw_SoundEnabled = "True" ]; then
	pw_OneWordCheck
else
	unset pw_CustomMusicProgram
	unset pw_SoundLocation
	unset pw_ArgumentsBeforeFile
	unset pw_ArgumentsAfterFile
fi

pw_Sound() {
	if [ "$pw_SoundEnabled" = "True" ]; then
		eval "$pw_CustomMusicProgram" "$pw_ArgumentsBeforeFile" "'""$pw_SoundLocation""'" "$pw_ArgumentsAfterFile" &
	fi
}

pw_DischargeNotif() {
	pw_ChangeIcon
	
	if [ "$pw_ACStatus" = 1 ]; then
    if [ "$(cat /tmp/pw_BatteryDaemon)" = "X11" ]; then
			if [ "$pw_BatteryLevel" = 100 ]; then
				pw_SummonNotif "Charged - $pw_BatteryLevel%" "" "normal"
			else
				pw_SummonNotif "Charging - $pw_BatteryLevel%" "" "normal"
			fi
		else
			if [ "$pw_BatteryLevel" = 100 ]; then
				pw_SummonNotif "[Charged] $pw_BatteryLevel%"
			else
				echo "[Charging] $pw_BatteryLevel%"
			fi
		fi
	else
		local pw_Counter=0
		while true; do
			pw_CheckStatus ACStatus
			pw_CheckStatus BatteryStatus
			if [ "$pw_Counter" -eq 10 ]; then
				return 1
			elif [ "$pw_BatteryStatus" != 3 ] && [ "$pw_ACStatus" -eq 0 ]; then
				break
			fi

			sleep 0.5s
			local pw_Counter=$(($pw_Counter + 1))
		done
	
	  
    pw_CheckStatus BatteryLevel
    
    if [ "$(cat /tmp/pw_BatteryDaemon)" = "X11" ]; then
		case $pw_BatteryStatus in
			0)
				pw_SummonNotif "Discharging - $pw_BatteryLevel%" "" "low" &;;
			1)
				pw_SummonNotif "Low Battery - $pw_BatteryLevel%" "Charge your laptop." "normal" &;;
			2)
				pw_SummonNotif "Critical Low Battery - $pw_BatteryLevel%" "Charge your laptop or it will shut down soon." "critical" &;;
		esac
  else 
		case $pw_BatteryStatus in
        	0)
        		echo "[Discharging] $pw_BatteryLevel%";;
    		1)
        		echo "[Low Battery] $pw_BatteryLevel% - Charge your laptop.";;
    		2)
        		echo "[Critical Low Battery] - $pw_BatteryLevel% - Charge your laptop or it will shut down soon.";;
		esac
    fi

    fi

  return
}

pw_QuitDaemon() {
	rm /tmp/pw_BatteryDaemon
	exit 0
}

pw_CheckStatus

pw_CurrentBatteryStatus="$pw_BatteryStatus"

if [ "$pw_CurrentBatteryStatus" = 3 ] || [ "$pw_ACStatus" = 1 ]; then
	pw_Charging="True"
elif [ "$pw_CurrentBatteryStatus" != 3 ] || [ "$pw_ACStatus" != 1 ]; then
	pw_Charging="False"
fi

if [ "$pw_BatteryLevel" = 100 ]; then
	pw_BatteryFull="True"
else
	pw_BatteryFull="False"
fi

pw_MainModule() {

	pw_CheckStatus

	if [ "$pw_CLIBehaviorLockin" != "True" ] ; then
		if [ "$pw_DebugMode" != "True" ] && [ -z "$DISPLAY" ]; then
    		echo "CLI" > /tmp/pw_BatteryDaemon
		elif [ "$pw_DebugMode" != "True" ] && [ -n "$DISPLAY" ]; then
    		echo "X11" > /tmp/pw_BatteryDaemon
  		fi
	fi

	if [ "$pw_ACStatus" -eq 0 ] && [ "$pw_Charging" = "True" ]; then
		pw_ChangeIcon
    	if pw_DischargeNotif; then
    		pw_Charging="False"
		fi
	elif [ "$pw_ACStatus" -eq 1 ] && [ "$pw_Charging" = "False" ]; then
		pw_ChangeIcon
		if [ $pw_SoundEnabled = "True" ]; then
			pw_Sound
		fi
    	pw_DischargeNotif
    	pw_Charging="True"
	fi

	sleep 0.1s

	if [ "$pw_BatteryLevel" -eq 100 ] && [ "$pw_BatteryFull" = "False" ]; then
		pw_ChangeIcon
		pw_DischargeNotif
		pw_BatteryFull="True"
	elif [ "$pw_BatteryLevel" != 100 ]; then
		pw_BatteryFull="False"
	fi

	if [ "$pw_BatteryStatus" != "$pw_CurrentBatteryStatus" ] && [ "$pw_Charging" = "False" ]; then
		pw_DischargeNotif
    	pw_CurrentBatteryStatus="$pw_BatteryStatus"
	fi

}

case $1 in
  "help")
    echo "./battery-check.sh [arg1] [arg2]]"
    echo "help - Shows the help information"
    echo "daemon [subargs: cli] - Runs this script as a cron job/daemon"
    exit 0;;
	"daemon")
		if [ -e /tmp/pw_BatteryDaemon ]; then
			echo "[Error] You already have a battery daemon running."
			exit 1
		fi
	
  if [ "$2" = "cli" ]; then
    pw_CLIBehaviorLockin="True"
    pw_DebugMode="False"
  elif [ "$2" = "debug" ]; then
	echo "Debug mode activated."
	echo 95 > /tmp/pw_BatteryLevelDebug
	echo 0 > /tmp/pw_ACStatusDebug
	pw_DebugMode="True"
    pw_CLIBehaviorLockin="False"
else
pw_DebugMode="False"
pw_CLIBehaviorLockin="False"
  fi

	if [ "$pw_CLIBehaviorLockin" = "False" ] && [ ! -z $DISPLAY ]; then
		echo "X11" > /tmp/pw_BatteryDaemon
  elif [ $pw_CLIBehaviorLockin = "True" ] || [ -z $DISPLAY ]; then
		echo "CLI" > /tmp/pw_BatteryDaemon
	fi

    	trap pw_QuitDaemon INT
		trap pw_QuitDaemon TERM
		trap pw_QuitDaemon ABRT
		trap pw_QuitDaemon QUIT
		trap pw_QuitDaemon HUP
    	while true; do
	    	pw_MainModule	
	    	sleep 0.5s
    	done;;

	*)
	
	if [ ! -e /tmp/pw_BatteryDaemon ]; then
		if [ "$1" != "cli" ] && [ ! -z $DISPLAY ]; then
			echo "X11" > /tmp/pw_BatteryDaemon
			pw_ChangeIcon
		else
			echo "CLI" > /tmp/pw_BatteryDaemon
		fi

    		pw_DischargeNotif
		rm /tmp/pw_BatteryDaemon
	else
		pw_DischargeNotif
	fi
	;;
esac
