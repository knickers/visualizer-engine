// Number, and angle, of cylinders
CONFIGURATION = 2; // [1:1 Cylinder, 2:2 Cylinders (V), 20:2 Cylinders (Flat), 3:3 Cylinders, 4:4 Cylinders]

// Distance between the stepper motor screws
MOTOR_SIZE = 31; // [20:0.1:50]

// Diameter inside the motor screw holes
MOUNTING_TAB_SIZE = 6.15; // [4.5:0.01:7.5]

// Tolerance between moving parts
TOLERANCE = 0.3; // [0.1:0.05:0.5]

// Parts layout
VIEW = "Printing"; // [Printing, Combined, Exploded]

/* [Propeller] */

ENABLE_PROPELLER = 0; // [0:No, 1:Yes]
PROPELLER_BLADES = 2; // [1:1:8]
PROPELLER_DIRECTION = 1; // [1:Clockwise, -1:Counter Clockwise]

$fa = $preview ? 15 : 0.1;
$fs = $preview ? 1.25 : 0.6;    // Curve resolution
PIN     = 2 + 0;                 // Pin radius
WALL    = 2 + 0;                 // Wall thickness
MOUNT   = MOUNTING_TAB_SIZE / 2; // Motor mount tab radius
SQRT2   = sqrt(2);               // Square root of 2
TOLHALF = TOLERANCE / 2;         // Half of the part tolerance
CRANK   = MOTOR_SIZE / 6;        // Crankshaft length
ROD     = MOTOR_SIZE / 2;        // Connecting rod length
PISTON  = MOTOR_SIZE / 3.1;      // Piston size
SLEEVE  = CRANK+ROD+PISTON/2+WALL+1;             // Cylinder length from center
CYLINDERS = CONFIGURATION == 20 ? 2 : CONFIGURATION; // Number of cylinders
CYLINDER_ANGLE = CONFIGURATION == 20 ? 180 : 90;     // Angle between cylinders
PIN_HEIGHT = CYLINDERS == 1 ? 4 : CYLINDERS+2;



if (VIEW == "Printing") {
	draw_for_printing();
}
else if (VIEW == "Combined") {
	rotate([90, 0, 0])
		draw_combined();
}
else if (VIEW == "Exploded") {
	length = 3;
	rotate([90, 0, 0])
		translate([0, 0, -length*3])
			draw_combined(length);
}



/*************************
 *  Part layout modules  *
 *************************/

module draw_for_printing() {
	translate([0,0,4])
		rotate(180, [0,1,0])
			block();

	translate([0, CRANK/2, 0])
		crank();

	translate([0, MOTOR_SIZE+PISTON, 0])
		spacer();

	y = CYLINDERS == 4 ? MOTOR_SIZE : CRANK*3;
	x = PISTON * 2;
	offset = (CYLINDERS-1) * PISTON;

	for (i = [0:CYLINDERS-1]) {
		translate([-offset + x*i, -y-PISTON, 0]) {
			piston();
			translate([0, -PISTON-ROD, 0])
				rod();
		}
	}

	if (ENABLE_PROPELLER) {
		translate([MOTOR_SIZE*2.5, 0, 0])
			propeller();
	}
}

// https://en.wikipedia.org/wiki/Piston_motion_equations#Crankshaft_geometry
function piston_height(angle) =
	CRANK * cos(angle) + sqrt(ROD*ROD - CRANK*CRANK * sin(angle)*sin(angle));

module draw_combined(explode = 0) {
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

	if (ENABLE_PROPELLER) {
		translate([0, 0, 7+PIN_HEIGHT+TOLHALF+explode*7])
			rotate([180, 0, a-90])
				propeller();
	}
}



/**************************************************
 *  Modules for building each part of the engine  *
 **************************************************/

module pin() {
	// Pin body
	cylinder(r = PIN, h = PIN_HEIGHT);

	// Upper cone
	translate([0, 0, PIN_HEIGHT+0.5])
		cylinder(r1 = PIN + 0.5, r2 = PIN, h = 0.5);

	// Lower cone
	translate([0, 0, PIN_HEIGHT])
		cylinder(r1 = PIN, r2 = PIN + 0.5, h = 0.5);
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

			if (ENABLE_PROPELLER) {
				p = PIN * 2 / SQRT2; // pin size
				translate([0, 0, PIN_HEIGHT+3])
					cube([p, p, 4], true);
			}
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
					ring(CYLINDERS == 1 ? 2 : 1);

