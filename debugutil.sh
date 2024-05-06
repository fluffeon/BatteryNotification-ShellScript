echo "Debug Utility for Battery Check"
echo "Make sure that Battery Check is running on debug mode."
echo ""
printf "Insert a battery percentage: "
read BatteryLevel
echo "Battery Status"
echo "0 = High"
echo "1 = Low"
echo "2 = Critical"
echo "3 = Charging"
printf "Insert your battery status: "
read BatteryStatus
echo "AC Status"
echo "0 = Off-Line"
echo "1 = On-Line"
printf "Insert AC status: "
read ACStatus

echo $BatteryLevel > /tmp/pw_BatteryLevelDebug &
echo $BatteryStatus > /tmp/pw_BatteryStatusDebug &
echo $ACStatus > /tmp/pw_ACStatusDebug &
