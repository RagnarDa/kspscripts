// For unit-testing.
function Assert{
	parameter condition.
	parameter name.
	IF (condition = false)
	{
		PRINT "Assertion: " + name + " failed.".
		WAIT 10.
	}
}


SET KSC to SHIP:GEOPOSITION.

// Function to measure Cd
function MEASURECD {
	LOCK STEERING TO HEADING(90,90).
	LOCK THROTTLE TO 1.0.
	SET DELTATIME TO 0.1.
	SET LASTTIME TO TIME:SECONDS.
	SET VVACC TO 1.
	SET LASTVV TO 0.
	SET SUMCD TO 0.
	SET SUMCDI TO 0.
	SET FILTERCD TO 1.0.
	SET ITERATIONS TO 20000.
	UNTIL (SHIP:VERTICALSPEED > 200.0)
	{
		SET ITERATIONS TO ITERATIONS - 1.
		//PRINTDATA().
	// Measure Cd...
		WAIT 0.01.
		SET DELTATIME TO TIME:SECONDS - LASTTIME.
		SET LASTTIME TO TIME:SECONDS.
		SET VVACC TO (SHIP:VERTICALSPEED - LASTVV)/DELTATIME.
		SET LASTVV TO SHIP:VERTICALSPEED.
		lock g to GETGATALT(altitude).
		SET ENGINEPUSH TO ((SHIP:MAXTHRUST*1000)/(SHIP:MASS*1000)) - g.
		//PRINT "ENGINEPUSH: " + ENGINEPUSH AT (0,24).
		
		SET REMAININGACC TO VVACC - ENGINEPUSH.
		//SET REMAININGACC TO REMAININGACC - g.
		
		//PRINT "REMAINING ACC: " + REMAININGACC AT (0,18).
		SET AEROFORCE TO REMAININGACC*(SHIP:MASS*1000).
		//PRINT "AEROFORCE: " + AEROFORCE AT (0,19).
		SET CALCQ TO (GETDENSITY(ALTITUDE) * 0.5 * SHIP:AIRSPEED * SHIP:AIRSPEED).
		SET TRUEQ TO SHIP:Q*101325.
		//PRINT "CALC QV: " + CALCQ AT (0,22).
		//PRINT "Cd: " + AEROFORCE/CALCQ AT (0,20).
		//PRINT "Cd: " + AEROFORCE/SHIP:Q AT (0,21).
		IF (SHIP:VERTICALSPEED > 50.0 AND SHIP:VERTICALSPEED < 200.0)
		{
			SET SUMCD TO (SUMCD - (AEROFORCE/CALCQ)).
			SET SUMCDI TO (SUMCDI + 1).
			SET FILTERCD TO (FILTERCD * 0.9) + ((-AEROFORCE/CALCQ)*0.1).
			PRINT "Filtercd: " + FILTERCD AT (0,24).
			PRINT "Sumcd: " + SUMCD AT (0,25).
			print "Sumcdi: " + SUMCDI AT (0,26).
			PRINT "Av Cd: " + (SUMCD/SUMCDI) AT (0,27).
			PRINT "SHIPMASS : " + SHIP:MASS AT (0,28).
			SET Cd TO (SUMCD/SUMCDI) / 1000.
			SET Cd To FILTERCD / 1000.
		}
	}.
	//SET Cd TO (SUMCD/SUMCDI).
	PRINT "Av Cd: " + (SUMCD/SUMCDI) AT (0,22).
}.

// Simple get to orbit code
function ASCEONDTOORBIT {
	SET HASMEASUREDCD TO 0.
	UNTIL (APOAPSIS > TARGETALT * 0.999 AND PERIAPSIS > TARGETALT * 0.999)
	{
		SET ALTRATIO TO ALTITUDE/TARGETALT.
		SET APORATIO TO APOAPSIS/TARGETALT.
		LOCK STEERING TO HEADING(90,90 - (90*APORATIO)).
		
		// This will make it burn full throttle 3/4 of the ascent.
		SET ASCENTBURN TO (4.0-(APORATIO*4.0)).
		IF (ASCENTBURN < 0)
		{
			SET ASCENTBURN TO 0.
		}
		// A little push for circularization.
		SET TIMETOAPO TO (APOAPSIS-ALTITUDE)/ABS(SHIP:VERTICALSPEED).
		SET APOPERIRATIO TO (PERIAPSIS/APOAPSIS).
		SET CIRCBURN TO (1-APOPERIRATIO)/TIMETOAPO.
		PRINT "TIME TO APO: " + TIMETOAPO AT (0,0).
		PRINT "ASCENTBURN: " + ASCENTBURN AT (0,1).
		PRINT "APORATIO: " + APORATIO AT (0,2).
		PRINT "APOPERIRATIO: " + APOPERIRATIO AT (0,3).
		PRINT "CIRBURN: " + CIRCBURN AT (0,4).
		
		// Combine the two.
		LOCK THROTTLE TO ASCENTBURN+CIRCBURN.
		
		WAIT 0.25.
		IF (HASMEASUREDCD = 0 AND ALTITUDE < 500)
		{
			MEASURECD().
			SET HASMEASUREDCD TO 1.
		}

		IF (ALTITUDE > 10000)
		{
			RCS ON.
		}

		//PRINT "THROTTLE " + CIRCBURN AT (0,8).
		//WAIT 0.01.

	}
	LOCK THROTTLE TO 0.
}.

function CIRCULARIZE {
	LOCK STEERING TO PROGRADE.
	SET INITIALAPO TO APOAPSIS.
	// Wait until ship is ascending
	UNTIL (SHIP:VERTICALSPEED > 0)
	{
		WAIT 1.
	}
	SET TIMETOAPO TO (APOAPSIS-ALTITUDE)/SHIP:VERTICALSPEED.
	PRINT "TIMETO APO: "+ TIMETOAPO.
	UNTIL (TIMETOAPO < 10)
	{
		// Wait until 10 seconds remain to apo.
		WAIT TIMETOAPO-10.
		SET TIMETOAPO TO (APOAPSIS-ALTITUDE)/SHIP:VERTICALSPEED.
	}
	LOCK THROTTLE TO 1-(APOAPSIS/PERIAPSIS).
	
	UNTIL (PERIAPSIS > INITIALAPO)
	{
		SET TIMETOAPO TO (APOAPSIS-ALTITUDE)/SHIP:VERTICALSPEED.
		SET APOPERIRATIO TO (PERIAPSIS/APOAPSIS).
		SET CIRCBURN TO (1-APOPERIRATIO)/TIMETOAPO.
		LOCK THROTTLE TO CIRCBURN.
		PRINT "THROTTLE " + CIRCBURN AT (0,8).
		WAIT 0.01.
	}
	PRINT "CIRCULARIZED".
	LOCK THROTTLE TO 0.
}.


function GETDENSITY {
	parameter altitude.
	set LOWDENS TO 0.
	set HIGHDENS TO 0.
	SET MIX TO 1.
	if (altitude < 2500)
	{
		SET LOWDENS TO 1.225.
		SET HIGHDENS TO 0.898.
		SET MIX TO altitude/2500.
	} else if (altitude < 5000)
	{
		SET LOWDENS TO 0.898.
		SET HIGHDENS TO  0.642 .
		SET MIX TO (altitude-2500)/2500.
	} else if (altitude < 7500)
	{
		SET LOWDENS TO  0.642 .
		SET HIGHDENS TO 0.446.
		SET MIX TO (altitude-5000)/2500.
	} else if (altitude < 10000)
	{
		SET LOWDENS TO 0.446.
		SET HIGHDENS TO 0.288.
		SET MIX TO (altitude-7500)/2500.
	} else if (altitude < 15000)
	{
		SET LOWDENS TO 0.288.
		SET HIGHDENS TO 0.108 .
		SET MIX TO (altitude-10000)/5000.
	} else if (altitude < 20000)
	{
		SET LOWDENS TO 0.108.
		SET HIGHDENS TO 0.040 .
		SET MIX TO (altitude-15000)/5000.
	} else if (altitude < 25000)
	{
		SET LOWDENS TO 0.040 .
		SET HIGHDENS TO  	0.015 .
		SET MIX TO (altitude-20000)/5000.
	} else if (altitude < 30000)
	{
		SET LOWDENS TO  	0.015 .
		SET HIGHDENS TO 0.006 .
		SET MIX TO (altitude-25000)/5000.
	} else if (altitude < 40000)
	{
		SET LOWDENS TO 0.006 .
		SET HIGHDENS TO 0.001.
		SET MIX TO (altitude-30000)/10000.
	} else if (altitude < 70000)
	{
		SET LOWDENS TO 0.001.
		SET HIGHDENS TO 0.0001.
		SET MIX TO (altitude-40000)/30000.
	} else
	{
		RETURN 0.
	}
	RETURN (LOWDENS*(1-MIX))+(HIGHDENS*(MIX)).
}.

