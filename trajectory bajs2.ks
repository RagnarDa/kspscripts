    // The density of air in kilograms per cubic meter
    // at a pressure of 1 atmosphere:
    set atmToDens to 1.2230948554874 .

    // 'e', as in the natural log base:
    set e to constant():e.

    // The typical drag coefficient in SQUAD's formula for most parts except parachutes:
    // If you assume your ship is made of typical parts and you aren't trying to launch with
    // parachutes active, this will also be the average across your whole ship then:
    set drag to 0.2.

    // m/s^2 gravitational acceleration here (i.e. 9.802 for earth at sea level).
    lock heregrav to BODY:MU / ( (SHIP:BODY:RADIUS+SHIP:ALTITUDE)^2 ).
	PRINT "Gravity here: " + heregrav.
    // You can lock this to surface vel, or oribital vel.
    // Depending on how high up you are you might want to switch it:
    lock useVel to ship:velocity:surface.

    print "Current Pressure is" + SHIP:SENSORS:PRES.
	// Pressure at KSC is 100.13
	
    // air density here:
    lock dense to ship:sensors:pres * atmToDens.

    // Force of drag from air pressure here:
    lock fdrag to 0.5*( dense )*(usevel:mag)^2*drag*0.008*SHIP:MASS.
	PRINT "Mass: " + SHIP:MASS.
	
    // Terminal velocity here:
    set Vterminal to ( (250*heregrav)/( dense * drag ) ) ^ 0.5 . // divZero?
	PRINT "Vterm: " + Vterminal.

	
PRINT "TEST: " + (VANG(NORTH:VECTOR, SHIP:PROGRADE:VECTOR)).
PRINT "TEST2: " + (90-VANG(NORTH:VECTOR, SHIP:PROGRADE:VECTOR)).
PRINT "TEST3: " + (360-(360+VANG(NORTH:VECTOR, SHIP:PROGRADE:VECTOR)-270)).


set sdPLon to longitude.
set sdPLat to latitude.
set sdAlt to altitude.
set sdDegToRad to 3.1415927 / 180.
set sdPLonV to 0.
set sdPLatV to 0.
set sdPTime to missiontime.
wait 0.1.
set sdTime to missiontime.
set sdLon to longitude.
set sdLat to latitude.
set sdVS to verticalspeed.
set sdSS to groundspeed.
set sdAlt to altitude.
set sdLatV to (sdLat-sdPLat) / (sdTime-sdPTime).
set sdLonV to (sdLon-sdPLon) / (sdTime-sdPTime).
set bodyRadius to 300000.
SET GROUNDV TO SQRT((sdLonV*sdLonV)+(sdLatV*sdLatV)) * (bodyRadius+sdAlt)*sdDegToRad.
PRINT "GROUNDV: " + GROUNDV.
SET GROUNDDIR TO ARCTAN2(sdLatV,sdLonV).
PRINT "GROUNDDIR: " + (GROUNDDIR).


	
SET sensorheight TO 90.
SET altitudebelow TO altitude - sensorheight.
// Vterminal expermentally determined (at 0 fuel): 281@10km 267@7km 244@5km 226.3@4km 202.7@3km 180@2km 155@1km
// so current v is about =(((281-155)/9000)*ALTITUDE)+155 and ~130m/s at surface
SET CurrentVterm TO (((281-130)/10000)*altitude)+130.
PRINT "CurrentVterm: " + CurrentVterm.
SET VterminalAtSurface TO 130.//173. // Flight Engineer says 115.6
PRINT "VTerm at surface: " + VterminalAtSurface.
SET Vterminal TO (CurrentVTerm+VterminalAtSurface)/2. // Get average of current v and final v.
PRINT "VTerm average: " + Vterminal.
SET AverageGravity TO (9.81+heregrav)/2.

  print "Current Pressure is" + SHIP:SENSORS:PRES.
	// Pressure at KSC is 100.13
	
    // air density here:
    lock dense to ship:sensors:pres * atmToDens.
PRINT "CURRENT DENSITY: " + dense.
SET AverageDensity TO ((dense + 1.2230948554874)/2).
PRINT "Average density: " + AverageDensity.

//* Calculate ascent phase *

// The ship weighs empty 15310kg so at V=130 the Cd-force is 15310N, therefore 15310=0.5*1.2230948554874*Cd*130*130
// and therefore unstandardized Cd is about 1.4813522528
SET VerticalAeroDrag TO 0.5*1.2230948554874*1.4813522528*SHIP:VERTICALSPEED*SHIP:VERTICALSPEED.
// SHIP:MASS returns tons?
SET AerodynamicDeceleration TO (SHIP:MASS*1000)/(VerticalAeroDrag * 0.5).
PRINT "VerticalAeroDrag: " + VerticalAeroDrag.
PRINT "Aerodynamc Deceleration: " + AerodynamicDeceleration.

SET TimeToDecelerate TO (SHIP:VERTICALSPEED/heregrav) * AerodynamicDeceleration.
SET DistanceDecc TO SHIP:VERTICALSPEED*(TimeToDecelerate*0.5).// ((0.5*(heregrav + AerodynamicDeceleration))*(TimeToDecelerate*TimeToDecelerate)).
if (SHIP:VERTICALSPEED < 0) {
	SET TimeToDecelerate TO 0.
	SET DistanceDecc TO 0.
}.
IF (SHIP:VERTICALSPEED = 0) {
	SET TimeToDecelerate TO 0.
	SET DistanceDecc TO 0.
}.
PRINT "ASCENT TIME: " + TimeToDecelerate.
PRINT "ASCENT DISTANCE: " + DistanceDecc.
PRINT "APOAPSIS: " + (altitude + DistanceDecc).


	
// * Calculate descent phase *


