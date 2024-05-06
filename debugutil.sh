echo "Debug Utility for Battery Check - Version 1.1"
echo "Make sure that Battery Check is running on debug mode."
echo ""
printf "Insert a battery percentage: "
read BatteryLevel

echo "AC Status"
echo "0 = Off-Line"
echo "1 = On-Line"
printf "Insert AC status: "
read ACStatus

echo $BatteryLevel > /tmp/pw_BatteryLevelDebug &
echo $BatteryStatus > /tmp/pw_BatteryStatusDebug &
echo $ACStatus > /tmp/pw_ACStatusDebug &