function GETGATALT {
	parameter ALTITUDETOCHECK.
	return body:mu / (ALTITUDETOCHECK + body:radius)^2.
}.

// Simple back-of-the envelope calculation from NASAs webpage.
function GETBALLISTICX {
	parameter STARTINGALT.
	parameter Uo.
	parameter Vo.
	parameter Cd.
	
	SET g to GETGATALT(STARTINGALT).
	SET Vt TO SQRT((2*SHIP:MASS*g)/((Cd*GETDENSITY(STARTINGALT))+0.000001)).
	SET ESTFALLTIME TO (Vo/g)*2.
	SET ymax TO (Vt^2 / (2 * g)) * ln ((Vo^2 + Vt^2)/Vt^2).
	SET ITERATIONS TO 5.
	UNTIL (ITERATIONS = 0)
	{

		SET NEWG TO GETGATALT(STARTINGALT+ymax).
		SET Vt TO SQRT((2*SHIP:MASS*NEWG)/((Cd*GETDENSITY((STARTINGALT+ymax)/2)))+0.000001).
		SET ymax TO (Vt^2 / (2 * NEWG)) * ln ((Vo^2 + Vt^2)/Vt^2).
		SET AVGG TO (g+NEWG)/2.
		SET FALLTIMENEW TO (Vo/AVGG)*2.
		
		SET X TO ((Vt*Vt)/AVGG)*(LN(((Vt*Vt)+AVGG*Uo*FALLTIMENEW)/(Vt*Vt))).
		
		SET ITERATIONS TO ITERATIONS - 1.
	}.
	RETURN X.
}

function GETAEROFORCE {
	parameter ALTITUDETOCHECK.
	parameter VEL.
	parameter CD.
	SET Q TO (GETDENSITY(ALTITUDETOCHECK) * 0.5 * VEL * VEL).
	RETURN Q * CD.
}.

function GETCURVEDDIST {
	parameter DIRECTDIST.
	parameter ALTITUDETOCHECK.
	SET ALTABOVECENTER TO Kerbin:RADIUS + ALTITUDETOCHECK.
	SET DISTINRAD TO ARCTAN(DIRECTDIST/ALTABOVECENTER) * Constant:DegToRad.
	RETURN DISTINRAD * Kerbin:RADIUS.
}

function GETSTRAIGHTDIST {
	parameter CURVEDDIST.
	parameter ALTITUDETOCHECK.
	SET A TO CURVEDDIST / Kerbin:RADIUS.
	SET B TO A / CONSTANT:DegToRad.
	SET C TO TAN(B).
	SET ALTABOVECENTER TO Kerbin:RADIUS + ALTITUDETOCHECK.
	RETURN C * ALTABOVECENTER.
}

// RETURN LIST(CURRENTALT, DISTANCEX, CURRENTHORV, CURRENTVERV)
function TRAJECTORYSTEP {
	parameter PCURRENTALT.
	parameter PCURRENTHORV.
	parameter PCURRENTVERV.
	parameter PDT.

	LOCAL LSMASS TO SHIP:MASS * 1000.

	LOCAL LAERODYNAMICFORCEHOR TO GETAEROFORCE(PCURRENTALT, PCURRENTHORV, Cd).
	LOCAL LAERODYNAMICFORCEVER TO GETAEROFORCE(PCURRENTALT, PCURRENTVERV, Cd).

	LOCAL LNEWHORV TO PCURRENTHORV - ((LAERODYNAMICFORCEHOR / LSMASS)*PDT).
	LOCAL LNEWVERV TO 0.
	IF (PCURRENTVERV > 0)
	{
		SET LNEWVERV TO PCURRENTVERV - ((LAERODYNAMICFORCEVER / LSMASS) * PDT).
	} ELSE {
		// I guess if falling the vertical drag is applied upwards.
		SET LNEWVERV TO PCURRENTVERV + ((LAERODYNAMICFORCEVER / LSMASS) * PDT).
	}
	// Apply G.
	SET LNEWVERV TO LNEWVERV - (GETGATALT(PCURRENTALT) * PDT).

	// Add the horv that is added as vertical V because we are
	// "missing" the body (ie orbit). Maybe do this somehow for horv too?
	LOCAL LRADIALDIST TO PCURRENTALT + Kerbin:RADIUS.
	SET LNEWVERV TO LNEWVERV + (SQRT((LNEWHORV*LNEWHORV)+(LRADIALDIST*LRADIALDIST))-LRADIALDIST).

	// Prepare for next iteration.
	LOCAL RCURRENTHORV TO LNEWHORV.
	LOCAL RCURRENTVERV TO LNEWVERV.
	LOCAL RCURRENTALT TO PCURRENTALT + RCURRENTVERV.
	LOCAL RDISTANCEX TO GETCURVEDDIST(RCURRENTHORV, RCURRENTALT).
	
	// Return a list
	RETURN LIST(RCURRENTALT, RDISTANCEX, RCURRENTHORV, RCURRENTVERV).
}

// RETURN LIST(CURRENTALT, DISTANCEX, CURRENTHORV, CURRENTVERV)
function RK4Step {
	parameter CURRENTALT.
	parameter CURRENTHORV.
	parameter CURRENTVERV.
	parameter DT.

	SET f0 TO TRAJECTORYSTEP( CURRENTALT, CURRENTHORV, CURRENTVERV, DT).//t0, u0 );

  	SET t1 TO DT/2.0.//t1 = t0 + dt / 2.0;
	SET a1 TO CURRENTALT + (DT * (f0[0]-CURRENTALT)/2.0).
	SET u1 TO CURRENTVERV + (DT * (f0[3]-CURRENTVERV) / 2.0). //u1 = u0 + dt * f0 / 2.0;
	SET v1 TO CURRENTHORV + (DT * (f0[2]-CURRENTHORV) / 2.0). 
	SET x1 TO 0 + (DT * f0[1] / 2.0). 
  	SET f1 TO TRAJECTORYSTEP(a1, v1, u1, DT/2).//f1 = f ( t1, u1 );

	SET t2 TO DT/2.0.//t2 = t0 + dt / 2.0;
	SET a2 TO CURRENTALT + (DT * (f1[0]-CURRENTALT)/2.0).
	SET u2 TO CURRENTVERV + (DT * (f1[3]-CURRENTVERV) / 2.0). //u2 = u0 + dt * f1 / 2.0;
	SET v2 TO CURRENTHORV + (DT * (f1[2]-CURRENTHORV) / 2.0).
	SET x2 TO 0 + (DT * f1[1] / 2.0).
  	SET f2 TO TRAJECTORYSTEP(a2, v2, u2, DT/2).//f2 = f ( t2, u2 );

  	SET t3 TO DT.//t3 = t0 + dt;
	SET a3 TO CURRENTALT + (DT * (f2[0]-CURRENTALT)).
	SET u3 TO CURRENTVERV + (DT * (f2[3]-CURRENTVERV)). //u3 = u0 + dt * f2;
	SET v3 TO CURRENTHORV + (DT * (f2[2]-CURRENTHORV)). 
	SET x3 TO 0 + (DT * f2[1]).
  	SET f3 TO TRAJECTORYSTEP(a3, v3, u3, DT).//f3 = f ( t3, u3 );


	//PRINT "a0 " + CURRENTALT + " a1 " + a1 + " a2 " + a2 + " a3 " + a3.
	//
	//  Combine to estimate the solution at time T0 + DT.
	//
	SET a TO (f0[0] + 2.0 * f1[0] + 2.0 * f2[0] + f3[0]) / 6.0. //u = u0 + dt * ( f0 + 2.0 * f1 + 2.0 * f2 + f3 ) / 6.0;
  	SET u TO (f0[3] + 2.0 * f1[3] + 2.0 * f2[3] + f3[3]) / 6.0. //u = u0 + dt * ( f0 + 2.0 * f1 + 2.0 * f2 + f3 ) / 6.0;
	SET v TO (f0[2] + 2.0 * f1[2] + 2.0 * f2[2] + f3[2]) / 6.0. //u = u0 + dt * ( f0 + 2.0 * f1 + 2.0 * f2 + f3 ) / 6.0;
	SET x TO 0 + DT * (f0[1] + 2.0 * f1[1] + 2.0 * f2[1] + f3[1]) / 6.0. //u = u0 + dt * ( f0 + 2.0 * f1 + 2.0 * f2 + f3 ) / 6.0;

	RETURN LIST(a, x, v, u).
}

