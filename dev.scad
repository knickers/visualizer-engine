include <engine.scad>;

// https://en.wikipedia.org/wiki/Piston_motion_equations#Crankshaft_geometry
function piston_height(angle) =
	CRANK * cos(angle) + sqrt(ROD*ROD - CRANK*CRANK * sin(angle)*sin(angle));

module combined(explode = 0) {
	a = $t * 360 + 90;           // angle of the crankshaft
	z = 4 + explode*6 + TOLHALF; // base z height of connecting rods
	nudge = 45;
	offset = (CYLINDERS-1) * (CYLINDER_ANGLE/2) - nudge;

	color("LightGrey")
	translate([0, 0, -explode])
		rotate([0, 0, offset])
			block();

	color("SlateGrey")
	translate([0, 0, explode])
		rotate([0, 0, a])
			spacer();

	color("SlateGrey")
	translate([0, 0, 2+explode*2])
		rotate([0, 0, a])
			crank();

	for (i = [0:CYLINDERS-1]) {
		A = -i*CYLINDER_ANGLE + nudge; // angle of this piston sleeve iteration
		O = i % 2;                     // is this an odd iteration?

		color("SlateGrey")
		rotate([0, 0, -A])
			translate([0, piston_height(abs(180-A-a)), 2+explode*4])
				piston();

		color("LightGrey")
		translate([sin(a)*CRANK, -cos(a)*CRANK, i*(1+TOLHALF/2) + z])
			rotate([0, 0, asin(sin(a+A)*CRANK/ROD)-A]) {
				if (O || (CYLINDERS==3 && i==2)) {
					rotate([0, 180, 0])
						translate([0, 0, -1])
							rod();
				}
				else {
					rod();
				}
			}
	}

	if (PROPELLER) {
		translate([0, 0, 7+PIN_HEIGHT+TOLHALF])
			rotate([180, 0, a-90])
				propeller();
	}
}

module exploded(explode) {
	translate([0, 0, MOTOR_SIZE])
		rotate([90, 0, 0])
			translate([0, 0, -explode*3])
				combined(explode);
}

/*
crank();
rod();
piston();
mount();
sleeve();
block();
propeller();
combined();
exploded(5);
*/
rotate([90, 0, 0])
combined();
