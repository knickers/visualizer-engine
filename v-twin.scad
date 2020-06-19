// Distance between the stepper motor screws in millimeters
MOTOR_SIZE = 31; // [20:0.1:50]

// Diameter in millimeters inside the motor screw holes
MOUNTING_TAB_SIZE = 6.15; // [4.5:0.01:7.5]

// Tolerance between moving parts
TOLERANCE = 0.3; // [0.1:0.05:0.5]


$fn     = 24 + 0;                // Curve resolution
PIN     = 2 + 0;                 // Pin radius
MOUNT   = MOUNTING_TAB_SIZE / 2; // Motor mount tab radius
TOLHALF = TOLERANCE / 2;         // Half of the part tolerance
SQRT2   = sqrt(2);               // Square root of 2
CRANK   = MOTOR_SIZE / 6;        // Crankshaft Length
ROD     = MOTOR_SIZE / 2;        // Connecting Rod Length
PISTON  = MOTOR_SIZE / 3;        // Piston size

module pin() {
	union() {
		// Pin body
		cylinder(r = PIN, h = 4);

		// Upper cone
		translate([0, 0, 4.5])
			cylinder(r1 = PIN + 0.5, r2 = PIN, h = 0.5);

		// Lower cone
		translate([0, 0, 4])
			cylinder(r1 = PIN, r2 = PIN + 0.5, h = 0.5);
	}
}

module crank() {
	translate([0, -CRANK, 0])
		union() {
			pin();

			// Middle filler
			translate([-4, 0, 0])
				cube([8, CRANK, 2]);

			// Lower circle
			cylinder(r = 4, h = 2);

			// Upper circle
			translate([0, CRANK, 0])
				cylinder(r = 4, h = 2);
		}
}

module spacer() {
	cylinder(r = 4, h = 2); // crankshaft spacer
}

// Connecting rod ring with a split for flexing over the pin head
module ring(height) {
	difference() {
		cylinder(r = PIN+TOLHALF+1, h = height);
		translate([0, 0, -1])
			cylinder(r = PIN+TOLHALF, h = height+2);
		translate([-TOLERANCE/2, 0, -1])
			cube([TOLERANCE, PIN+TOLERANCE+1, height+2]);
	}
}

module rod() {
	union() {
		difference() {
			union() {
				// Half height ring
				rotate([0, 0, 180])
					ring(1);

				// Middle bar
				translate([-1, PIN+TOLERANCE+1, 0])
					cube([2, ROD-PIN*2-TOLERANCE*1.5-1, 2]);

				// Lower bar filler
				translate([-1, PIN+TOLHALF, 0])
					cube([2, 2, 1]);
			}
		}

		// Full height ring
		translate([0, ROD, 0])
			ring(2);
	}
}

module piston_body() {
	w = PISTON + 2;
	a = (w-TOLERANCE*2) / SQRT2;

	translate([0, 0, 1])
		intersection() {
			rotate([0, 45, 0])
				cube([a, PISTON, a], true); // main piston body

			cube([w, PISTON, 2], true); // flatten top and bottom
		}
}

module piston() {
	union() {
		pin();

		difference() {
			piston_body();

			// curved cutout
			translate([0, -CRANK*2+1, -1])
				cylinder(r = CRANK+1, h = 4, $fn = PISTON/10*$fn);
		}
	}
}

module mount() {
	d = MOUNT/2;
	w = PISTON+4;

	union() {
		translate([0, 0, -1])
			difference() {
				cylinder(r = MOUNT, h = 1); // outside diameter
				translate([0, 0, -1])
					cylinder(r = MOUNT-0.6, h = 3); // inside diameter
			}

		// upper crossmember
		translate([-w/2, MOUNT-2, 0])
			cube([w, 2, 1]);

		// lower crossmember
		translate([-w/2, -MOUNT, 0])
			cube([w, 2, 1]);