				// Middle bar
				translate([-1, PIN+TOLERANCE+1, 0])
					cube([2, ROD-PIN*2-TOLERANCE*1.5-1, 2]);

				// Lower bar filler
				translate([-1, PIN+TOLHALF, 0])
					cube([2, 2, CYLINDERS == 1 ? 2 : 1]);
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
	s = PISTON - TOLERANCE*2;

	translate([0, 0, 1])
		difference() {
			rotate([0, 45, 0])
				cube([a, PISTON, a], true); // main piston body

			translate([0, 0, PISTON/2+1])
				cube([s, PISTON+1, PISTON], true); // flatten top

			translate([0, 0, -PISTON/2-1])
				cube([s, PISTON+1, PISTON], true); // flatten bottom
		}
}

module piston() {
	union() {
		pin();

		difference() {
			piston_body();

			// curved cutout
			translate([0, -CRANK*2+1, -1])
				cylinder(r = CRANK+1, h = 4);
		}
	}
}

module mount() {
	d = MOUNT/2;
	w = PISTON + 2*WALL;

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

module mounts() {
	s = MOTOR_SIZE / 2 * SQRT2;
	offset = (CYLINDERS-1) * CYLINDER_ANGLE/2;

	for (i = [0:CYLINDERS-1])
		rotate([0, 0, offset-i*CYLINDER_ANGLE])
			translate([0, s, 0])
				mount();
}

module sleeve_outline() {
	w = PISTON + 2*WALL;
	W = w + 2;
	a = W / SQRT2;

	if (WALL < 2)
		translate([0, SLEEVE/2, 3])
			intersection() {
				rotate([0, 45, 0])
					cube([a, SLEEVE, a], true); // piston track bulge

				cube([W, SLEEVE, 2], true); // flatten top
			}

	translate([-w/2, 0, 0])
		cube([w, SLEEVE, 4]);
}

module sleeve_cutout() {
	a = (PISTON+2) / SQRT2;

	translate([-PISTON/2, -WALL, -1])
		cube([PISTON, SLEEVE, 6]);

	translate([0, SLEEVE/2 - WALL, 3])
		rotate([0, 45, 0])
			cube([a, SLEEVE, a], true); // piston track grooves
}

module sleeve() {
	difference() {
		sleeve_outline();
		sleeve_cutout();
	}
}

module block() {
	offset = (CYLINDERS-1) * CYLINDER_ANGLE/2;
	union() {
		difference() {
			union() {
				for (i = [0:CYLINDERS-1])
					rotate([0, 0, offset-i*CYLINDER_ANGLE])
						sleeve_outline();

				// block housing outer wall
				cylinder(r = CRANK+5+WALL, h = 4);
			}

			for (i = [0:CYLINDERS-1])
				rotate([0, 0, offset-i*CYLINDER_ANGLE])
					sleeve_cutout();

			// block housing inner wall
			translate([0, 0, -1])
				cylinder(r = CRANK+5, h = 6);
		}

		mounts();
	}
}

module propeller_blade() {
	l = MOTOR_SIZE + 4; // length of propeller blade

	translate([l/2+l/10, 0, 0]) {
		linear_extrude(2) {
			hull() {
				scale([1, 0.25, 1])
					circle(d = l); // main body

				translate([-l/2-l/10, 0, 0])
					square(PROPELLER_BLADES>5 ? 1/PROPELLER_BLADES : 3, true);

				translate([l/2-l/40, -l/15*PROPELLER_DIRECTION, 0])
					circle(d = l/20); // wingtip
			}
		}
	}
}

module propeller() {
	p = (PIN * 2 + TOLHALF) / SQRT2; // pin size
	a = 360 / PROPELLER_BLADES;
	s = PIN*2+TOLERANCE*2; // pin slot extension size

	difference() {
		union() {
			cylinder(d = 8, h = 2); // center hub

			for (i = [0:PROPELLER_BLADES-1]) {
				rotate(a*i, [0,0,1])
					propeller_blade();
			}

			translate([CRANK-s/2, -s/2, 0])
				cube([s, s, 4]); // pin slot extension
		}

		translate([CRANK, 0, 2])
			cube([p+0.1, p+0.1, 6], true); // pin slot
	}
}