SET DownSpeed TO  -SHIP:VERTICALSPEED.
IF (DownSpeed < 0) {SET DownSpeed TO 1/100.}. // Make sure no positive values.
IF (DownSpeed = 0) {SET DownSpeed TO 1/100.}. // Make sure no positive values.

SET sensorheight TO 90.
SET altitudebelow TO (altitude - sensorheight) + DistanceDecc.
SET TimeAcc TO (Vterminal - DownSpeed)/AverageGravity.
SET DistanceAcc TO (DownSpeed * TimeAcc)+((0.5*AverageGravity)*(TimeAcc*TimeAcc)).
//SET TimeToImpact TO SQRT(altitudebelow/DownSpeed).
SET TimeDescending TO 0.
IF TRUE { // DistanceAcc < altitudebelow {
	PRINT "Does reach Vterm".
	SET TimeDescending TO TimeAcc+(((altitudebelow)-DistanceAcc)/Vterminal).
} ELSE {
	// Doesnt reach full terminal v.
	// THIS CODE DOESNT WORK.
	PRINT "Doesnt reach Vterm".
	SET TimeAcc TO (altitudebelow/DistanceAcc)*TimeAcc.
	SET DistanceAcc TO (DownSpeed * TimeAcc)+((0.5*AverageGravity)*(TimeAcc*TimeAcc)).
	SET ImpactSpeed TO (DownSpeed) + (AverageGravity * TimeAcc).
	PRINT "Impact speed: " + ImpactSpeed.
	SET TimeDescending TO TimeAcc.
}.
						
PRINT "Alt below: " + altitudebelow.
PRINT "TimeAcc: " + TimeAcc.
PRINT "DistanceAcc: " + DistanceAcc.
PRINT "FALLTIME: " + TimeDescending.
PRINT "ASCENT TIME: " + TimeToDecelerate.
SET TimeToImpact TO TimeDescending + TimeToDecelerate.
PRINT "Time to impact: " + TimeToImpact.


// * Calculate horizontal movement *

SET HorizontalSpeed TO SQRT((SHIP:AIRSPEED*SHIP:AIRSPEED)-(SHIP:VERTICALSPEED*SHIP:VERTICALSPEED)).
PRINT "Ground speed: " + SHIP:GROUNDSPEED.
PRINT "Horizontal speed: " + HorizontalSpeed.
SET HorVT TO SQRT( (2 * SHIP:MASS* 1000 * AverageGravity) / (atmToDens*(1.4813522528*7*3.75)) ).
SET XDist TO (HorVT^2 / AverageGravity) * LN( (HorVT^2 + AverageGravity * SHIP:GROUNDSPEED * TimeToImpact) / HorVT^2 ). //LN(a)
PRINT "XDIST: " + XDist.
//SET XDistTwo TO (HorVT^2 / AverageGravity) * LN( (HorVT^2 + AverageGravity * HorizontalSpeed * TimeToImpact) / HorVT^2 ). 
PRINT "XDist/2: " + (XDist/2).

SET STARTINGPOS TO SHIP:GEOPOSITION.
SET STARTINGLONGITUDE TO SHIP:GEOPOSITION:LNG.
SET STARTINGLATITUDE TO SHIP:GEOPOSITION:LAT.



//SET spot TO LATLNG(SHIP:GEOPOSITION:LAT+(sdLatV*TimeToImpact),SHIP:GEOPOSITION:LNG+(sdLonV*TimeToImpact)).
SET distratio TO (XDist/2)/GROUNDV.
SET spot TO LATLNG(SHIP:GEOPOSITION:LAT+(sdLatV*distratio),SHIP:GEOPOSITION:LNG+(sdLonV*distratio)).
PRINT "SPOT: " + spot.

SET VD TO VECDRAWARGS(
              spot:ALTITUDEPOSITION(spot:TERRAINHEIGHT+1000),
              spot:POSITION - spot:ALTITUDEPOSITION(spot:TERRAINHEIGHT+1000),
              red, "THIS IS THE SPOT", 1, true).

SET TIMETICK TO 0.
until (FALSE)
{
	WAIT 1.
	SET TIMETICK TO TIMETICK+1.
	SET TimeToImpact TO TimeToImpact - 1.
	PRINT "REMAINING FALLTIME: " + TimeToImpact AT (0,0).
	// Calculate traveled distance.
	SET KSCDISTGEO TO SQRT(((STARTINGPOS:LNG-SHIP:GEOPOSITION:LNG)*(STARTINGPOS:LNG-SHIP:GEOPOSITION:LNG))+((STARTINGPOS:LAT-SHIP:GEOPOSITION:LAT)*(STARTINGPOS:LAT-SHIP:GEOPOSITION:LAT))).
	// Calculate it to meters.
	SET KSCDIST TO (KSCDISTGEO/180)*constant():pi*300000.
	PRINT "TRAVELED DISTANCE: " + KSCDIST AT (0,1).
	// Calculate target distance.
	SET TARGETDISTGEO TO SQRT(((spot:LNG-SHIP:GEOPOSITION:LNG)*(spot:LNG-SHIP:GEOPOSITION:LNG))+((spot:LAT-SHIP:GEOPOSITION:LAT)*(spot:LAT-SHIP:GEOPOSITION:LAT))).
	// Calculate it to meters.
	SET TARGETDIST TO (TARGETDISTGEO/180)*constant():pi*300000.
	PRINT "IMPACT DISTANCE: " + TARGETDIST AT (0,2).
	
	//PRINT "AVERAGE HOR DECELERATION: " + ((HorizontalSpeed-SHIP:GROUNDSPEED)/TIMETICK) AT (0,22).
}.