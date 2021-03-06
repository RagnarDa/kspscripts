// LTLS VTVL SSTO Script by RagnarDa 2016
////SET WARP TO 1.
SET TARGETORBIT TO 80000.
SET RETURNORBIT TO 71000.
SET GRAVITYTURNHEIGHT TO 50.
SET TIPPINGRESTRICTION TO 20.
PRINT SHIP:GEOPOSITION:LNG.
PRINT SHIP:GEOPOSITION:LAT.
SET STARTINGPOS TO SHIP:GEOPOSITION.
SET STARTINGLONGITUDE TO SHIP:GEOPOSITION:LNG.
SET STARTINGLATITUDE TO SHIP:GEOPOSITION:LAT.
//SET BURNLONGITUDE TO STARTINGLONGITUDE - (175+122.8225).
//SET BURNLONGITUDE TO STARTINGLONGITUDE - 97.82.
SET BURNLONGITUDE TO STARTINGLONGITUDE - 98.5.//((97.82+100.842)/2).//100.842.//100.45.//99.742.
//SET BURNLONGITUDE TO STARTINGLONGITUDE - 77.00.
IF (BURNLONGITUDE < -180) {SET BURNLONGITUDE TO BURNLONGITUDE + 360.}.
PRINT "Return longitude: " + burnlongitude.
//PRINT FACING:PITCH.
//PRINT FACING:YAW.
LOCK THROTTLE TO 1.0.   // 1.0 is the max, 0.0 is idle.
LOCK STEERING TO HEADING(90,90).
RCS OFF.
//FROM {local countdown is 10.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
  //  PRINT "..." + countdown.
 //   WAIT 1. // pauses the script here for 1 second.
//}
PRINT "STAGING...".
STAGE.
PRINT "LIFTOFF".
LOG "Liftoff." to orbitertwolog.txt.
WAIT UNTIL ALTITUDE > 40.
LOG "Altitude 200." to orbitertwolog.txt.
IF TRUE {
GEAR OFF.
GEAR OFF.
PRINT "GEAR RETRACTED.".
LOCK STEERING TO HEADING(90,90.0).
////SET WARP TO 1.
WAIT UNTIL ALTITUDE > GRAVITYTURNHEIGHT.
LOG "Altitude 10000." to orbitertwolog.txt.
//SET WARP TO 0.
PRINT "BEGIN GRAVITY TURN...".
SET MYSTEER TO HEADING(90,90). //90 degrees east and pitched up 90 degrees (straight up)
LOCK STEERING TO MYSTEER. // from now on we'll be able to change steering by just assigning a new value to MYSTEER
SET LASTANGLE TO 90.
SET LASTTHROTTLE TO 1.
SET USETHROTTLEDASCENT TO TRUE.
UNTIL APOAPSIS > TARGETORBIT {
	// 90-(((10000/(100000-20000))*90))
	//SET MYVANGLE TO ((90-(((GRAVITYTURNHEIGHT/(TARGETORBIT-(SHIP:APOAPSIS-GRAVITYTURNHEIGHT)))*90) * 4.0))/1)+0.0.
	SET MYVANGLE TO ((90-((SHIP:APOAPSIS/(TARGETORBIT-0))*90))).
   IF (MYVANGLE < LASTANGLE - 0.02) { SET MYVANGLE TO LASTANGLE - 0.02. }.
		SET LASTANGLE TO MYVANGLE.
	IF (ALTITUDE > 1000)
	{
		// REDUCE THRUST TO USE PROPER GRAVITY TURN.
		SET VV TO SHIP:VERTICALSPEED.
		SET HV TO SHIP:GROUNDSPEED.
		SET PROGRADEANGLE TO (ARCTAN(VV/HV)).// * 57.2957795.
		//PRINT "PROGRADANGLE:" + PROGRADEANGLE.
		//PRINT "MYVANGLE: " + MYVANGLE.
		//IF (SHIP:APOAPSIS > 40000) {
		//	SET USETHROTTLEDASCENT TO TRUE.
		//}.
		IF (USETHROTTLEDASCENT) {
			IF (PROGRADEANGLE > MYVANGLE) {
				SET LASTTHROTTLE TO (LASTTHROTTLE - 0.00075).
			//	PRINT "DECREASING THROTTLE.".
			} ELSE {
				SET LASTTHROTTLE TO (LASTTHROTTLE + 0.00075).
			//	PRINT "INCREASING THROTTLE.".
				}.
			IF (LASTTHROTTLE < 0) { SET LASTTHROTTLE TO 0.}.
			IF (LASTTHROTTLE > 1) { SET LASTTHROTTLE TO 1.}.
		}.
	}.
	LOCK THROTTLE TO LASTTHROTTLE.
	SET MYSTEER TO HEADING(90,(MYVANGLE)). //90 degrees east and pitched up 90 degrees (straight up)
    PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16). // prints new number, rounded to the nearest integer.
    PRINT (MYVANGLE) AT (0,17).
	
	WAIT 0.01.
	//We use the PRINT AT() command here to keep from printing the same thing over and
    //over on a new line every time the loop iterates. Instead, this will always print
    //the apoapsis at the same point on the screen.
	////SET WARP TO 1.
}.
LOG "APO > TARGET ORBIT." to orbitertwolog.txt.
	//SET WARP TO 0.
