//PRINT "=========================================".
//PRINT "      HELLO WORLD".
//PRINT "THIS IS THE FIRST SCRIPT I WROTE IN kOS.".
//PRINT "=========================================".

//This is our countdown loop, which cycles from 10 to 0
//PRINT "Counting down:".
LOCK THROTTLE TO 1.0.   // 1.0 is the max, 0.0 is idle.
LOCK STEERING TO UP.
RCS OFF.
//FROM {local countdown is 10.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
  //  PRINT "..." + countdown.
 //   WAIT 1. // pauses the script here for 1 second.
//}
PRINT "STAGING...".
STAGE.
PRINT "LIFTOFF".
//SET WARP TO 1.
WAIT UNTIL ALTITUDE > 10000.
SET WARP TO 0.
PRINT "BEGIN GRAVITY TURN...".
SET MYSTEER TO HEADING(90,90). //90 degrees east and pitched up 90 degrees (straight up)
LOCK STEERING TO MYSTEER. // from now on we'll be able to change steering by just assigning a new value to MYSTEER
UNTIL APOAPSIS > 90000 {
	// 90-(((10000/(100000-20000))*90))
	SET MYVANGLE TO (90-(((10000/(100000-(SHIP:APOAPSIS-10000)))*90))).
    SET MYSTEER TO HEADING(90,MYVANGLE). //90 degrees east and pitched up 90 degrees (straight up)
    PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16). // prints new number, rounded to the nearest integer.
    PRINT ROUND(MYVANGLE) AT (0,17).
	//We use the PRINT AT() command here to keep from printing the same thing over and
    //over on a new line every time the loop iterates. Instead, this will always print
    //the apoapsis at the same point on the screen.
	//SET WARP TO 1.
}.
	SET WARP TO 0.
LOCK THROTTLE TO 0.0.
PRINT "GRAVITY TURN COMPLETE. APO > 90KM".
// Calculate time to apoapsis
SET TIMETOAPO TO ((SHIP:APOAPSIS-SHIP:ALTITUDE)/SHIP:VERTICALSPEED).
PRINT "Time to (roughly) apoapsis: " + TIMETOAPO.
SET MYSTEER TO HEADING(90,0).
RCS ON.
WAIT TIMETOAPO.
PRINT "Apoapsis reached.".
SET MYSTEER TO HEADING(90,00).
UNTIL PERIAPSIS > 90000 {
	  PRINT ROUND(SHIP:PERIAPSIS,0) AT (0,16). // prints new number, rounded to the nearest integer.
	//We use the PRINT AT() command here to keep from printing the same thing over and
    //over on a new line every time the loop iterates. Instead, this will always print
    //the apoapsis at the same point on the screen.

	RCS OFF.
	SET TIMETOAPO TO ((SHIP:APOAPSIS-SHIP:ALTITUDE)/SHIP:VERTICALSPEED).
	
	IF TIMETOAPO > 30 { 
		RCS ON.
		LOCK THROTTLE TO 0.0.
		WAIT 1.
	} ELSE {
		IF SHIP:PERIAPSIS > 70000 {
			IF (TIMETOAPO < 20) { LOCK THROTTLE TO 0.1. }
			} ELSE IF (TIMETOAPO < 20) {
			LOCK THROTTLE TO 1.0.}
			
	}
	SET MYSTEER TO HEADING(90,00).
	
	//SET WARP TO 1.
}.
LOCK THROTTLE TO 0.0.
SET THROTTLE TO 0.0.
//SET WARP TO 0.