		// right support
		translate([MOUNT-1, -MOUNT/2, 0])
			cube([1, MOUNT, 0.5]);

		// left support
		translate([-MOUNT, -MOUNT/2, 0])
			cube([1, MOUNT, 0.5]);
	}
}

module mounts() {
	s = MOTOR_SIZE / 2;

	union() {
		// right mount
		translate([s, s, 0])
			rotate([0, 0, -45])
				mount();

		// left mount
		translate([-s, s, 0])
			rotate([0, 0, 45])
				mount();
	}
}

module block_outline() {
	w = PISTON+4;
	translate([-w/2, 0, 0])
		cube([w, CRANK+ROD+PISTON/2+3, 4]);
}

module block_cutout() {
	a = (PISTON+2) / SQRT2;

	union() {
		translate([-PISTON/2, 0, -1])
			cube([PISTON, CRANK+ROD+PISTON/2+1, 6]);

		translate([0, (CRANK+ROD+PISTON/2+1) / 2, 3])
			rotate([0, 45, 0])
				cube([a, CRANK+ROD+PISTON/2+1, a], true);
	}
}

module block() {
	union() {
		difference() {
			union() {
				rotate([0, 0, -45])
					block_outline();

				rotate([0, 0, 45])
					block_outline();

				cylinder(r = CRANK+7, h = 4, $fn = $fn*2);
			}

			rotate([0, 0, -45])
				block_cutout();

			rotate([0, 0, 45])
				block_cutout();

			translate([0, 0, -1])
				cylinder(r = CRANK+5, h = 6, $fn = $fn*1.5);
		}

		mounts();
	}
}

// https://en.wikipedia.org/wiki/Piston_motion_equations#Crankshaft_geometry
function piston_height(angle) =
	CRANK * cos(angle) + sqrt(ROD*ROD - CRANK*CRANK * sin(angle)*sin(angle));

module combined(explode = 0) {
	a = (1-$t) * 360;

	// engine block
	translate([0, 0, -explode])
		block();

	// crankshaft spacer
	translate([0, 0, explode])
		rotate([0, 0, a])
			spacer();

	// crankshaft
	translate([0, 0, 2+explode*2])
		rotate([0, 0, a])
			crank();

	// right piston
	rotate([0, 0, -45])
		translate([0, piston_height(abs(a-135)), 2+explode*4])
			piston();

	// left piston
	rotate([0, 0, 45])
		translate([0, piston_height(abs(a+135)), 2+explode*4])
			piston();

	// right connecting rod
	translate([sin(a)*CRANK, -cos(a)*CRANK, 4+explode*6+TOLHALF])
		rotate([0, 0, asin(sin(a+45)*CRANK/ROD)-45])
			rod();

	// left connecting rod
	translate([sin(a)*CRANK, -cos(a)*CRANK, 6+explode*6+TOLERANCE*2/3])
		rotate([0, 180, asin(sin(a-45)*CRANK/ROD)+45])
			rod();
}

module exploded(explode) {
	translate([0, 0, MOTOR_SIZE])
		rotate([90, 0, 0])
			translate([0, 0, -explode*3])
				combined(explode);
}

module seperate() {
	translate([0,0,4]) rotate(180, [0,1,0]) block();     // engine block
	translate([0, CRANK+PISTON*2, 0]) spacer();          // crankshaft spacer
	translate([0, CRANK/2, 0]) crank();                  // crankshaft
	translate([CRANK+PISTON*2, -PISTON/2, 0]) piston();  // right piston
	translate([-CRANK-PISTON*2, -PISTON/2, 0]) piston(); // left piston
	translate([CRANK+PISTON*2, -ROD*2, 0]) rod();        // right connecting rod
	translate([-CRANK-PISTON*2, -ROD*2, 0]) rod();       // left connecting rod
}

/*
crank();
rod();
piston();
mount();
block();
combined();
exploded(5);
seperate();
*/
seperate();