LOCK THROTTLE TO 0.0.
PRINT "GRAVITY TURN COMPLETE. APO > 90KM".
IF (USETHROTTLEDASCENT = FALSE)
{
// Calculate time to apoapsis
SET TIMETOAPO TO ((SHIP:APOAPSIS-SHIP:ALTITUDE)/SHIP:VERTICALSPEED).
PRINT "Time to (roughly) apoapsis: " + TIMETOAPO.
LOCK MYSTEER TO HEADING(90,0).
RCS ON.
//SET WARP TO 1.
WAIT TIMETOAPO-20.
//SET WARP TO 0.
LOCK MYSTEER TO HEADING(90,00).
RCS OFF.
WAIT 20.
RCS ON.
PRINT "Apoapsis reached.".
LOCK MYSTEER TO HEADING(90,00).
UNTIL PERIAPSIS > TARGETORBIT {
	  PRINT ROUND(SHIP:PERIAPSIS,0) AT (0,16). // prints new number, rounded to the nearest integer.
	//We use the PRINT AT() command here to keep from printing the same thing over and
    //over on a new line every time the loop iterates. Instead, this will always print
    //the apoapsis at the same point on the screen.

	RCS OFF.
	SET TIMETOAPO TO ((SHIP:APOAPSIS-SHIP:ALTITUDE)/SHIP:VERTICALSPEED).
	
	IF TIMETOAPO > 30 { 
		//RCS ON.
		LOCK THROTTLE TO 0.0.
		WAIT 1.
	} ELSE {
		IF SHIP:PERIAPSIS > 10000 {
			IF (TIMETOAPO < 20) { LOCK THROTTLE TO 0.1. }
			} ELSE IF (TIMETOAPO < 20) {
			LOCK THROTTLE TO 1.0.}
			
	}
	SET MYSTEER TO HEADING(90,00).
	
	////SET WARP TO 1.
}.
}.
RCS OFF.
LOCK THROTTLE TO 0.0.
SET THROTTLE TO 0.0.
////SET WARP TO 0.
LOG "In orbit." to orbitertwolog.txt.
PRINT "Waiting to decouple (to make sure throttel off.".
LOCK THROTTLE TO 0.0.
WAIT 10.
LOCK THROTTLE TO 0.0.
PRINT "Decoupling...".
STAGE.
LOCK THROTTLE TO 0.0.
SET THROTTLE TO 0.0.
LOG "Decoupled." to orbitertwolog.txt.
PRINT "Waiting 15 seconds...".
WAIT 15.
PRINT "Turning to retrograde...".
RCS ON.
SET MYSTEER TO RETROGRADE.
IF (TRUE) {
WAIT 30.
PRINT "Burning retrograde.".
RCS ON.
LOCK MYSTEER TO RETROGRADE.
LOCK THROTTLE TO 0.1.
WAIT UNTIL PERIAPSIS < RETURNORBIT.
RCS OFF.
LOCK THROTTLE TO 0.0.
PRINT "Done.".
WAIT 2.
PRINT "WAITING TO APO PASSED.".
WAIT UNTIL SHIP:VERTICALSPEED < 0.
SET TIMETOPERI TO ETA:PERIAPSIS.//((((SHIP:PERIAPSIS-SHIP:ALTITUDE)/(SHIP:VERTICALSPEED)))*2).
PRINT "Time to periapsis: " + TIMETOPERI.
//SET WARP TO 1.
WAIT TIMETOPERI - 120.
PRINT "At periapsis - 120 seconds.".
//PRINT "Waiting to altitude < 75100".
LOCK MYSTEER TO RETROGRADE.
//WAIT UNTIL SHIP:ALTITUDE < 75100.
RCS ON.
//LOCK MYSTEER TO RETROGRADE.
//PRINT "Waiting to passing periapsis...".
//WAIT UNTIL SHIP:VERTICALSPEED > 0.
//LOCK MYSTEER TO RETROGRADE.

//RCS ON.
//LOCK MYSTEER TO RETROGRADE.
//WAIT 2.
//SET WARP TO 0.
RCS OFF.
LOCK MYSTEER TO RETROGRADE.
PRINT "Waiting 110 seconds to align.".
WAIT 110.
RCS ON.
LOCK MYSTEER TO RETROGRADE.
PRINT "Brake burning til circular.".
LOCK THROTTLE TO 0.1.
WAIT UNTIL PERIAPSIS < SHIP:ALTITUDE - 100.
LOCK THROTTLE TO 0.0.
}.
LOG "Waiting for " + BURNLONGITUDE + " degree longitude..." to orbitertwolog.txt.
PRINT "Waiting for " + BURNLONGITUDE + " degree longitude...".
LOCK THROTTLE TO 0.0.
LOCK MYSTEER TO RETROGRADE.
SET LONG1 TO SHIP:GEOPOSITION:LNG.
WAIT 1.
SET LONG2 TO SHIP:GEOPOSITION:LNG.
SET LONGITUDESTOFLY TO 10.
IF (BURNLONGITUDE < 0)
{
// 180 + -172 = 
	SET LONGITUDESTOFLY TO 0 - (SHIP:GEOPOSITION:LNG + BURNLONGITUDE).
}.
SET LONGSPEED TO LONG2-LONG1.
SET TIMETOFLY TO (LONGITUDESTOFLY/LONGSPEED)/60.
PRINT "It will take approximately " + TIMETOFLY + " minutes to reach the burn point.".
WAIT 10.
//SET WARP TO 3.
WAIT UNTIL SHIP:GEOPOSITION:LNG < BURNLONGITUDE.
LOCK THROTTLE TO 0.0.
LOCK MYSTEER TO RETROGRADE.
PRINT "LESS THAN.".
WAIT UNTIL SHIP:GEOPOSITION:LNG > BURNLONGITUDE-0.1.
PRINT "More than.".
//SET WARP TO 0.
LOCK THROTTLE TO 0.0.
LOCK MYSTEER TO RETROGRADE.
LOG "At correct longitude. Deorbiting." to orbitertwolog.txt.
PRINT "Waiting 5 seconds to align.".
WAIT 5.
PRINT "Deorbiting...".
LOCK THROTTLE TO 0.1.
WAIT UNTIL PERIAPSIS < 100.
LOCK THROTTLE TO 0.0.
LOG "Deorbited." to orbitertwolog.txt.
PRINT "Done. Rotating and waiting for arriving to KSC. Lets burn.".
LOCK MYSTEER TO PROGRADE.
WAIT 60.
RCS OFF.
//SET WARP TO 1.
WAIT UNTIL SHIP:ALTITUDE < 50000.
LOG "Below 50km." to orbitertwolog.txt.
PRINT "Below 50km.".
//SET WARP TO 0.
PRINT "WAITING FOR KSC OVERFLY.".
//PRINT SHIP:GEOPOSITION:LAT.
WAIT UNTIL SHIP:GEOPOSITION:LNG > STARTINGLONGITUDE - 0.001.
PRINT "KSC Overfly.".
WAIT UNTIL SHIP:AIRSPEED < 1000.
LOG "Below 1000m/s." to orbitertwolog.txt.
PRINT "Airspeed < 1000.".
STAGE.
STAGE.
BRAKES ON.
RCS ON.
//SET WARP TO 0.
PRINT "Rotate. Control burn.".
LOCK THROTTLE TO 0.01.
LOCK MYSTEER TO RETROGRADE.
WAIT 2.
LOG "In control." to orbitertwolog.txt.
LOCK THROTTLE TO 0.0.
//PRINT "Turning PROGRADE.".
//LOCK MYSTEER TO PROGRADE.
//PRINT "WAITING TIL ALTITUDE < 4km".
//WAIT UNTIL ALTITUDE < 4000.

} ELSE {
	// Lander test.
	LOCK STEERING TO HEADING(45,80).
	WAIT UNTIL ALTITUDE > 7000.

	}.