function GETEULERBALLX {
	// Iterative Euler method.
	parameter STARTINGALT.
	parameter ENDALT.
	parameter Uo.
	parameter Vo.
	parameter Cd.
	SET DT to 1.
	SET ITERATIONS TO 1000.
	SET CURRENTALT TO STARTINGALT.
	SET CURRENTHORV TO Uo.
	SET CURRENTVERV TO Vo.
	SET DISTANCEX TO 0.
	SET SMASS TO SHIP:MASS * 1000.
	//PRINT "CURRENTALT: " + CURRENTALT.
	//PRINT "CURRENTHORV: " + CURRENTHORV.
	//PRINT "CURRENTVERV: " + CURRENTVERV.
	//PRINT "DISTANCEX: " + DISTANCEX.
	//PRINT "ITERATION: " + ITERATIONS.
	//PRINt "SHIP MASS: " + SMASS.
	UNTIL (ITERATIONS = 0)
	{
		SET ESTIMATE TO TRAJECTORYSTEP(CURRENTALT, CURRENTHORV, CURRENTVERV, 1.0).

		// Prepare for next iteration.
		SET CURRENTHORV TO ESTIMATE[2].
		SET CURRENTVERV TO ESTIMATE[3].
		SET CURRENTALT TO ESTIMATE[0].
		SET DISTANCEX TO DISTANCEX + ESTIMATE[1].
		
		//PRINT "CURRENTALT: " + CURRENTALT.
		//PRINT "CURRENTHORV: " + CURRENTHORV.
		//PRINT "CURRENTVERV: " + CURRENTVERV.
		//PRINT "DISTANCEX: " + DISTANCEX.
		//PRINT "ITERATION: " + ITERATIONS.
		IF (CURRENTALT < ENDALT) 
		{
			// End iterations.
			SET ITERATIONS TO 0.
		} ELSE {
			// Continue iterations.
			SET ITERATIONS TO ITERATIONS - 1.
			IF (ITERATIONS = 0)
			{
				PRINT "NO SOLUTION FOUND!".
				PRINT "NO SOLUTION FOUND!" AT (10,0).
				RETURN -1.
			}
		}
	}.
	RETURN LIST(DISTANCEX, DISTANCEX, CURRENTHORV, CURRENTVERV).
}.

function GETRK4BALLX {
	// Iterative RK4 method.
	parameter STARTINGALT.
	parameter ENDALT.
	parameter Uo.
	parameter Vo.
	parameter Cd.
	SET DT to 1.
	SET ITERATIONS TO 1000.
	SET CURRENTALT TO STARTINGALT.
	SET CURRENTHORV TO Uo.
	SET CURRENTVERV TO Vo.
	SET DISTANCEX TO 0.
	SET SMASS TO SHIP:MASS * 1000.
	//PRINT "CURRENTALT: " + CURRENTALT.
	//PRINT "CURRENTHORV: " + CURRENTHORV.
	//PRINT "CURRENTVERV: " + CURRENTVERV.
	//PRINT "DISTANCEX: " + DISTANCEX.
	//PRINT "ITERATION: " + ITERATIONS.
	//PRINt "SHIP MASS: " + SMASS.
	UNTIL (ITERATIONS = 0)
	{
		// RETURN LIST(CURRENTALT, DISTANCEX, CURRENTHORV, CURRENTVERV)
		//function RK4Step {
	//parameter CURRENTALT.
	//parameter CURRENTHORV.
	//parameter CURRENTVERV.
	//parameter DT.
		SET ESTIMATE TO RK4Step(CURRENTALT, CURRENTHORV, CURRENTVERV, 1.0).

		// Prepare for next iteration.
		SET CURRENTHORV TO ESTIMATE[2].
		SET CURRENTVERV TO ESTIMATE[3].
		SET CURRENTALT TO ESTIMATE[0].
		SET DISTANCEX TO DISTANCEX + ESTIMATE[1].
		//PRINT "CURRENTALT: " + CURRENTALT.
		//PRINT "CURRENTHORV: " + CURRENTHORV.
		//PRINT "CURRENTVERV: " + CURRENTVERV.
		//PRINT "DISTANCEX: " + DISTANCEX.
		//PRINT "ITERATION: " + ITERATIONS.
		IF (CURRENTALT < ENDALT) 
		{
			// End iterations.
			SET ITERATIONS TO 0.
		} ELSE {
			// Continue iterations.
			SET ITERATIONS TO ITERATIONS - 1.
			IF (ITERATIONS = 0)
			{
				PRINT "NO SOLUTION FOUND!".
				PRINT "NO SOLUTION FOUND!" AT (10,0).
				RETURN -1.
			}
		}
	}.
	RETURN LIST(DISTANCEX, DISTANCEX, CURRENTHORV, CURRENTVERV).
}.

function GETGROUNDDIST {
	parameter POS.
	// Calculating geographical distance.
	SET POSDISTGEO TO SQRT(((POS:LNG-SHIP:GEOPOSITION:LNG)*(POS:LNG-SHIP:GEOPOSITION:LNG))+((POS:LAT-SHIP:GEOPOSITION:LAT)*(POS:LAT-SHIP:GEOPOSITION:LAT))).
	IF (POSDISTGEO < 0)
	{
		SET POSDISTGEO TO POSDISTGEO + 360.
	}
	// Calculate it to meters.
	RETURN (POSDISTGEO/180)*(CONSTANT:PI*Kerbin:RADIUS).
}

LOCK CALCHORV TO COS((ARCSIN(SHIP:VERTICALSPEED/SHIP:AIRSPEED)))*SHIP:AIRSPEED.
function PRINTDATA {
	SET Cd TO 0.007.
	
	//PRINT "CURRENT X:" + GETBALLISTICX(ALTITUDE, SHIP:VERTICALSPEED, CALCHORV, Cd) at (20,0).
	PRINT "KSCDIST: " + GETGROUNDDIST(KSC) at (20,1).
}

