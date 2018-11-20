CLEARSCREEN.
SET launchPad TO SHIP:GEOPOSITION.
set radarOffset to alt:radar.
RCS ON.
SAS OFF.
STAGE.
SET FALLTIME TO 20.1.
PRINT SHIP:MAXTHRUST AT (0,7).
PRINT SHIP:MASS AT (0,8).
lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)		
LOCK TWR TO ((SHIP:MAXTHRUST*1000)/((SHIP:MASS*1000)*g)).
PRINT "TWR: " + ((SHIP:MAXTHRUST*1000)/((SHIP:MASS*1000)*g)) AT (0,6).
SET Cd TO 0.011.
LOCK CALCHORV TO COS((ARCSIN(SHIP:VERTICALSPEED/SHIP:AIRSPEED)))*SHIP:AIRSPEED.
SET Uo TO CALCHORV.
	SET Density TO 1.225.
	PRINT "Density: " + Density AT (0,24).
	SET Vt TO SQRT((2*SHIP:MASS*g)/(Cd*Density)).
	PRINT "Vt: " + Vt AT (0,25).
	SET X TO ((Vt*Vt)/g)*(LN(((Vt*Vt)+g*Uo*FALLTIME)/(Vt*Vt))).

UNTIL APOAPSIS > 500 {
	LOCK THROTTLE TO 1.0.
	///TWR.
	//IF (ALT:RADAR > 10)
	//{
	//	LOCK THROTTLE TO (1.0/TWR) - SHIP:VERTICALSPEED.
	//}
	LOCK STEERING TO HEADING(90,80).
	SET Uo TO CALCHORV.
	SET Density TO 1.225.
	PRINT "Density: " + Density AT (0,24).
	SET Vt TO SQRT((2*SHIP:MASS*g)/(Cd*Density)).
	PRINT "Vt: " + Vt AT (0,25).
	SET X TO ((Vt*Vt)/g)*(LN(((Vt*Vt)+g*Uo*Vt)/(Vt*Vt))).
	PRINT "X: " + X AT (0,26).
}
LOCK STEERING TO HEADING(90,90).
LOCK THROTTLE TO 0.0.
WAIT 1.0.
SET DISTANCETOFALL TO (APOAPSIS-ALTITUDE)*2.
SET FALLTIME TO (SHIP:VERTICALSPEED/g)*2.
PRINT "EST FALLTIME: " + FALLTIME AT (0,1).
SET LASTTIME TO TIME:SECONDS.
SET LASTHV TO SHIP:GROUNDSPEED.
SET HORACC TO 0.
SET HASRUN TO 0.
SET DELTATTIME TO 1.
SET Uo TO CALCHORV.
SET Vo TO SHIP:VERTICALSPEED.
SET STARTTIME TO TIME:SECONDS.
SET STARTINGALT TO ALT:RADAR.
SET Go TO g.
SET Vt TO 1.
SET STARTINGSPOT to SHIP:GEOPOSITION.
SET Cd TO 0.01.
SET X TO 1.
SET LASTDIST TO 0.

SET AVGCOUNTER TO 0.
SET AVGCOEFF TO 0.

