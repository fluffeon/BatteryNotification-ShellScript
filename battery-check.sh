#!/bin/sh

pw_IconDir="/usr/local/share/icons/Adwaita"
pw_ExtraDir="/scalable/status"
pw_SoundSystem="pulse"

pw_CheckStatus() {
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
			paplay Charging.wav &;;
	esac
}

pw_DischargeNotif() {
	pw_ChangeIcon
	
	if [ $pw_ACStatus = 1 ]; then
		pw_Sound
		pw_SummonNotif "Charging - $pw_BatteryLevel%" "" "normal"
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

		case $pw_BatteryStatus in
			0)
				pw_SummonNotif "Discharging - $pw_BatteryLevel%" "" "normal" &;;
			1)
				w_SummonNotif "Low Battery - $pw_BatteryLevel%" "Charge your laptop." "normal" &;;
			2)
				pw_SummonNotif "Critical Low Battery - $pw_BatteryLevel%" "Charge your laptop or it will shut down soon." "critical" &;;
		esac
	
	fi

  return
}

pw_QuitDaemon() {
	rm /tmp/pw_BatteryDaemon
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
elif [ "$pw_CurrentBatteryStatus" != 3 ] || [ "$pw_ACStatus" != 1]; then
	pw_Charging="False"
fi

pw_MainModule() {

	pw_CheckStatus
	
	if [ "$pw_BatteryLevel" -eq 100 ] \
	&& [ "$pw_ACStatus" -eq 1 ] \
	&& [ "$pw_Charging" -eq "False" ]; then
		pw_ChangeIcon
    	pw_SummonNotif "Charged - $pw_BatteryLevel%" "You can disconnect your charger now." "normal"
    	pw_Charging="True";
	elif [ "$pw_ACStatus" = 0 -a "$pw_Charging" = "True" ]; then
    	if pw_DischargeNotif; then
    		pw_Charging="False"
		fi
	elif [ "$pw_ACStatus" = 1 -a "$pw_Charging" = "False" ]; then
    	pw_DischargeNotif
    	pw_Charging="True"
    	pw_LowBattery="False"
    	pw_CriticalBattery="False"
	fi

	sleep 0.1s

	if [ "$pw_BatteryStatus" != "$pw_CurrentBatteryStatus" ] && [ "$pw_Charging" = "False" ]; then
		pw_DischargeNotif
    	pw_CurrentBatteryPercentage="$pw_BatteryLevel"
    	pw_CurrentBatteryStatus="$pw_BatteryStatus"
    	pw_CurrentACStatus="$pw_ACStatus"
	fi
}

case $1 in
	"daemon")
		if [ -e /tmp/pw_BatteryDaemon ]; then
			echo "You already have a battery daemon running."
			exit 1
    	else
			touch /tmp/pw_BatteryDaemon
		fi

    	trap pw_QuitDaemon SIGINT
    	while true; do
	    	pw_MainModule	
	    	sleep 0.5s
    	done;;
	*)
    	pw_ChangeIcon
    	pw_DischargeNotif;;
esac