function DEORBIT {
	parameter DEORBITALT.
	parameter DEORBITV.
	parameter DEORBITVV.
	// First calculate a deorbit burn which would put the impact point on the
	// other side of Kerbin
	
	

	//SET DEORBITV TO 4049. // TEST
	//SET DEORBITALT TO 89000. // TEST
	PRINT "DEORBITBURN DIST: " + Kerbin:RADIUS * CONSTANT:PI AT (0,7).
	PRINT "INITALV: " + DEORBITV AT (0,8).
	PRINT "INITALT: " + DEORBITALT AT (0,9).
	SET IMPACTDIST TO Kerbin:RADIUS * CONSTANT:PI * 2.
	UNTIL (IMPACTDIST < Kerbin:RADIUS * CONSTANT:PI AND IMPACTDIST > 0)
	{
		SET DEORBITV TO DEORBITV * 0.975.
		SET IMPACTDIST TO GETRK4BALLX(DEORBITALT, 0, DEORBITV, DEORBITVV, Cd)[0].
		PRINT "IMPACTDIST: " + IMPACTDIST AT (0,10).
		PRINT "DEORBITV: " + DEORBITV AT (0,11).
	}
	PRINT "WAITING TIL WEST OF KSC".
	UNTIL (KSC:LNG>SHIP:GEOPOSITION:LNG)
	{
		set kuniverse:timewarp:warp to 3.
		WAIT 10.
		IF (KSC:LNG>SHIP:GEOPOSITION:LNG)
		{
			set kuniverse:timewarp:warp to 0.
			WAIT 60.
		}
	}
	set kuniverse:timewarp:warp to 0.
	SET LASTDIFF TO GETGROUNDDIST(KSC)-IMPACTDIST.
	SET DEORBITV TO GETCURVEDDIST(DEORBITV, DEORBITALT).
	SET DIFF TO GETGROUNDDIST(KSC)-IMPACTDIST.
	SET TIMETODEORBITBURN TO 1000000000000.
	SET BURNTIME TO 0.
	UNTIL (0 > (TIMETODEORBITBURN - (BURNTIME*2.0))) // HACK!
	{
		// Wait until burn time.
		WAIT 0.1.
		SET DIFF TO GETGROUNDDIST(KSC)-IMPACTDIST.
		
		SET TIMETODEORBITBURN TO ABS((DIFF/(LASTDIFF-DIFF))*0.1).
		SET LASTDIFF TO DIFF.
		SET BURNTIME TO ((GETSTRAIGHTDIST(CALCHORV, DEORBITALT) - DEORBITV)/((SHIP:MAXTHRUST*1000)/(SHIP:MASS*1000))).
		//SET BURNTIME TO 6. // HACK!
		PRINT "DEORBIT IN: " + TIMETODEORBITBURN AT (0,12).
		PRINT "DIST: " + GETGROUNDDIST(KSC) AT (0,13).
		PRINT "REMAINING DEORBIT V: " + (GETSTRAIGHTDIST(CALCHORV, DEORBITALT) - DEORBITV) AT (0,14).
		PRINT "BURNTIME: " + BURNTIME AT (0,15).
		PRINT "THRUST: " + SHIP:MAXTHRUST*1000 AT (0,16).
		PRINT "MASS: " + SHIP:MASS*1000 AT (0,17).
		LOCK STEERING TO RETROGRADE.
		RCS ON.
		
	}
	UNTIL (DEORBITV > GETSTRAIGHTDIST(CALCHORV, DEORBITALT))
	{
		PRINT "REMAINING DEORBIT V: " + (GETSTRAIGHTDIST(CALCHORV, DEORBITALT) - DEORBITV) AT (0,14).
		//LOCK THROTTLE TO 1-(DEORBITV/CALCHORV). // 1-(100/1000) = 1-0.1 = 0.9
		LOCK THROTTLE TO 0.5. // HACK
	}.
	LOG "DEORBITED AT ALT "+ altitude + " DIST " + GETGROUNDDIST(KSC) + " WITH IMPACTX " + IMPACTDIST TO "mylog".
	LOCK THROTTLE TO 0.
	UNTIL (ALTITUDE < 50000) // Still outside atmosphere...
	{
		
		// Do a recursive burn at 0.9 alt
		SET DECISIONALT TO SHIP:ALTITUDE * 0.9. // Decision alt
		PRINT "CORRECTION AT " + DECISIONALT.
		LOG "CORRECTION AT " + DECISIONALT TO "mylog".
		SET DECISIONTRAJ TO GETRK4BALLX(DECISIONALT, 0, GETSTRAIGHTDIST(SHIP:AIRSPEED, DECISIONALT), SHIP:VERTICALSPEED, Cd).
		UNTIL (ALTITUDE < DECISIONALT)
		{
			WAIT 0.5.
		}
		SET OVERSHOOT TO DECISIONTRAJ[0]-GETGROUNDDIST(KSC).
		PRINT "WILL OVERSHOOT: " + OVERSHOOT.
		LOG "WILL OVERSHOOT: " + OVERSHOOT TO "mylog".
		IF (OVERSHOOT > 5000)
		{
			// VEEERY HACKISH.
			LOCK STEERING TO RETROGRADE.
			LOCK THROTTLE TO 0.1.
			WAIT 1.0.
			LOCK THROTTLE TO 0.0.
		}.
	}.
	
	LOCK STEERING TO PROGRADE.
}
function TransferFor {
	SET sourceParts to SHIP:PARTSDUBBED("AFTTANK").
	SET destinationParts to SHIP:PARTSDUBBED("FORTANK").
	SET foo TO TRANSFERALL("liquidfuel", sourceParts, destinationParts).
	SET foo:ACTIVE to TRUE.
	SET sourceParts to SHIP:PARTSDUBBED("AFTTANK").
	SET destinationParts to SHIP:PARTSDUBBED("FORTANK").
	SET foo TO TRANSFERALL("oxidizer", sourceParts, destinationParts).
	SET foo:ACTIVE to TRUE.
	PRINT "TRANSFER COMPLETE".
}.

function TransferAft {
	SET sourceParts to SHIP:PARTSDUBBED("FORTANK").
	SET destinationParts to SHIP:PARTSDUBBED("AFTTANK").
	SET foo TO TRANSFERALL("liquidfuel", sourceParts, destinationParts).
	SET foo:ACTIVE to TRUE.
	SET sourceParts to SHIP:PARTSDUBBED("FORTANK").
	SET destinationParts to SHIP:PARTSDUBBED("AFTTANK").
	SET foo TO TRANSFERALL("oxidizer", sourceParts, destinationParts).
	SET foo:ACTIVE to TRUE.
	PRINT "TRANSFER COMPLETE".
}.


// Remember ALPHA is _positive_ when going down.
function GETALPHADEG {
	parameter HORV.
	parameter VERV.
	parameter PITCH.
	LOCAL VELVEC TO ARCTAN(VERV/HORV).
	LOCAL ALPHA TO PITCH-VELVEC.
	IF (ALPHA > 360)
	{
		SET ALPHA TO ALPHA - 360.
	}
	RETURN ALPHA.
}

