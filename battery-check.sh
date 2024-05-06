#!/bin/sh

pw_IconDir="/usr/local/share/icons/Adwaita"
pw_ExtraDir="/scalable/status"
pw_SoundSystem="pulse"

pw_CheckStatus() {
case $pw_DebugMode in
"True")

	case $1 in
	"BatteryLevel")
		pw_BatteryLevel="$(cat /tmp/pw_BatteryLevelDebug)";;
	"BatteryStatus")
		pw_BatteryStatus="$(cat /tmp/pw_BatteryStatusDebug)";;
	"ACStatus")
		pw_ACStatus="$(cat /tmp/pw_ACStatusDebug)";;
	*)
		pw_BatteryLevel="$(cat /tmp/pw_BatteryLevelDebug)"
		pw_BatteryStatus="$(cat /tmp/pw_BatteryStatusDebug)"
		pw_ACStatus="$(cat /tmp/pw_ACStatusDebug)";;
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
		pw_BatteryStatus="$(apm -b)";;
      
	"ACStatus")
		# AC Status
		# 0 - Off-Line
		# 1 - On-Line
		# 2 - Backup Power
		pw_ACStatus="$(apm -a)";;

	*)
		pw_BatteryLevel="$(apm -l)"
    		pw_BatteryStatus="$(apm -b)"
    		pw_ACStatus="$(apm -a)"
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


#	if [ "$pw_BatteryStatus" -eq 3 ] && [ "$pw_BatteryLevel" -eq 100 ]; then
#		local pw_PercentageNumberIcon="100-charged"
#	else
#		local pw_BatteryLevel2=$(($pw_BatteryLevel / 10 * 10))
#		local pw_PercentageNumberIcon="$pw_BatteryLevel2$pw_Suffix"
#	fi

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
		notify-send -r 27072 "$pw_NotifTitle" "$pw_NotifSubtitle" -i "$pw_NotifIcon" -u "$pw_NotifUrgency" &
	fi

}

pw_Sound() {
	case $pw_SoundSystem in
		"oss")
			cat Charging.raw > /dev/dsp &;;
		"pulse")
			paplay "/home/fen/My working dirs/BatteryScript/Charging.wav" >> /dev/null &;;
	esac
}

pw_DischargeNotif() {
	pw_ChangeIcon
	
	if [ $pw_ACStatus = 1 ]; then
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
				echo "[Charged] $pw_BatteryLevel%"
			fi
		fi
	else
		local pw_Counter=0
		while true; do
			pw_CheckStatus BatteryStatus
			pw_CheckStatus ACStatus
			if [ "$pw_Counter" -eq 10 ]; then
				return 1
			elif [ "$pw_BatteryStatus" != 3 -a "$pw_ACStatus" -eq 0 ]; then
				break
			fi

			sleep 0.5s
			local pw_Counter=$(($pw_Counter + 1))
		done
	
	  
    pw_CheckStatus BatteryLevel
    
    if [ "$(cat /tmp/pw_BatteryDaemon)" = "X11" ]; then
		case $pw_BatteryStatus in
			0)
				pw_SummonNotif "Discharging - $pw_BatteryLevel%" "" "normal" &;;
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

#	if [ "$pw_DebugMode" = "True" ]; then
#		rm /tmp/pw_BatteryLevelDebug
#		rm /tmp/pw_BatteryStatusDebug
#		rm /tmp/pw_ACStatusDebug
#	fi

	exit 0
}

#if [ $pw_BatteryStatus -eq 3 ]; then
#	pw_Subtitle="Charging"
#else
#	pw_Subtitle="Discharging"
#fi

#pw_SummonNotif "Battery Left: $pw_BatteryLevel%" "$pw_Subtitle" "low"
pw_CheckStatus

pw_CurrentBatteryStatus="$pw_BatteryStatus"
pw_CurrentBatteryPercentage="$pw_BatteryLevel"
pw_CurrentACStatus="$pw_ACStatus"

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
  if [ "$pw_DebugMode" != "True" ]; then
  if [ "$CLIBehaviorLockin" = "True" ] || [ -z $DISPLAY ]; then
    echo "CLI" > /tmp/pw_BatteryDaemon
  elif [ "$CLIBehaviorLockin" = "False" ] && [ ! -z $DISPLAY ]; then
    echo "X11" > /tmp/pw_BatteryDaemon
  fi
  fi

	if [ "$pw_ACStatus" = 0 -a "$pw_Charging" = "True" ]; then
		pw_ChangeIcon
    	if pw_DischargeNotif; then
    		pw_Charging="False"
		fi
	elif [ "$pw_ACStatus" = 1 -a "$pw_Charging" = "False" ]; then
		pw_ChangeIcon
		pw_Sound
    	pw_DischargeNotif
    	pw_Charging="True"
    	pw_LowBattery="False"
    	pw_CriticalBattery="False"
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
    	pw_CurrentBatteryPercentage="$pw_BatteryLevel"
    	pw_CurrentBatteryStatus="$pw_BatteryStatus"
    	pw_CurrentACStatus="$pw_ACStatus"
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
			echo "You already have a battery daemon running."
			exit 1
		fi
	
  if [ "$2" = "cli" ]; then
    pw_CLIBehaviorLockin="True"
    pw_DebugMode="False"
  elif [ "$2" = "debug" ]; then
	echo "Debug mode activated."
	echo 95 > /tmp/pw_BatteryLevelDebug
	echo 0 > /tmp/pw_BatteryStatusDebug
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

    	trap pw_QuitDaemon SIGINT
		trap pw_QuitDaemon SIGTERM
		trap pw_QuitDaemon SIGKILL
		trap pw_QuitDaemon SIGABRT
		trap pw_QuitDaemon SIGQUIT
		trap pw_QuitDaemon SIGHUP
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
