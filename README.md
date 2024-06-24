# Battery-Check Shell Script
This is a simple battery indicator built in sh. This was made for FreeBSD but should work on Linux aswell.

Dependencies
------------
 - apm
 - (*maybe optional)* Adwaita icons

> **Note:** Other icon sets *might* work but I haven't tested yet and I can't guarantee that all icon sets work.

Configuration
-------------
**All configuration** is done by editing the shell script directly.

|Variable|Value|Details|
|-------------------------------|-------|--|
|pw_IconDir                     |String |Specifies the directory where the icon pack is located (Default: `"/usr/local/share/icons/Adwaita"`)|
|pw_ExtraDir                    |String |Specifies the subdirectory inside the icon pack directory in where the battery icons are located (Default: `"/scalable/icons`)  |
|pw_SoundSystem                 |String |Specifies the sound system to use (options: `oss` or `pulse`, default: `pulse`)  |
|pw_LowBatteryPercentage        |Integer|Specifies the percentage to show the low battery toast. |
|pw_CriticalLowBatteryPercentage|Integer|Specifies the percentage to show the critical low battery toast.|