//PRINT "KSC Overfly. Stop horizontal movement.".
//LOCK STEERING TO (-1) * SHIP:VELOCITY:SURFACE.
//WAIT 2.
//LOCK THROTTLE TO 1.0.
//WAIT UNTIL SHIP:GROUNDSPEED < -100.0.
LOCK THROTTLE TO 0.0.

//LOCK STEERING TO HEADING(90,90).
//WAIT UNTIL alt:radar < 2500.
//WAIT UNTIL SHIP:VERTICALSPEED < -5.
//PRINT "AGL 1500. Burning...".
//LOCK STEERING TO (-1) * SHIP:VELOCITY:SURFACE.
//WAIT 2.
//LOCK THROTTLE TO 1.0.
//WAIT UNTIL SHIP:VERTICALSPEED > -50.
//LOCK THROTTLE TO 0.0.
//PRINT "Vertical speed > -50".

//LOCK STEERING TO HEADING(90,90).
//PRINT "Waiting to < 10000m".
//WAIT UNTIL altitude < 10000.

PRINT "Trying to aim for KSC.".

//PRINT "COARSE BURN...".
LOCK STEERING TO HEADING(STARTINGPOS:HEADING,5).
//WAIT 10.
SET COARESBURNED TO TRUE.
BRAKES ON.
until COARESBURNED {
IF (SHIP:VERTICALSPEED < 0) {
SET Vterminal TO 173.
SET TimeAcc TO (Vterminal - -SHIP:VERTICALSPEED)/9.81.
SET DistanceAcc TO (-SHIP:VERTICALSPEED * TimeAcc)/(0.5*9.81*TimeAcc*TimeAcc).
 //TimeToImpact TO SQRT(altitude/-SHIP:VERTICALSPEED).
//IF (DistanceAcc < altitude) {
	SET TimeToImpact TO TimeAcc+((altitude-DistanceAcc)/Vterminal).
//} else {
//}.

//PRINT "FALLTIME: " + TimeToImpact.

	// Calculating geographical distance.
	SET KSCDISTGEO TO SQRT(((STARTINGPOS:LNG-SHIP:GEOPOSITION:LNG)*(STARTINGPOS:LNG-SHIP:GEOPOSITION:LNG))+((STARTINGPOS:LAT-SHIP:GEOPOSITION:LAT)*(STARTINGPOS:LAT-SHIP:GEOPOSITION:LAT))).
	// Calculate it to meters.
	SET KSCDIST TO (KSCDISTGEO/180)*300000.
	PRINT "KCSDIST: " + KSCDIST.

LOCK STEERING TO HEADING(STARTINGPOS:HEADING,5).
LOCK THROTTLE TO 1.0.
//PRINT "GROUNDSPEED: " + SHIP:GROUNDSPEED.
//PRINT "TIME TO KSC: " + KSCDIST/(SHIP:GROUNDSPEED).
	LOCK THROTTLE TO 0.0.
	SET COARESBURNED TO TRUE.
IF (KSCDIST/(SHIP:GROUNDSPEED * 0.9) > TimeToImpact)
{
	LOCK THROTTLE TO 0.0.
	SET COARESBURNED TO TRUE.
}. 
}.
}.

