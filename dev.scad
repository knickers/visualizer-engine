include <v-twin.scad>;

// https://en.wikipedia.org/wiki/Piston_motion_equations#Crankshaft_geometry
function piston_height(angle) =
	CRANK * cos(angle) + sqrt(ROD*ROD - CRANK*CRANK * sin(angle)*sin(angle));

module combined(explode = 0) {
	a = $t * 360 + 90;           // angle of the crankshaft
	b = 4 + explode*6 + TOLHALF; // base height of connecting rods
	offset = (CYLINDERS-1) * 45;

	color("LightGrey")
	translate([0, 0, -explode])
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
		A = offset-i*90; // angle of this piston sleeve iteration
		O = i % 2;       // is this an odd iteration?

		color("SlateGrey")
		rotate([0, 0, A])
			translate([0, piston_height(abs(A+180-a)), 2+explode*4])
				piston();

		color("LightGrey")
		translate([sin(a)*CRANK, -cos(a)*CRANK, i*(1+TOLHALF/2) + b])
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
combined();