function GLIDE {
	PRINT "GLIDING...".
	TransferAft().
	UNTIL (SHIP:VERTICALSPEED < 0)
	{
		WAIT 0.5.
	}
	SET TARGETDIST TO KSC:DISTANCE.
	LOCAL TIMETOCRASH TO ALTITUDE/(-SHIP:VERTICALSPEED).
	//SET THROTTLE TO 0.05.
	LOCAL HOVERSLAMALT TO GETHOVERSLAMALTITUDE(SHIP:MASS,SHIP:MAXTHRUST,GETGATALT(0),SHIP:VERTICALSPEED).
	UNTIL ((ALT:RADAR - 5 - (0*(-SHIP:VERTICALSPEED))) < HOVERSLAMALT * 0)// - (SHIP:VERTICALSPEED*1.1))
	{
		// SIMPLE GLIDE ALGO, JUST AIM AT TARGET.
		// Surprisingly effective.
		SET TARGETDIST TO KSC:DISTANCE.
		SET CURALT TO ALT:RADAR.
		
		PRINT "ALTITUDE " + CURALT.
		PRINT "DISTANCE " + TARGETDIST.
		IF (CURALT > TARGETDIST)
		{
			SET CURALT TO TARGETDIST.
		}.
		SET GLIDEPATH TO ARCSIN((CURALT)/TARGETDIST). // HACK: Aim 500m above.
		SET NORTHERROR TO (KSC:LAT-SHIP:GEOPOSITION:LAT).
		PRINT "GLIDEPATH " + (GLIDEPATH).
		LOCAL BACKWARDSALPHA TO 90-GETALPHADEG(CALCHORV,SHIP:VERTICALSPEED,SHIP:FACING:PITCH).
		PRINT "BACKWARDSALPHA " + BACKWARDSALPHA.
		PRINT "NORTHERROR " + NORTHERROR * 2.
		LOCK STEERING TO HEADING(-90+(NORTHERROR*2),(GLIDEPATH-BACKWARDSALPHA)).
		WAIT 0.1.
		LOCAL TIMETOCRASH TO ALTITUDE/(-SHIP:VERTICALSPEED).
		LOCAL MASSREQUIRED TO CALCULATEMASSREQUIRED(GETGATALT(ALTITUDE),260,SHIP:MASS,ABS(SHIP:VERTICALSPEED)).

		SET HOVERSLAMALT TO GETHOVERSLAMALTITUDE(SHIP:MASS - MASSREQUIRED,SHIP:MAXTHRUST,GETGATALT(ALTITUDE),SHIP:VERTICALSPEED).
		PRINT "HOVERSLAM ALT: " + HOVERSLAMALT.

		PRINT "STOP TIME: " + GETSTOPTIME(SHIP:MASS - MASSREQUIRED,SHIP:MAXTHRUST,GETGATALT(ALTITUDE),-SHIP:VERTICALSPEED).
	}
	LOCK STEERING TO UP.
	WAIT 5. // Wait for reorientation.
	LOCK THROTTLE TO 1.
	LOCAL MASSREQUIRED TO CALCULATEMASSREQUIRED(GETGATALT(ALTITUDE),260,SHIP:MASS,ABS(SHIP:VERTICALSPEED)).
	WAIT GETSTOPTIME(SHIP:MASS - MASSREQUIRED,SHIP:MAXTHRUST,GETGATALT(ALTITUDE),-SHIP:VERTICALSPEED).
	UNTIL(FALSE)
	{
	LOCAL shiptwr TO GETTWR(ALTITUDE).
	LOCAL P TO ABS(FACING:PITCH)+90.
	LOCAL throttlesetting TO GETHOVERTHROTTLE(shiptwr, P).
	LOCK THROTTLE TO throttlesetting - (SHIP:VERTICALSPEED+(ALT:RADAR/10)).
	}.
//	TransferAft().
	UNTIL (ALTITUDE < 5000)
	{
		// More complicated glide...
		PRINTDATA().
		// Gliding test
		SET LASTESTIMATE TO 0.
		IF (SHIP:VERTICALSPEED < 0)
		{
			SET TARGETDIST TO GETGROUNDDIST(KSC).
			SET TRAJDIST TO GETRK4BALLX(ALTITUDE,0, GETSTRAIGHTDIST(SHIP:AIRSPEED, ALTITUDE), SHIP:VERTICALSPEED, Cd)[0].
			
			// We need to compensate for slow computation.
			SET ESTDIFF TO TRAJDIST - LASTESTIMATE.
			SET IMPACTERROR TO TARGETDIST - (TRAJDIST + (ESTDIFF*2)).

			PRINT "IMPACTERROR: " + IMPACTERROR AT (20,2).

			IF (IMPACTERROR < -100)
			{
				// Try to glide further
				LOCK STEERING TO HEADING(90,5).
				LOG "GLIDING..." TO "mylog".
			} ELSE IF (IMPACTERROR > 100)
			{
				// Try to glide down
				LOCK STEERING TO HEADING(90,-90).
				LOG "DIVING..." TO "mylog".
			} ELSE {
				LOCK STEERING TO PROGRADE.
				LOG "ON TARGET." TO "mylog".
			}
			
			SET LASTESTIMATE TO TRAJDIST.
		}
		WAIT 1.
	}
	LOG "CRASHING AT " + GETGROUNDDIST(KSC) TO "mylog".
}

// Assumes same ISP! HACK
function GETTWR {
	parameter ALTITUDETOCHECK.
	LOCAL GRAVITYPULL TO ((SHIP:MASS*1000)*GETGATALT(ALTITUDETOCHECK)).
	RETURN ((SHIP:MAXTHRUST*1000)/GRAVITYPULL).
}

// Returns the throttle position to keep same altitude
// with current pitch (ie more throttle when at an angle)
// Pitch is relative to horizon, so use ABS(FACING:PITCH)+90.
function GETHOVERTHROTTLE {
	parameter thrusttoweightratio.
	parameter pitchtocheck.
	LOCAL LEANOPP TO SIN(ABS(pitchtocheck-90))*(1/thrusttoweightratio).
	RETURN SQRT((LEANOPP*LEANOPP)+((1/thrusttoweightratio)*(1/thrusttoweightratio))).
}

// For rod
function CALCULATEMOI {
	parameter m.
	parameter L.
	return (1/12)*m*L*L.
}

function CALCULATETORQUE {
	parameter L.
	parameter F.
	parameter angle.
	return (L/2)*F*sin(angle).
}

// Calculate approximate rotation degree/second^2 at power 
// (no aerodynamic forces considered)
function GETPOWEREDROTATIONACC {
	parameter SHIPLENGTH.
	parameter SHIPWEIGHT.
	parameter SHIPTHRUST.
	parameter ENGINEGIMBAL.
	RETURN CALCULATETORQUE(SHIPLENGTH, SHIPTHRUST, ENGINEGIMBAL)/CALCULATEMOI(SHIPWEIGHT, SHIPLENGTH).
}

// Calculates the distance traveled at constant
// acceleration and speed
function GETDISPLACEMENT {
	parameter initialvel.
	parameter t.
	parameter a.
	return (initialvel*t)+(0.5*a*t*t).
}

// Calculates the time it takes to turn the
// ship around completely at power setting
// using thrust alone. Aerodynamics not considered.
function GETPOWEREDONEEIGHTYTURNTIME {
	parameter SHIPLENGTH.
	parameter SHIPWEIGHT.
	parameter SHIPTHRUST.
	parameter ENGINEGIMBAL.
	RETURN SQRT(CONSTANT:PI*2/GETPOWEREDROTATIONACC(SHIPLENGTH,SHIPWEIGHT,SHIPTHRUST,ENGINEGIMBAL)).
}

// Returns time to stop vessel by thrust.
function GETSTOPTIME {
	parameter SHIPWEIGHT.
	parameter SHIPTHRUST.
	parameter GRAVITY.
	parameter INITIALVELOCITY.
	RETURN INITIALVELOCITY/((SHIPTHRUST/SHIPWEIGHT)-GRAVITY).
}
Assert((GETSTOPTIME(1000,2000,10,10)<GETSTOPTIME(1000,2000,20,10)), "GetStopTime 1").
Assert((GETSTOPTIME(500,2000,10,10)<GETSTOPTIME(1000,2000,10,10)), "GetStopTime 2").
Assert((GETSTOPTIME(1000,3000,10,10)<GETSTOPTIME(1000,2000,10,10)), "GetStopTime 3").
Assert((GETSTOPTIME(1000,2000,10,10)<GETSTOPTIME(1000,2000,30,10)), "GetStopTime 4").

// Returns the altitude which to start full thrust to not hit ground.
function GETHOVERSLAMALTITUDE {
	parameter SHIPWEIGHT.
	parameter SHIPTHRUST.
	parameter GRAVITY.
	parameter VERTICALVELOCITY.
	//RETURN GETDISPLACEMENT(-VERTICALVELOCITY,GETSTOPTIME(SHIPWEIGHT, SHIPTHRUST, GRAVITY, -VERTICALVELOCITY), ((SHIPTHRUST/SHIPWEIGHT))).
	RETURN 0.5 * -VERTICALVELOCITY * GETSTOPTIME(SHIPWEIGHT, SHIPTHRUST, GRAVITY, -VERTICALVELOCITY).
}

