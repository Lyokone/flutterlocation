## [2.0.0] 25th January 2019
* Code cleanup
* BREAKING CHANGE: Change Dart API to return structured data rather than a map.

## [1.4.0] 21st August 2018
* Add lazy permission request thanks to yathit
* Add hasPermission() thanks to vagrantrobbie
* Bug correction thanks to jalpedersen
* Add more examples  

## [1.3.4] 4th June 2018
* Fix crash for Android API pre 27 thanks to matthewtsmith.


## [1.3.3] 30th May 2018
* Correct implementation of iOS plugin to match Android behaviour. No need to call getLocation 
to get permissions for location callbacks.


## [1.3.2] 30th May 2018
* Change implementation to api in build.gradle in order to solve incompatibilities between 
GMS versions thanks to luccascorrea 

## [1.3.1] 29th May 2018
* Added speed and speed_accuracy (only Android truly discover speed accuracy, so its always 0 for now on iOS)
* Solved a crash


## [1.3.0] 27th May 2018
* Make it compatible with Firebase thanks to quangIO
* Resolve runtime error exception thanks to jharrison902  
* Update gitignore thanks to bcko


## [1.2.0] 5th April 2018
* Permissions denied on Android handled thanks to g123k 
* Dart 2 update thanks to efortuna

## [1.1.6] - 19th Octobre 2017.

* iOS code from Swift to Objective-C thanks to fluff

## [1.1.1] - 20th July 2017.

* Fixes for iOS result's format.


## [1.1.0] - 17th July 2017.

* Added permission check for Android 6+ (thanks netdur). Still no callback when permissions granted
so aiming SDK 21 is safer.

## [1.0.0] - 7th July 2017.

* Initial Release.