//PRINT "COARSE BURNED. WAITING TO 15 SECONDS TO IMPACT...".
//WAIT UNTIL (altitude/-SHIP:VERTICALSPEED < 15). 


// Steer toward base.


	set bodyRadius to 60000.
if body = "Kerbin" { set bodyRadius to 60000. }.
if body = "Mun" { set bodyRadius to 20000. }.

//print "THIS IS A CRUDE DEMO LOOPING FOREVER.".
//print "    alt-1 to lock to surface prograde. ".
//print "    alt-2 to lock to surface retrograde. ".
//print "    alt-3 to quit. ".
//print " ".
set mySteer to up.
sas off.
lock steering to mySteer.
set direct to "retro".
set done to false.

set sdPTime to missiontime.
set sdPLon to longitude.
set sdPLat to latitude.
set sdPAtl to altitude.
set sdDegToRad to 3.1415927 / 180.
set LASTTHROTTLE to 0.
set sdPVS to verticalspeed.
set sdPLatError to (latitude-STARTINGLATITUDE).
set sdPLonError to (longitude-STARTINGLONGITUDE).
set sdPLonV to 0.
set sdPLatV to 0.
wait 1.
SET ERROROUTPUTTED TO FALSE.
until done {
	wait 0.1.
  on AG1 set direct to "pro".
  on AG2 set direct to "retro".
  on AG3 done on.

  set sdTime to missiontime.
set sdLon to longitude.
set sdLat to latitude.
set sdVS to verticalspeed.
set sdSS to groundspeed.
set sdAlt to altitude.
set TimeToImpact TO (alt:radar/-SHIP:VERTICALSPEED).
set LonError to (longitude-STARTINGLONGITUDE).
set LatError to (latitude-STARTINGLATITUDE).
set sdLonV to (sdLat-sdPLat) / (sdTime-sdPTime).
set sdLatV to (sdLon-sdPLon) / (sdTime-sdPTime).
set sdLonAcc to sdLonV-sdPLonV.
set sdLatAcc to sdLatV-sdPLatV.
set sdPLonV to sdLonV.
set sdPLatV to sdLatV.
set surfRelSpeed to ( sdSS^2 + sdVS^2 ) ^ 0.5 .
// (10-20)/5.0
set LonCorrection to LonError+((sdPLonError-LonError)/(0.1/5.0)).
set LatCorrection to LatError+((sdPLatError-LatError)/(0.1/5.0)).
set sdPLatError to (latitude-STARTINGLATITUDE).
set sdPLonError to (longitude-STARTINGLONGITUDE).
// Limit lon and lat error
//IF (LonError > 0.5) { SET LonError TO 0.5.}.
//IF (LonError < -0.5) { SET LonError TO -0.5.}.
//IF (LatError > 0.5) { SET LatError TO 0.5.}.
//IF (LatError < -0.5) { SET LatError TO -0.5.}.
//SET LonError TO 0.
//SET LatError TO 0.
SET FALLTIME TO alt:radar/SQRT(9.81).
SET FALLTIME TO 70.
SET Vterminal TO 173.
SET TimeAcc TO (Vterminal - -SHIP:VERTICALSPEED)/9.81.
SET DistanceAcc TO (-SHIP:VERTICALSPEED * TimeAcc)/(0.5*9.81*TimeAcc*TimeAcc).
 //TimeToImpact TO SQRT(altitude/-SHIP:VERTICALSPEED).
//IF (DistanceAcc < altitude) {
	SET FALLTIME TO TimeAcc+((altitude-DistanceAcc)/Vterminal).
	SET FALLTIMEHORADJ TO 1.5.
//} else {
//}.

//PRINT "FALLTIME: " + TimeToImpact.
//PRINT "FALLTIME: " + FALLTIME.
SET KSCDIST TO SQRT((LatError*LatError)+(LonError*LonError)) * (bodyRadius+sdAlt)*sdDegToRad.
//PRINT "KSCDIST: " + KSCDIST.
IF (KSCDIST > 4000) {
	PRINT "ABORT RETURN!".
	SET LonError TO 0.
	SET LatError TO 0.
	SET KSCDIST TO 0.
}.
IF (FALLTIME < 15)
{
	GEAR ON.
	GEAR ON.
}.
set surfRelNorth to ( (bodyRadius+sdAlt)*sdDegToRad*(LatError + ((sdLat-sdPLat)*FALLTIME*FALLTIMEHORADJ)) + (sdLatAcc*1)) / (sdTime-sdPTime).
set surfRelEast to ( (bodyRadius+sdAlt)*sdDegToRad*(LonError + ((sdLon-sdPLon)*FALLTIME*FALLTIMEHORADJ)+ (sdLonAcc*1)) * cos(sdLat) ) / (sdTime-sdPTime).
SET ErrorDist TO SQRT(((LatError + ((sdLat-sdPLat)*FALLTIME*FALLTIMEHORADJ))*(LatError + ((sdLat-sdPLat)*FALLTIME*FALLTIMEHORADJ)))+((LonError + ((sdLon-sdPLon)*FALLTIME)+ (sdLonAcc*1))*(LonError + ((sdLon-sdPLon)*FALLTIME)+ (sdLonAcc*1)))) * (bodyRadius+sdAlt)*sdDegToRad.
IF (ERROROUTPUTTED = FALSE)
{
	PRINT "ERROR DIST: " + ErrorDist.
	SET ERROROUTPUTTED TO TRUE.
}.
SET OLDTIPPINGRESTRICTION TO TIPPINGRESTRICTION.
set surfRelUp to sdVS.
set surfRelUp to sdVS.
set surfRelUp to -80.


	SET surfRelUp TO -45.
		SET TIPPINGRESTRICTION TO 30.
		IF altitude < 1500 {
		SET surfRelUp TO -80.
		SET TIPPINGRESTRICTION TO 10.
}.
IF surfRelEast > TIPPINGRESTRICTION { SET surfRelEast TO TIPPINGRESTRICTION.}.
IF surfRelEast < -TIPPINGRESTRICTION { SET surfRelEast To -TIPPINGRESTRICTION.}.
if surfRelNorth > TIPPINGRESTRICTION { SET surfRelNorth TO TIPPINGRESTRICTION.}.
if surfRelNorth < -TIPPINGRESTRICTION { SET surfRelNorth TO -TIPPINGRESTRICTION.}.
SET TIPPINGRESTRICTION TO OLDTIPPINGRESTRICTION.

//IF (surfRelUp>-0.1) {SET surfRelUp to -0.1.}.


//IF (surfRelUp>-0.1) {SET surfRelUp to -0.1.}.

set surfPrograde to up * V( 0 - surfRelEast, surfRelNorth, surfRelUp ).
set surfRetrograde to up * V( surfRelEast, 0-surfRelNorth, 0-surfRelUp ).

set sdPLat to sdLat.
set sdPLon to sdLon.
set sdPTime to sdTime.
set sdPAlt to sdAlt.
set vAcc to (sdPVS-verticalspeed)/0.1.
//PRINT "vAcc: " + vAcc.
set sdPVS to verticalspeed.
  if direct = "pro" {
    set mySteer to surfPrograde.
  }.
  if direct = "retro" {
    set mySteer to surfRetrograde.
  }.
  //LOCK THROTTLE TO (-SHIP:VERTICALSPEED/alt:radar)*1.0.
//  IF (alt:radar > 800) {	
//	SET ALTERROR TO (580)-(alt:radar-8).
 //} else {
	SET ALTERROR TO (KSCDIST*1.2)-(alt:radar-9.813).
// }.
  //PRINT "CURRENT ALT: " + alt:radar.
  //PRINT "TARGET ALT: " + (KSCDIST*1.2).
  //PRINT "ALTERROR: " + ALTERROR.
  SET GROUNDSPEED TO SQRT((sdLonV*sdLonV)+(sdLatV*sdLatV)) * (bodyRadius+sdAlt)*sdDegToRad.
  //SET APPROACHTIME TO KSCDIST/GROUNDSPEED.
//	PRINT "APPROACH TIME: " + APPROACHTIME.
// TWR about 1.5 so 9.8*0.5 amount of acc available + lag (4.9m/s2)
// NO! TWR about 2.0 and we want to be stable at about 100m so 100/(9.8*2) = 5.1
SET ALTDIV TO 6.
SET THROTTLECHANGE TO ((1/ALTDIV)*0.1)*2.
  	SET TARGETVS TO (ALTERROR/ALTDIV).
	//IF ((KSCDIST*2.0)>alt:radar) SET TARGETVSL TO 10.
	//PRINT "TARGETVS: " + TARGETVS.
	//IF (TARGETVS < -150) { SET TARGETVS TO -150. }.
	//IF (TARGETVS > 150) { SET TARGETVS TO 150.}.
	IF (KSCDIST < 1.0) {IF (TARGETVS > -8.0) {IF (GROUNDSPEED < 1.0) { SET TARGETVS TO -8.0.}.}.} ELSE {
			IF (SHIP:VERTICALSPEED < 0){
		IF (ErrorDist > altitude * 0.005) {
		IF (surfRelEast > TIPPINGRESTRICTION-1) { LOCK THROTTLE TO LASTTHROTTLE+0.5.}.
		IF (surfRelEast < -TIPPINGRESTRICTION+1) { LOCK THROTTLE TO LASTTHROTTLE+0.5.}.
		IF (surfRelNorth > TIPPINGRESTRICTION-1) { LOCK THROTTLE TO LASTTHROTTLE+0.5.}.
		IF (surfRelNorth < -TIPPINGRESTRICTION+1) { LOCK THROTTLE TO LASTTHROTTLE+0.5.}.
		SET LASTTHROTTLE TO (LASTTHROTTLE + THROTTLECHANGE + 0.01).
		}.
		}.
	}.
		IF SHIP:VERTICALSPEED < (TARGETVS+vAcc) {  SET LASTTHROTTLE TO (LASTTHROTTLE + THROTTLECHANGE). } ELSE { SET LASTTHROTTLE TO (LASTTHROTTLE - THROTTLECHANGE).  }.
		IF (LASTTHROTTLE < 0) { SET LASTTHROTTLE TO 0.}.
		IF (LASTTHROTTLE > 1) { SET LASTTHROTTLE TO 1.}.
		//if (alt:radar < 1000) {
		//
		//} else {
	//	IF LASTTHROTTLE < 0.01 { SET LASTTHROTTLE TO 0.01.}.
		//}.
		LOCK THROTTLE TO LASTTHROTTLE.

		
//IF altitude > 4000 {
//	IF altitude < 6000 {
//		LOCK THROTTLE TO SQRT((surfRelEast*surfRelEast)+(surfRelNorth*surfRelNorth)) / 90.
//	}.
//}.
  //print "East,North,Up = ( " + surfRelEast + ", " + surfRelNorth + ", " + surfRelUp + ")".
}.
unlock steering.
	