//PRINT "TEST HOVER SLAM ALT:" + GETHOVERSLAMALTITUDE(100,2000,10,-10).
//Assert((GETHOVERSLAMALTITUDE(100,2000,10,-10)<16), "Hover slam altitude 1").
//Assert((GETHOVERSLAMALTITUDE(100,2000,10,-10)>9), "Hover slam altitude 2").
Assert((GETHOVERSLAMALTITUDE(100,2000,10,-20)>GETHOVERSLAMALTITUDE(100,2000,10,-10)), "Hover slam altitude 3").
Assert((GETHOVERSLAMALTITUDE(100,2000,11,-20)>GETHOVERSLAMALTITUDE(100,2000,10,-20)), "Hover slam altitude 4").
Assert((GETHOVERSLAMALTITUDE(100,2000,10,-20)>GETHOVERSLAMALTITUDE(50,2000,10,-20)), "Hover slam altitude 5").
Assert((GETHOVERSLAMALTITUDE(50,1000,10,-20)>GETHOVERSLAMALTITUDE(50,2000,10,-20)), "Hover slam altitude 6").



// Returns the mass (in kg) of the required propellant
// to achieve given Dv at G.
function CALCULATEMASSREQUIRED {
	parameter GRAVITY.
	parameter ISP.
	parameter INITIALMASS.
	parameter Dv.
	RETURN INITIALMASS - (INITIALMASS / (CONSTANT:E^(Dv/(GRAVITY*ISP)))).
}
Assert((CALCULATEMASSREQUIRED(9.80665, 260, 100000,13000) > 99000), "Calculatemassrequired 1").
Assert((CALCULATEMASSREQUIRED(9.80665, 260, 100000,13000) < 100000), "Calculatemassrequired 2").



function LAND {
	LOCAL ROTATIONTIME TO GETPOWEREDONEEIGHTYTURNTIME(13.6,SHIP:MASS, 168, 3).
	PRINT "ROTATION TIME CURRENT " + ROTATIONTIME.
	LOCK THROTTLE TO 1.
	LOCK STEERING TO HEADING(0,0).
	TransferFor().
	WAIT ROTATIONTIME.
	LOCK THROTTLE TO 0.
	WAIT 5.
	// ROTATION TEST
	LOCAL TIMETOCRASH TO ALTITUDE/(-SHIP:VERTICALSPEED).
	UNTIL (TIMETOCRASH + 1 < ROTATIONTIME*3)
	{
		WAIT 0.1.
		SET TIMETOCRASH TO ALTITUDE/(-SHIP:VERTICALSPEED).
	}.
	// First achieve horiztontal heading
	TransferAft().
	LOCK THROTTLE TO 0.25.
	LOCAL TIMER TO 10.
	UNTIL (TIMER < 0)
	{
		LOCK STEERING TO HEADING(0,90/TIMER).
		WAIT 0.1.
		SET TIMER TO TIMER - 0.1.
	}
	LOCK THROTTLE TO 1.
	LOCK STEERING TO UP.
	WAIT ROTATIONTIME.
	LOCK THROTTLE TO 1.
	LOCK STEERING TO RETROGRADE.
	WAIT ROTATIONTIME.
	LOCK THROTTLE TO 0.
	UNTIL (FALSE)
	{
		//PRINTDATA().
		
		LOCAL shiptwr TO GETTWR(ALTITUDE).
		LOCAL P TO ABS(FACING:PITCH)+90.
		LOCAL throttlesetting TO GETHOVERTHROTTLE(shiptwr, P).
		LOCK THROTTLE TO throttlesetting.// - (SHIP:VERTICALSPEED+(ALT:RADAR/10)).
	
		IF (SHIP:GROUNDSPEED < 0.5)
		{
			LOCK STEERING TO UP.
		}
	}
}.

function LANDINVERTED {
	LOCK THROTTLE TO 0.
	LOCK STEERING TO PROGRADE.
	UNTIL (FALSE)
	{
		//PRINTDATA().
		
		LOCAL shiptwr TO GETTWR(ALTITUDE).
		LOCAL P TO ABS(FACING:PITCH)-90.
		LOCAL throttlesetting TO GETHOVERTHROTTLE(shiptwr, P).
		LOCK THROTTLE TO throttlesetting - SHIP:VERTICALSPEED.// - (SHIP:VERTICALSPEED+(ALT:RADAR/10)).
	
		IF (SHIP:GROUNDSPEED < 0.5)
		{
			LOCK STEERING TO UP.
		}
	}
}.



// Assert
Assert((GETALPHADEG(10,10,10) <> 0), "Alpha computation 1").
Assert((GETALPHADEG(1,10,10) < -70), "Alpha computation 2").
Assert((GETALPHADEG(1,-10,10) > 85), "Alpha computation 3").
Assert((GETALPHADEG(1,-10,80) > 100), "Alpha computation 4").
Assert((GETGATALT(0) < 9.9) AND GETGATALT(0) > 9.8, "S/L gravity").
Assert((GETGATALT(10000) < 9.86), "1 km gravity").
stage.
Assert((GETTWR(0) > 1 AND GETTWR(0) < 2), "TWR too low/high?").
Assert((GETHOVERTHROTTLE(2,90) = 0.5), "Hover throttle at up facing.").
Assert((GETHOVERTHROTTLE(2,45) > 0.5) AND (GETHOVERTHROTTLE(2,45) < (0.5*1.5)), "Hover throttle at angle.").
Assert((GETHOVERTHROTTLE(1,90) = 1.0), "Hover throttle at up facing.").


//function CALCULATETORQUE {
//	parameter L.
//	parameter F.
//	parameter angle.
Assert((CALCULATETORQUE(20,100,90)=1000), "Torque calc 1").
Assert((CALCULATETORQUE(20,100,45)>707 AND CALCULATETORQUE(20,100,45)<708), "Torque calc 2").

//function CALCULATEMOI {
//	parameter m.
//	parameter L.
Assert((CALCULATEMOI(10,10) < CALCULATEMOI(15,10)), "Calc moi 1").
Assert((CALCULATEMOI(10,10) < CALCULATEMOI(10,15)), "Calc moi 2").

//function GETPOWEREDROTATIONACC {
//	parameter SHIPLENGTH.
//	parameter SHIPWEIGHT.
//	parameter SHIPTHRUST.
//	parameter ENGINEGIMBAL.
PRINT "ACC NOW " + GETPOWEREDROTATIONACC(13.6,SHIP:MASS, 168, 3).
PRINT "ACC WET " + GETPOWEREDROTATIONACC(13.6,SHIP:WETMASS, 168, 3).
PRINT "ACC DRY " + GETPOWEREDROTATIONACC(13.6,SHIP:DRYMASS, 168, 3).
Assert((GETPOWEREDROTATIONACC(13.6,SHIP:WETMASS, 168, 3) < GETPOWEREDROTATIONACC(13.6,SHIP:DRYMASS, 168, 3)), "Powered rotation acceleration 1").
Assert((GETPOWEREDROTATIONACC(13.6,SHIP:DRYMASS, 168, 3) < 10), "Powered rotation acceleration 2").
Assert((GETPOWEREDROTATIONACC(13.6,SHIP:DRYMASS, 168, 3) > 0.5), "Powered rotation acceleration 3").
PRINT "ROTATION TIME WET " + GETPOWEREDONEEIGHTYTURNTIME(13.6,SHIP:WETMASS, 168, 3).
PRINT "ROTATION TIME DRY " + GETPOWEREDONEEIGHTYTURNTIME(13.6,SHIP:DRYMASS, 168, 3).
Assert((GETPOWEREDONEEIGHTYTURNTIME(13.6,SHIP:DRYMASS, 168, 3) < 5), "Powered rotation time 1").
Assert((GETPOWEREDONEEIGHTYTURNTIME(13.6,SHIP:DRYMASS, 168, 3) > 1), "Powered rotation time 2").
Assert((GETPOWEREDONEEIGHTYTURNTIME(13.6,SHIP:DRYMASS, 168, 3) < GETPOWEREDONEEIGHTYTURNTIME(13.6,SHIP:WETMASS, 168, 3)), "Powered rotation time 3").