IF (true){
UNTIL (ALT:RADAR < STARTINGALT)
{
	// Measure horizontal (sideways) drag
	LOCK THROTTLE TO 0.0.
	RCS ON.

	SET DELTATIME TO TIME:SECONDS - LASTTIME.
	SET LASTTIME TO TIME:SECONDS.
	
	lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)		

	IF (HASRUN = 1)
	{
		
		SET LASTDIST TO STARTINGSPOT:DISTANCE.
		SET HORACC TO (CALCHORV - LASTHV)/DELTATIME.
		SET LASTHV TO CALCHORV.

	}.
	SET HASRUN TO 1.
	SET CALCQ TO (1.225 * 0.5 * CALCHORV * CALCHORV).
	PRINT "Q: " + (SHIP:Q) + " CALC Q: " + CALCQ AT (0,19).
	PRINT "HACC: " + HORACC AT (0,20).

	PRINT "SIDE ACCELERATION: " + (HORACC) AT (0,21).
	PRINT "DELTATIME: " + DELTATIME AT (0,22).
	SET SIDEFORCE TO (HORACC) * ship:mass.
	IF (TRUE)
	{
		PRINT "SIDE COEFF: " + ((SIDEFORCE) / CALCQ) AT (0,23).
		SET AVGCOEFF TO AVGCOEFF + (SIDEFORCE / CALCQ).
		SET AVGCOUNTER TO AVGCOUNTER + 1.
	}.
	
	// My horizontal X calculation
	// Vt = sqrt ( (2 * m * g) / (Cd * r * A) ) 
	// ^^^^ Terminal velocity
	SET Vsquared TO SHIP:AIRSPEED * SHIP:AIRSPEED.
	SET Density TO (SHIP:Q/Vsquared)*2.
	SET Density TO 1.225.
	PRINT "Density: " + Density AT (0,24).
	SET Vt TO SQRT((2*SHIP:MASS*g)/(Cd*Density)).
	PRINT "Vt: " + Vt AT (0,25).
	SET X TO ((Vt*Vt)/Go)*(LN(((Vt*Vt)+Go*Uo*FALLTIME)/(Vt*Vt))).
	PRINT "X: " + X AT (0,32).
	PRINT "TIME: " + (TIME:SECONDS - STARTTIME) AT (0,27).
	PRINT "CALCHORV: " + CALCHORV AT (0,33).
	WAIT 0.01.
}
}.
PRINT "AVG: " + (AVGCOEFF/AVGCOUNTER) AT (30,23).
//SET Cd TO (AVGCOEFF/AVGCOUNTER).
lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)	
SET VtV TO SQRT((2*SHIP:MASS*Go)/(0.01*Density)).	
SET TVFinal TO (VtV/Go)*ARCTAN(Vo/VtV).
PRINT "TVFinal: " + TVFinal AT(0,31).
// X/((Vt2)/g) = (LN((Vt2)+g*Uo*Vt)/Vt2)
// 
SET REALDISTANCE TO STARTINGSPOT:DISTANCE.
PRINT "REAL DISTANCE: " + REALDISTANCE AT (0,28).
SET REALTIME TO (TIME:SECONDS - STARTTIME).
PRINT "Uo: " + Uo AT(0,29).
SET ERROR TO X-REALDISTANCE.
PRINT "ERROR: " + ERROR AT (0,34).
if (true)
{
UNTIL (ERROR > -100)
{
	IF (Cd > 0.0022)
	{
		SET Cd TO Cd-0.001.
		SET ERROR TO 0.
	}.
	SET Vt TO SQRT((2*SHIP:MASS*Go)/(Cd*Density)).
	PRINT "Vt: " + Vt AT (0,25).
	SET X TO ((Vt*Vt)/Go)*(LN(((Vt*Vt)+Go*Uo*REALTIME)/(Vt*Vt))).
	PRINT "X: " + X AT (0,26).
	SET ERROR TO X-REALDISTANCE.
	PRINT "ERROR: " + ERROR AT (0,34).
	PRINT "Uo" + Uo AT (0,35).
}.
}.
PRINT "Final Cd: " + Cd AT (0,30).