UNTIL alt:radar < 100 {
	SET FIRSTLONG TO SHIP:GEOPOSITION:LNG.
	SET FIRSTLAT TO SHIP:GEOPOSITION:LAT.
	// Calculate horizontal distance
	
	SET FIRSTDISTGEO TO SQRT(((STARTINGPOS:LNG-SHIP:GEOPOSITION:LNG)*(STARTINGPOS:LNG-SHIP:GEOPOSITION:LNG))+((STARTINGPOS:LAT-SHIP:GEOPOSITION:LAT)*(STARTINGPOS:LAT-SHIP:GEOPOSITION:LAT))).
	SET FIRSTDIST TO (FIRSTDISTGEO/180)*300000.
	WAIT 0.1.
	SET SECONDLONG TO SHIP:GEOPOSITION:LNG.
	SET SECONDLAT TO SHIP:GEOPOSITION:LAT.
	// Calculating geographical distance.
	SET KSCDISTGEO TO SQRT(((STARTINGPOS:LNG-SHIP:GEOPOSITION:LNG)*(STARTINGPOS:LNG-SHIP:GEOPOSITION:LNG))+((STARTINGPOS:LAT-SHIP:GEOPOSITION:LAT)*(STARTINGPOS:LAT-SHIP:GEOPOSITION:LAT))).
	// Calculate it to meters.
	SET KSCDIST TO (KSCDISTGEO/180)*300000.
	PRINT "KCSDIST: " + KSCDIS.
	// 80 75 => 5, (75+5)-DIST > 0 => Overshoot
	SET CLOSINGSPEED TO (FIRSTDIST-KSCDIST)/0.1.
	// -80 -78 -74 (((-78-(-80--78)/0.1))-74)
	SET TIMETOSIXH TO ((alt:radar-300)/-SHIP:VERTICALSPEED).
	IF (SHIP:VERTICALSPEED > -1) SET TIMETOSIXH TO 1.
	PRINT "TIME TO 600: " + TIMETOSIXH.
	SET LONGERROR TO (((SECONDLONG-((SECONDLONG-FIRSTLONG))/(0.1))) - STARTINGLONGITUDE).
	SET LATERROR TO (((SECONDLAT-((SECONDLAT-FIRSTLAT))/(0.1))) - STARTINGLATITUDE).
	PRINT "LONGERROR " + LONGERROR.
	PRINT "LATERROR " + LATERROR.
	SET TARGETVS TO -100.
	SET TARGETVS TO ((-((alt:radar-100) / 2))-40).
	PRINT "TARGET VS: " + TARGETVS.
	
	IF (SHIP:VERTICALSPEED < TARGETVS) {
				LOCK THROTTLE TO 1.0.
				//LOCK STEERING TO ((-1) * SHIP:VELOCITY:SURFACE) + V(-LONGERROR * 100,-LATERROR * 100,0).
				LOCK STEERING TO HEADING(90,90).
			} ELSE {
		IF SHIP:VERTICALSPEED < 5
		{
			SET REMAININGFUEL TO SHIP:MASS - SHIP:DRYMASS.
			PRINT "REMAININGFUEL: " + REMAININGFUEL.
			IF (REMAININGFUEL > 2)
			{
				//LOCK THROTTLE TO (0.1 * (LONGERROR + LATERROR)).
				
				//LOCK THROTTLE TO (0.1 * SHIP:GROUNDSPEED).
				//(-SHIP:VERTICALSPEED/50).
				//LOCK THROTTLE TO 0.0.
				IF (KSCDIST > 1) {
					PRINT "DISTANCE: " + KSCDIST.
					PRINT "CLOSINGSPEED: " + CLOSINGSPEED.
					PRINT "ERROR: " + (KSCDIST - (CLOSINGSPEED)).
					SET ONTARGET TO TRUE.
					IF ((KSCDIST - (CLOSINGSPEED*(TIMETOSIXH/2))) > 1) { SET ONTARGET TO FALSE. }.
					IF ((KSCDIST - (CLOSINGSPEED*(TIMETOSIXH/2))) < -1) { SET ONTARGET TO FALSE. }.
					IF (ONTARGET ) {
						// Not likely :)
						PRINT "ON TARGET!!!!!11! <<< -----".
						LOCK THROTTLE TO 0.0.
						} ELSE {
					IF ((KSCDIST - (CLOSINGSPEED*((TIMETOSIXH+5)/2))) < 0) {
						// Overshooting
						PRINT "OVERSHOOTING!!!!!!!!!!!!!!!!!!!!!!".
						IF (SHIP:VERTICALSPEED < -10) {
							LOCK STEERING TO ((-1) * SHIP:VELOCITY:SURFACE).
							LOCK THROTTLE TO 0.35.
						} ELSE {
							LOCK STEERING TO HEADING(STARTINGPOS:HEADING,110).
							LOCK THROTTLE TO 0.01.
						}.
						} ELSE {
						
							// Steer toward base.
							//PRINT "STEERING TOWARDS BASE".
							SET TRAJERROR TO (KSCDIST - (CLOSINGSPEED*((TIMETOSIXH+5)/2))).
							//PRINT "CLOSINGSPEED: " + CLOSINGSPEED.
							//PRINT "TRAJERROR: " + TRAJERROR.
							SET CORRECTION TO (90 - (TRAJERROR/5)).
							IF (CORRECTION < 20) { SET CORRECTION TO 20. }.
							IF (CORRECTION > 160) { SET CORRECTION TO 160. }.
							//PRINT "Correction: " + CORRECTION.
							
							SET TARGETSPEED TO 100.
							IF (alt:radar < 600) { 
								SET TARGETSPEED TO 50.0.
								LOCK STEERING TO ((-1) * SHIP:VELOCITY:SURFACE).
							} ELSE {
								LOCK STEERING TO HEADING(STARTINGPOS:HEADING,CORRECTION).
								}.
							LOCK THROTTLE TO (-SHIP:VERTICALSPEED/TARGETSPEED)*0.3.
							}.
						//} ELSE {
							//LOCK STEERING TO HEADING(STARTINGPOS:HEADING,90).
						//	LOCK THROTTLE TO 0.0.
						//}.
							}.
				} ELSE {
					
				IF (SHIP:VERTICALSPEED < -50) {
					//IF (SHIP:GROUNDSPEED > KSCDIST) {
						// Trajectory correction
						PRINT "NO FUEL. BRAKING.".
						//LOCK STEERING TO ((-1) * SHIP:VELOCITY:SURFACE) + V(-LONGERROR * 100,-LATERROR * 100,0).
						//LOCK STEERING TO ((-1) * SHIP:VELOCITY:SURFACE) + HEADING(STARTINGPOS:HEADING,89).
						//LOCK STEERING TO ((-1) * SHIP:VELOCITY:SURFACE).
					//	PRINT "PITCH: " + FACING:PITCH.
					//	PRINT "YAW: " + FACING:YAW.
						//LOCK STEERING TO R(90+(LONGERROR * 1000),90+(LATERROR * 1000),0).
						//LOCK STEERING TO HEADING(STARTINGPOS:HEADING,85).
						///LOCK THROTTLE TO 0.35.
						UNTIL SHIP:GROUNDSPEED < 1 {
							IF SHIP:VERTICALSPEED < -10 {
								LOCK THROTTLE TO (0.1 * SHIP:GROUNDSPEED).
							} ELSE { LOCK THROTTLE TO 0.0.}.
								WAIT 0.01.
						}
						
						PRINT "HORIZONTAL VELOCITY KILLED.".
					} ELSE {
						// Hover mode.
						PRINT "NO FUEL. FALLING.".
					//	LOCK STEERING TO R(90+(LONGERROR * 1000),90+(LATERROR * 1000),0).
							LOCK STEERING TO HEADING(STARTINGPOS:HEADING,90.0).
						//LOCK STEERING TO ((-1) * SHIP:VELOCITY:SURFACE).
						LOCK THROTTLE TO 0.0.
					}.
				}.
			}.
		} ELSE { 
			//LOCK STEERING TO ((-1) * SHIP:VELOCITY:SURFACE) + V(-LONGERROR * 100,-LATERROR * 100,0).
			IF SHIP:VERTICALSPEED > 0
				{		
					LOCK THROTTLE TO 0.0.
				}.
				IF (SHIP:VERTICALSPEED > -1) {	LOCK STEERING TO HEADING(90,90).}.
			}.
		}.
}.
//PRINT "Waiting to AGL < 600m".
WAIT UNTIL alt:radar < 600.
PRINT "600 m AGL. Beginning controlled descend.".
//SAS ON.
//SET SASMODE TO "RETROGRADE".
LOCK MYSTEER TO HEADING(90,90).
WAIT UNTIL SHIP:VERTICALSPEED < -5.
SET LASTTHROTTLE TO 0.0.
LOCK STEERING TO (-1) * SHIP:VELOCITY:SURFACE.
UNTIL alt:radar < 1 {
	IF (alt:radar > 5000) {
		IF (SHIP:GROUNDSPEED > 1) {
			
				IF SHIP:VERTICALSPEED < -20
				{
				//LOCK STEERING TO RETROGRADE.
				//SET SASMODE TO "RETROGRADE".
				LOCK STEERING TO (-1) * SHIP:VELOCITY:SURFACE.
				WAIT 0.1.

				// PHASE 2: Kill our horizontal velocity (surface speed)
	
				PRINT "KILLING HORIZONTAL VELOCITY".
				UNTIL SHIP:GROUNDSPEED < 1 {
						IF SHIP:VERTICALSPEED < -10 {
							LOCK THROTTLE TO (0.1 * SHIP:GROUNDSPEED).
							} ELSE { LOCK THROTTLE TO 0.0.}.
						WAIT 0.01.
					}
				}.
				PRINT "HORIZONTAL VELOCITY KILLED.".
			
		}.
//		LOCK STEERING TO HEADING(90,90).
//		SAS OFF.
		LOCK THROTTLE TO 0.0.
	} ELSE IF (alt:radar > 2000) {
	// Final correction
	// Steer toward base.
	PRINT "FINAL CORRECTION.".
	SET TIMETOFIFTY TO ((alt:radar)/-SHIP:VERTICALSPEED).
							PRINT "STEERING TOWARDS BASE".
							SET TRAJERROR TO (KSCDIST - (CLOSINGSPEED*((TIMETOFIFTY-5)/2))).
							PRINT "CLOSINGSPEED: " + CLOSINGSPEED.
							PRINT "TRAJERROR: " + TRAJERROR.
							SET CORRECTION TO (90 - (TRAJERROR/5)).
							IF (CORRECTION < 45) { SET CORRECTION TO 45. }.
							IF (CORRECTION > 135) { SET CORRECTION TO 135. }.
							PRINT "Correction: " + CORRECTION.
							LOCK STEERING TO HEADING(STARTINGPOS:HEADING,CORRECTION).
							LOCK THROTTLE TO (-SHIP:VERTICALSPEED/40)*0.3.
	} ELSE {
		SAS OFF.
		SET TARGETVS TO -0.1.
		IF (SHIP:GROUNDSPEED > 1) {
			PRINT "KILLING GROUND SPEED.".
			UNTIL (alt:radar < 70) {
			IF SHIP:VERTICALSPEED < -5 {
				LOCK STEERING TO (-1) * SHIP:VELOCITY:SURFACE.
				LOCK THROTTLE TO (0.1 * SHIP:GROUNDSPEED).
			} ELSE {
				LOCK STEERING TO HEADING(90,90).			
				LOCK THROTTLE TO 0.0.
				}.
			WAIT 0.01.
			}
			UNTIL SHIP:VERTICALSPEED < 0 {
				LOCK STEERING TO HEADING(90,90).			
				LOCK THROTTLE TO 0.0.
			}.
			PRINT "HORIZONTAL VELOCITY KILLED.".
		}.
		IF (alt:radar > 5)  {SET TARGETVS TO (-((alt:radar) / 2)).}.
		IF SHIP:VERTICALSPEED < TARGETVS {  SET LASTTHROTTLE TO (LASTTHROTTLE + 0.01). } ELSE { SET LASTTHROTTLE TO (LASTTHROTTLE - 0.01).  }.
		IF (LASTTHROTTLE < 0) { SET LASTTHROTTLE TO 0.}.
		IF (LASTTHROTTLE > 1) { SET LASTTHROTTLE TO 1.}.
		if (alt:radar < 50) {LOCK STEERING TO HEADING(STARTINGPOS:HEADING,90.0).	} ELSE IF (SHIP:VERTICALSPEED > 0) {LOCK STEERING TO HEADING(90,90).} ELSE {LOCK STEERING TO (-1) * SHIP:VELOCITY:SURFACE.}.
		//LOCK STEERING TO HEADING(90,90).
		LOCK THROTTLE TO LASTTHROTTLE.
		
		
	}.
}.
LOCK THROTTLE TO 0.0.