Assert((GETDISPLACEMENT(1,2,1)=4), "Displacement calculation").

WAIT 1.

SET DV TO (260*GETGATALT(0))*LN(SHIP:MASS/SHIP:DRYMASS).
PRINT "DV0 : " + DV AT (0,30).
LOG "DV0 " + DV TO "mylog".
SET DOTEST TO true.
IF (DOTEST){
LOCK STEERING TO HEADING(-90,85).
LOCK THROTTLE TO 1.
WAIT 60.
LOCK STEERING TO HEADING(90,85).
LOCK THROTTLE TO 1.
WAIT 20.
LOCK THROTTLE TO 0.
UNTIL (SHIP:VERTICALSPEED < -1.0)
{
	LOCK STEERING TO UP.
	WAIT 1.
}.
LOCK THROTTLE TO 0.001.
LOCK STEERING TO RETROGRADE.
WAIT 1.
LOCK THROTTLE TO 0.

GLIDE().
}.

SET Cd TO 0.7/1000.
SET CURV TO GETCURVEDDIST(2500, 100000). 
PRINT SHIP:MAXTHRUST*1000.
PRINT SHIP:MASS*1000.
SET BURNTIME TO (50)/(((SHIP:MAXTHRUST*1000)/(SHIP:MASS*1000))-9.8).


PRINT "BURNTIME " + BURNTIME.
PRINT "G's " + ((SHIP:MAXTHRUST*1000)/(SHIP:MASS*1000))/GETGATALT(0).
LOG "START G " + ((SHIP:MAXTHRUST*1000)/(SHIP:MASS*1000))/GETGATALT(0) TO "mylog".



WAIT 4.
PRINT CURV.
PRINT GETSTRAIGHTDIST(CURV, 100000).
//PRINT GETEULERBALLX(90000, 0, 4400,0, Cd).
SET TRAJTEST TO TRAJECTORYSTEP(1000,340,0,1).
PRINT "TRAJ STEP: ALT " + TRAJTEST[0] + " X " + TRAJTEST[1] + " H " + TRAJTEST[2] + " V " + TRAJTEST[3].
SET TRAJ4TEST TO RK4STEP(1000,340,0,1).
PRINT "TRAJ4 STEP: ALT " + TRAJ4TEST[0] + " X " + TRAJ4TEST[1] + " H " + TRAJ4TEST[2] + " V " + TRAJ4TEST[3].
//PRINT "EULER: " + GETEULERBALLX(1000, 0, 340,0, Cd).
//PRINT "RK4: " + GETRK4BALLX(1000, 0, 340,0, Cd).
//PRINT "NASA: " + GETBALLISTICX(1000, 340, 10, Cd).
//PRINT "EULER: " + GETEULERBALLX(100000, 0, GETSTRAIGHTDIST(2400, 100000),0, Cd).
//PRINT "RK4: " + GETRK4BALLX(100000, 0, GETSTRAIGHTDIST(2400, 100000),0, Cd).
//PRINT "NASA: " + GETBALLISTICX(100000, 3000, 10, Cd).
//PRINT GETEULERBALLX(500,0,1100,0,Cd).
//PRINT GETEULERBALLX(90000, 0, 1100,0, Cd).
//WAIT 10.
//DEORBIT(85000, GETSTRAIGHTDIST(2200, DEORBITALT)).
SET TARGETALT TO 80000.
STAGE.
ASCEONDTOORBIT().
SET DV TO (260*GETGATALT(0))*LN(SHIP:MASS/SHIP:DRYMASS).
PRINT "DVo : " + DV AT (0,34).
LOG "DVo " + DV TO "mylog".

WAIT 4.
SET DEORBITALT TO (APOAPSIS+PERIAPSIS)/2.0. // Likely deorbit altitude
SET DEORBITV TO GETSTRAIGHTDIST(SHIP:AIRSPEED, DEORBITALT).
DEORBIT(DEORBITALT, DEORBITV, 0).
GLIDE().
LAND().
PRINT "PROGRAM ENDED.".
UNTIL (FALSE) {
	WAIT 3600000.
}.

//CIRCULARIZE().


CLEARSCREEN.
PRINT "*** BALLISTIC BURN TEST ***" AT (0,0).
STAGE.
SET Cd TO 0.7/1000.
SET Vo TO 320.
SET Uo TO 200.
SET TARGETDIST TO 400000.
SET TRAJECTORYANGLE TO (ARCTAN(Vo/Uo)).//* constant:RadToDeg.
PRINT "TRAJECTORYANGLE: " + TRAJECTORYANGLE.
SET Density TO 1.225.
//lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)	
lock g to GETGATALT(altitude).
SET Vt TO SQRT((2*SHIP:MASS*g)/(Cd*Density)).
SET FALLTIMEHMS TO (Vo/g)*2.
SET UoHMS TO Uo.
LOCK CALCHORV TO COS((ARCSIN(SHIP:VERTICALSPEED/SHIP:AIRSPEED)))*SHIP:AIRSPEED.
SET ymax TO (Vt^2 / (2 * g)) * ln ((Vo^2 + Vt^2)/Vt^2).
SET NEWG TO body:mu / (ymax + body:radius)^2.
SET Vt TO SQRT((2*SHIP:MASS*NEWG)/(Cd*GETDENSITY((ALTITUDE+ymax)/2))).
SET ymax TO (Vt^2 / (2 * NEWG)) * ln ((Vo^2 + Vt^2)/Vt^2).
SET AVGG TO (g+NEWG)/2.
SET FALLTIMENEW TO (Vo/AVGG)*2.
PRINT "YMAX: " + Ymax AT (0,9).
PRINT "EST FALLTIME: " + FALLTIMENEW AT (0,1).
SET X TO ((Vt*Vt)/AVGG)*(LN(((Vt*Vt)+AVGG*UoHMS*FALLTIMENEW)/(Vt*Vt))).
PRINT "Calculated X: " + X AT (0,3).
LOCK STEERING TO HEADING(90,90).
LOCK THROTTLE TO 1.0.