// CALCULATED Cd = 0.011.// 0.037.
RCS ON.
LOCK THROTTLE TO 0.1.
LOCK STEERING TO HEADING(90,90).
SET SUICIDEBURN TO 0.
SET MEASURELIFT TO 0.
SET LASTTIME TO TIME:SECONDS.
SET LASTVV TO SHIP:VERTICALSPEED.
SET VERTICALACC TO 0.
SET HASRUN TO 0.
SET FINISHED TO 0.
SET TARGETALT TO 10.
UNTIL FINISHED = 1 {
	SET DELTATIME TO TIME:SECONDS - LASTTIME.
	SET LASTTIME TO TIME:SECONDS.
	IF (HASRUN = 1)
	{
		IF (DELTATIME > 0)
		{
			SET VERTICALACC TO (SHIP:VERTICALSPEED - LASTVV)/DELTATIME.
			SET LASTVV TO SHIP:VERTICALSPEED.
		}.
	}.
	lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)		
	if ADDONS:TR:AVAILABLE {
		if ADDONS:TR:HASIMPACT {
			PRINT ADDONS:TR:IMPACTPOS AT(0,1).
			SET VD TO VECDRAWARGS(
              ADDONS:TR:IMPACTPOS:ALTITUDEPOSITION(ADDONS:TR:IMPACTPOS:TERRAINHEIGHT+100),
              ADDONS:TR:IMPACTPOS:POSITION - ADDONS:TR:IMPACTPOS:ALTITUDEPOSITION(ADDONS:TR:IMPACTPOS:TERRAINHEIGHT+100),
              red, "Impact", 1, true).
			  
			SET XERROR TO ((launchPad:LNG-ADDONS:TR:IMPACTPOS:LNG)/180)*300000.
			SET YERROR TO ((launchPad:LAT-ADDONS:TR:IMPACTPOS:LAT)/180)*300000.
			SET ERRORDIST TO SQRT((XERROR*XERROR)+(YERROR*YERROR)).
			PRINT ERRORDIST AT(0,3).
			PRINT XERROR AT (0,4).
			PRINT YERROR AT (0,5).
			IF (SUICIDEBURN = 0)
			{
				IF (MEASURELIFT = 0)
				{
				// SET THROTTLE TO 1 TWR
					SET TWR TO ((SHIP:MAXTHRUST*1000)/((SHIP:MASS*1000)*g)).
					LOCK THROTTLE TO (1/TWR). 
					IF (ERRORDIST < 5)
					{
						LOCK THROTTLE TO 0.
						SET MEASURELIFT TO 1.
						LOCK STEERING TO (-1) * SHIP:VELOCITY:SURFACE.
					}.
				}.
			}.

			
			
			
			
			
			// -1000 = 100
			// 90 - (X/1000)
			SET PITCH TO 90 + ((XERROR/250)*90).
			SET DIR TO -90 + ((YERROR/250)*90).
			PRINT "DIR " + DIR + " PITCH " + PITCH AT (0,6).
			LOCK STEERING TO HEADING(DIR,PITCH).

			PRINT SHIP:MAXTHRUST AT (0,7).
			PRINT (SHIP:MASS) AT (0,8).
			// -5 M/S
			// 10kg
			// 20N
			// ACC

		 lock trueRadar to (ALT:RADAR - radarOffset) - 1.0.			// Offset radar to get distance from gear to ground
				
			IF (trueRadar > 0.5)
			{
				
				lock maxDecel to ((ship:availablethrust*1000) / (ship:mass*1000)) - g. 
				lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
				lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
				lock impactTime to trueRadar / abs(ship:verticalspeed). 
				SET ACC TO SHIP:MAXTHRUST/SHIP:MASS.
				
				//SET TIMETOSTOP TO (-SHIP:VERTICALSPEED)/(ACC).
			//	SET IMPACTTIME TO ((ALT:RADAR)/(-SHIP:VERTICALSPEED)).
				PRINT "RADAR ALT " + ALT:RADAR AT (0,8).
				PRINT "VERTICAL SPEED " + SHIP:VERTICALSPEED AT (0,9).
				PRINT "IMPACT TIME " + IMPACTTIME AT (0,10).
				PRINT "ACCELERATION " + ACC AT (0,11).
				//sIF (IMPACTTIME < TIMETOSTOP)
				//{
				//	LOCK THROTTLE TO 1.
				//	LOCK STEERING TO HEADING(-90,90).
				//	SET SUICIDEBURN TO 1.
				//}.
				
				IF (SHIP:GROUNDSPEED>0.5)
				{
					LOCK STEERING TO (-1) * SHIP:VELOCITY:SURFACE.
					IF (trueRadar < (stopDist*3))
					{
						IF (trueRadar > (stopDist*1.1))
						{
							// KILL HORISONTAL SPEED FIRST
							LOCK STEERING TO (-1) * SHIP:VELOCITY:SURFACE.
							SET SUICIDEBURN TO 1.
							SET TWR TO ((SHIP:MAXTHRUST*1000)/((SHIP:MASS*1000)*g)).
							LOCK THROTTLE TO (1/TWR). 
						}
					}
				}
				
				
				SET TIMETOSLAM TO (trueRadar-stopDist)/(-SHIP:VERTICALSPEED).
				
				
				
				
				print "Performing hoverslam..." + FLOOR(TIMETOSLAM) AT (0,12).
				IF (trueRadar < stopDist)
				{
					print "Performing hoverslam...NOW!   " AT (0,12).
					lock throttle to idealThrottle.
					LOCK STEERING TO HEADING(-90,90).
					SET SUICIDEBURN TO 1.
						///TWR.
					
					IF ((trueRadar+SHIP:VERTICALSPEED) < 50)
					{
						print "Performing hoverslam...HOVER!   " AT (0,12).
						SET TARGETALT TO TARGETALT - DELTATIME.
						// 2 - (-1+(10/10)) = 2 -(-0.9)
						// 2 - 10 = -8
						SET ALTCORRECTION TO (SHIP:VERTICALSPEED-((trueRadar-TARGETALT)/10)).
						LOCK THROTTLE TO (1.0/TWR) - ALTCORRECTION.
					}
				}.
				PRINT "Q: " + SHIP:Q AT (0,13).
				PRINT "VACC: " + VERTICALACC AT (0,14).
				PRINT "GRAVITY: " + g at (0,15).
				PRINT "LIFT ACCELERATION: " + (VERTICALACC - G) AT (0,16).
				PRINT "DELTATIME: " + DELTATIME AT (0,17).
				SET LIFTFORCE TO (VERTICALACC - G) * ship:mass.
				PRINT "LIFT COEFF: " + ((LIFTFORCE) / SHIP:Q) AT (0,18).
			} ELSE IF (SUICIDEBURN = 1)
			{
				print "Performing hoverslam...DONE " AT (0,12).
				LOCK THROTTLE TO 0.
				LOCK STEERING TO HEADING(-90,90).
				SET FINISHED TO 1.
				SAS ON.
			} ELSE {
				wait 0.1.
				}.
				SET HASRUN TO 1.
		} else {
			PRINT "Impact position is not available" AT(0,1).
		}
	} else {
		PRINT "Trajectories is not available." AT(0,1).
	}

}