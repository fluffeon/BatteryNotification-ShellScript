#!/bin/sh

pw_IconDir="/usr/local/share/icons/Adwaita"
pw_ExtraDir="/scalable/status"
pw_SoundSystem="oss"

pw_CheckStatus() {
	pw_BatteryLevel="$(apm -l)"

	# Battery Status
	# 0 = High
	# 1 = Low
	# 2 = Critical
	# 3 = Charging
	pw_BatteryStatus="$(apm -b)"

	# AC Status
	# 0 - Off-Line
	# 1 - On-Line
	# 2 - Backup Power
	pw_ACStatus="$(apm -a)"
}

pw_ChangeIcon() {
	if [ "$pw_BatteryStatus" -eq 3 ] || [ "$pw_ACStatus" -eq 1 ]; then
		local pw_Suffix="-charging"
	else
		local pw_Suffix=""
	fi

	if    [ "$pw_ACStatus" -eq 1 ] \
	&& [ "$pw_BatteryLevel" -eq 100 ] \
	|| [ "$pw_BatteryStatus" -eq 3 ]; then
    	local pw_PercentageNumberIcon="100-charged";
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
			cat Charging.raw > /dev/dsp &
			;;
	esac
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


while true; do

	if     [ "$pw_BatteryLevel" -eq 100 ] \
		&& [ "$pw_ACStatus" -eq 1 ] \
		&& [ "$pw_Charging" -eq "False" ]; then
			pw_ChangeIcon
			pw_SummonNotif "Charged - $pw_BatteryLevel%" "You can disconnect your charger now." "normal"
			pw_Charging="True";
	elif [ "$pw_ACStatus" = 0 -a "$pw_Charging" = "True" ]; then
		pw_ChangeIcon
		pw_SummonNotif "Discharging - $pw_BatteryLevel%" "" "normal"
		pw_Charging="False"
	elif [ "$pw_ACStatus" = 1 -a "$pw_Charging" = "False" ]; then
			pw_ChangeIcon
			pw_Sound &
			pw_SummonNotif "Charging - $pw_BatteryLevel%" "" "normal"
			pw_Charging="True"
	fi
	
	if [ "$pw_BatteryLevel" != "$pw_CurrentBatteryPercentage" ] || [ "$pw_BatteryStatus" != "$pw_CurrentBatteryStatus" ] || [ "$pw_ACStatus" != "$pw_CurrentACStatus" ]; then
		
		case $pw_BatteryLevel in
			1)
			pw_ChangeIcon
			pw_SummonNotif "Low Battery - $pw_BatteryLevel%" "Please charge your laptop." "normal";;
			2)
			pw_ChangeIcon
			pw_SummonNotif "Critical Low Battery - $pw_BatteryLevel%" "You should charge your laptop or else it will shutdown soon." "critical";;
		esac

		


		pw_CurrentBatteryPercentage="$pw_BatteryLevel"
		pw_CurrentBatteryStatus="$pw_BatteryStatus"
		pw_CurrentACStatus="$pw_ACStatus"
	fi
	
	pw_CheckStatus
	sleep 0.5s
done