SET BURNSTARTINGSPOT to SHIP:GEOPOSITION.
SET CONTINUEBURN TO 1.
SET LASTESTIMATE TO 0.
SET FINEADJUST TO 0.
UNTIL CONTINUEBURN = 0 {
	
	// We need to limit speed for the computation to have any chance to keep up
	// TODO: Figure out a smarter way that calculates throttle based on how long til
	// impactX reaches target dist.
	LOCK THROTTLEPOS TO  (Vo/1.0) / SHIP:VERTICALSPEED.
	if (THROTTLEPOS > 1)
	{
		LOCK THROTTLEPOS TO 1.
	}
	IF (FINEADJUST = 1)
	{
		LOCK THROTTLEPOS TO 0.1.
	}
	PRINT "THROTTLEPOS: " + (THROTTLEPOS) AT (0,11).
	LOCK THROTTLE TO THROTTLEPOS.

	SET BURNDISTANCE TO GETGROUNDDIST(KSC).
	SET TRAJDIST TO GETEULERBALLX(ALTITUDE,0, CALCHORV, SHIP:VERTICALSPEED, Cd)[0].
	
	// We need to compensate for slow computation.
	SET ESTDIFF TO TRAJDIST - LASTESTIMATE.
	SET LASTESTIMATE TO TRAJDIST.
	SET TOTALDIST TO BURNDISTANCE + TRAJDIST.
	IF ((TOTALDIST + (ESTDIFF*3)) > TARGETDIST * 0.9)
	{
		SET FINEADJUST TO 1.
	}
	IF ((TOTALDIST + (ESTDIFF*2)) > TARGETDIST)
	{
		LOCK THROTTLE TO 0.
		SET CONTINUEBURN TO 0.
		PRINT "FINAL IMPACT: " + (TRAJDIST) AT (0,11).
		PRINT "KSC DIST: " + (BURNDISTANCE) AT (0,12).
		PRINT "TOTAL: " + (TOTALDIST) AT (0,7).
		PRINT "ESTDIFF: " + (ESTDIFF) AT (0,8).
	}
	


	PRINTDATA().
	//LOCK THROTTLE TO 1.0.
	IF (APOAPSIS > 500)
	{
		LOCK STEERING TO HEADING(90,TRAJECTORYANGLE).
	}
	SET TRAJECTORYANGLE TO (ARCTAN(CALCHORV/SHIP:VERTICALSPEED)).
	PRINT "G: " + g AT (0,30).
	PRINT "EST DENSITY: " + GETDENSITY(ALTITUDE) AT (0,31).
	PRINT "CALC Q: " + (GETDENSITY(ALTITUDE) * 0.5 * SHIP:AIRSPEED * SHIP:AIRSPEED) AT (0,32).
	PRINT "GIVEN Qkpa: " + (SHIP:Q*constant:AtmToKpa) AT (0,33).
	PRINT "GIVEN Q: " + (SHIP:Q * 101325) AT (0,17).
	SET CALCDENS TO ((SHIP:Q*101325)/(0.5*SHIP:AIRSPEED*SHIP:AIRSPEED)).
	PRINT "CALC DENS: " + CALCDENS AT (0,34).
	SET CALCDENS2 TO ((SHIP:Q)/(0.5*SHIP:AIRSPEED*SHIP:AIRSPEED)).
	PRINT "CALC DENS2: " + CALCDENS2 AT (0,15).
	SET CALCDENS3 TO (((GETDENSITY(ALTITUDE) * 0.5 * SHIP:AIRSPEED * SHIP:AIRSPEED))/(0.5*SHIP:AIRSPEED*SHIP:AIRSPEED)).
	PRINT "CALC DENS3: " + CALCDENS3 AT (0,16).
	PRINT "AIRSPEED: " + SHIP:AIRSPEED AT (0,37).
	
	
	
	RCS ON.
}
LOCK THROTTLE TO 0.
LOCK STEERING TO PROGRADE.
wait 1.
PRINT "ACTAUL Uo: " + CALCHORV AT (0,13).
PRINT "ACTUAL Vo: " + SHIP:VERTICALSPEED AT (0,14).
SET NEWDENSITY TO Density.
//(0.898+0.642)/2.
//SET NEWVt TO SQRT((2*SHIP:MASS*g)/(Cd*GETDENSITY((ALTITUDE+(ALTITUDE+ymax))/2))).
SET NEWVT TO 1.
SET FALLTIMENEW TO ((SHIP:VERTICALSPEED)/g)*2.
SET XNEW TO ((NEWVt*NEWVt)/g)*(LN(((NEWVt*NEWVt)+g*CALCHORV*FALLTIMENEW)/(NEWVt*NEWVt))).
SET XNEW TO GETBALLISTICX(ALTITUDE,CALCHORV, SHIP:VERTICALSPEED, Cd).
//PRINT "NEW ESTIMATE: " + XNEW AT (0,4).
PRINT "NEW FALLTIME: " + FALLTIMENEW AT (0,5).
PRINT "NEWER ESTIMATE: " + GETEULERBALLX(ALTITUDE,ALTITUDE, CALCHORV, SHIP:VERTICALSPEED, Cd)[0] AT (0,4).
PRINT "NEWER IMPACT: " + GETEULERBALLX(ALTITUDE,0, CALCHORV, SHIP:VERTICALSPEED, Cd)[0] AT (0,6).

SET YMAXNEW TO (NEWVt^2 / (2 * g)) * ln ((SHIP:VERTICALSPEED^2 + NEWVt^2)/NEWVt^2).
PRINT "NEW YMAX: " + (YMAXNEW + ALTITUDE) AT (0,10).


UNTIL (FALSE)
{
	PRINTDATA().
	// Gliding test
	IF (SHIP:VERTICALSPEED < 0)
	{
		SET BURNDISTANCE TO GETGROUNDDIST(KSC).
		SET TRAJDIST TO GETEULERBALLX(ALTITUDE,0, CALCHORV, SHIP:VERTICALSPEED, Cd)[0].
		
		// We need to compensate for slow computation.
		SET ESTDIFF TO TRAJDIST - LASTESTIMATE.
		SET LASTESTIMATE TO TRAJDIST.
		SET TOTALDIST TO BURNDISTANCE + TRAJDIST.
		IF ((TOTALDIST + (ESTDIFF*3)) > TARGETDIST * 0.9)
		{
			SET FINEADJUST TO 1.
		}
		SET IMPACTERROR TO (TOTALDIST + (ESTDIFF*2)) - TARGETDIST.
		PRINT "IMPACTERROR: " + IMPACTERROR AT (20,2).

		IF (IMPACTERROR < -100)
		{
			// Try to glide further
			LOCK STEERING TO HEADING(90,5).
		} ELSE IF (IMPACTERROR > 100)
		{
			// Try to glide down
			LOCK STEERING TO HEADING(90,-90).
		} ELSE {
			LOCK STEERING TO PROGRADE.
		}
		
	}
}.

SET STARTINGALT TO ALTITUDE.
SET STARTINGSPOT to SHIP:GEOPOSITION.
SET STARTTIME TO TIME:SECONDS.
SET STARTHORV TO CALCHORV.
SET STARTVERV TO SHIP:VERTICALSPEED.
SET MAXALT TO 0.
UNTIL (ALTITUDE < STARTINGALT)
{
	PRINTDATA().
	PRINT "G: " + g AT (0,30).
	RCS OFF.
	IF (MAXALT < ALTITUDE)
	{
		SET MAXALT TO ALTITUDE.
	}
}
BRAKES ON.
RCS ON.
SET REALDISTANCE TO STARTINGSPOT:DISTANCE.
PRINT "REAL DISTANCE: " + REALDISTANCE AT (0,6).
SET REALTIME TO (TIME:SECONDS - STARTTIME).
PRINT "REAL TIME: " + REALTIME AT (0,7).
PRINT "REAL MAXY: " + MAXALT AT (0,8).
if (FALSE) {
SET TARGETALT TO 100.
//LOCK STEERING TO UP.
//LOCK THROTTLE TO 1.0.
wait 5.
// LOCK STEERING TO RETROGRADE.
UNTIL (XNEW > REALDISTANCE)
{
	PRINT "CALCULCATING NEW Cd..." + Cd AT (0,15).
	PRINT "NEWX: " + XNEW AT (0,16).
	
	SET Cd TO Cd - 0.0001.
	IF (Cd < 0.0002) { BREAK. }.
	SET PEAKG TO body:mu / (MAXALT + body:radius)^2.

	SET AVGG TO (PEAKG+NEWG)/2.
	SET NEWVt TO SQRT((2*SHIP:MASS*g)/(Cd*GETDENSITY((ALTITUDE+(ALTITUDE+MAXALT))/2))).
	SET FALLTIMENEW TO ((STARTVERV)/AVGG)*2.
	SET XNEW TO ((NEWVt*NEWVt)/AVGG)*(LN(((NEWVt*NEWVt)+AVGG*STARTHORV*FALLTIMENEW)/(NEWVt*NEWVt))).
	IF (SHIP:VERTICALSPEED < 1.0)
	{
		LOCK TWR TO ((SHIP:MAXTHRUST*1000)/((SHIP:MASS*1000)*g)).
		//LOCK THROTTLE TO (1.0/TWR) - SHIP:VERTICALSPEED.
	}
	IF (SHIP:GROUNDSPEED < 5.0)
	{
		//LOCK STEERING TO HEADING(90,90).
	}
}

UNTIL (FALSE)
{
	PRINTDATA().
	IF (SHIP:VERTICALSPEED < -1.0)
	{
		LOCK TWR TO ((SHIP:MAXTHRUST*1000)/((SHIP:MASS*1000)*g)).
		//LOCK THROTTLE TO (1.0/TWR) - (SHIP:VERTICALSPEED+(ALT:RADAR/10)).
	}
	IF (SHIP:GROUNDSPEED < 5.0)
	{
		//LOCK STEERING TO HEADING(90,90).
	}
}
}.