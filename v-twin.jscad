function getParameterDefinitions() {
	return [{
		type: 'choice',
		name: 'fn',
		caption: 'Resolution',
		initial: 24,
		values: [24, 40, 90],
		captions: ['Low', 'Medium', 'High'],
	}, {
		type: 'float',
		name: 'tolerance',
		caption: 'Part Tolerance',
		initial: 0.5,
	}, {
		type: 'float',
		name: 'size',
		caption: 'Motor Screw Distance',
		initial: 31,
	}, {
		type: 'float',
		name: 'mount',
		caption: 'Motor Screw Diameter',
		initial: 6.15,
	}, {
		type: 'float',
		name: 'crank',
		caption: 'Crankshaft Length',
		initial: 5,
	}, {
		type: 'float',
		name: 'rod',
		caption: 'Connecting Rod Length',
		initial: 15,
	}, {
		type: 'choice',
		name: 'part',
		caption: 'Part',
		initial: 'seperated',
		values: [
			'crank',
			'rod',
			'piston',
			'mount',
			'block',
			'exploded',
			'combined',
			'seperate'
		],
		captions: [
			'Crankshaft',
			'Connecting Rod',
			'Piston',
			'Engine Mount',
			'Engine Block',
			'Exploded View',
			'All Combined',
			'All Seperated'
		],
	}];
}
function r2d(radians) { return radians * 180 / Math.PI; }
function d2r(degrees) { return degrees * Math.PI / 180; }

function pin(args) {
	return union(
		cylinder({r: args.pin, h: 5, fn: args.fn}),
		translate([0, 0, 5], // upper cone
			cylinder({
				r1: args.pin + 0.5,
				r2: args.pin,
				h: 0.5,
				fn: args.fn
			})
		),
		translate([0, 0, 4.5], // lower cone
			cylinder({
				r1: args.pin,
				r2: args.pin + 0.5,
				h: 0.5,
				fn: args.fn
			})
		)
	);
}

function crank(args) {
	return union(
		pin(args),
		cube({size: [8, args.crank, 2], center: [1, 0, 0]}), // Middle filler
		cylinder({r: 4, h: 2, fn: args.fn}), // Lower circle
		translate([0, args.crank, 0],
			cylinder({r: 4, h: 2, fn: args.fn}) // Upper circle
		)
	);
}

function spacer(args) {
	return cylinder({r: 4, h: 2, fn: args.fn}); // crankshaft spacer
}

function rod(args) {
	var n = args.internal ? 3 : 1;
	var ring = difference(
		cylinder({r: args.pin+args.tolHalf+1, h: 2, fn: args.fn}),
		cylinder({r: args.pin+args.tolHalf, h: 2, fn: args.fn}),
		cube({
			size: [args.tolerance*n, args.pin+args.tolerance+1, 2],
			center: [1, 0, 0]
		})
	);

	return union(
		difference(
			union(
				rotate(180, [0,0,1], ring), // Half height ring
				translate([0, args.pin+args.tolHalf, 0],
					cube({ // Middle bar
						size: [2, args.rod-args.pin*2-args.tolerance, 2],
						center: [1, 0, 0]
					})
				)
			),
			translate([0, 0, 1],
				// Half height cutter
				cube({
					size: [
						args.pin*2+2+args.tolerance,
						args.pin*2+2+args.tolerance*2,
						2
					],
					center: [1, 1, 0]
				})
			)
		),
		translate([0, args.rod, 0], ring) // Full height ring
	);
}

function piston(args) {
	var a = (12-args.tolerance*2) / Math.SQRT2;
	var p = difference(
		translate([0, 0, 1],
			rotate(45, [0, 1, 0],
				cube({size: [a, 10, a], center: true}) // main piston body
			)
		),
		translate([0, 0, 2],
			cube({size: [12, 10, 10], center: [1, 1, 0]}) // flatten top
		),
		cube({size: [12, 10, -10], center: [1, 1, 0]}) // flatten bottom
	);
	if (args.internal) {
		a = 10;
		p = difference(
			p,
			cylinder({r: 2.5+args.tolerance*2, h: 2, fn: args.fn}),
			rotate(a, [0,0,1], // right side angled cutout
				cube({size: [4+args.tolerance*4, -10, 2], center: [1, 0, 0]})
			),
			rotate(-a, [0,0,1], // left side angled cutout
				cube({size: [4+args.tolerance*4, -10, 2], center: [1, 0, 0]})
			)
		);
	}
	else {
		p = union(
			pin(args),
			difference(
				p,
				translate([0, -8, 0],
					cylinder({r: 5, h: 2, fn: args.fn}) // curved cutout
				)
			)
		);
	}

	return p;
}

function mount(args) {
	var d = args.mount/2;
	return union(
		difference(
			cylinder({r: args.mount, h: -1, fn: args.fn}), // outside diameter
			cylinder({r: args.mount-0.6, h: -1, fn: args.fn}) // inside diameter
		),
		translate([0, args.mount-2, 0],
			cube({size: [14, 2, 1], center: [1, 0, 0]}) // upper crossmember
		),
		translate([0, -args.mount+2, 0],
			cube({size: [14, -2, 1], center: [1, 0, 0]}) // lower crossmember
		),
		translate([args.mount-1, 0, 0],
			cube({size: [1, args.mount, 0.5], center: [0, 1, 0]}) // right support
		),
		translate([-args.mount+1, 0, 0],
			cube({size: [-1, args.mount, 0.5], center: [0, 1, 0]}) // left support
		)
	);
}

function mounts(args) {
	var s = args.size / 2;
	var tab = mount(args);

	return union(
		translate([s, s, 0],
			rotate(-45, [0, 0, 1], tab) // right mount
		),
		translate([-s, s, 0],
			rotate(45, [0, 0, 1], tab) // left mount
		)
	);
}

function block(args) {
	var a = 12 / Math.SQRT2;
	var outline = cube({
		size: [14, args.crank+args.rod+8, 4],
		center: [1, 0, 0]}
	);
	var cutout = union(
		cube({size: [10, args.crank+args.rod+6, 4], center: [1, 0, 0]}),
		translate([0, 0, 3],
			rotate(45, [0, 1, 0],
				cube({size: [a, args.crank+args.rod+6, a], center: [1, 0, 1]})
			)
		)
	);

	return union(
		difference(
			union(
				rotate(-45, [0, 0, 1], outline),
				rotate(45, [0, 0, 1], outline),
				cylinder({r: args.crank+7, h: 4, fn: args.fn})
			),
			rotate(-45, [0, 0, 1], cutout),
			rotate(45, [0, 0, 1], cutout),
			cylinder({r: args.crank+5, h: 4, fn: args.fn})
		),
		mounts(args)
	);
}

function combined(args) {
	var l = args.part == 'exploded' ? 8 : 0;
	var Rod = rod(args);
	var Piston = piston(args);
	var A = 45 - r2d(Math.asin(args.crank * Math.sin(d2r(135)) / args.rod));
	var h = args.internal ? 0 : 2;
	var model = union(
		translate([0, -args.crank, 2+l*4],
				rotate(-A, [0, 0, 1],
					translate([0, args.rod, 0],
						rotate(-45+A, [0, 0, 1], Piston) // right piston
					)
				),
				rotate(A, [0, 0, 1],
					translate([0, args.rod, 0],
						rotate(45-A, [0, 0, 1], Piston) // left piston
					)
				)
		),
		translate([0, -args.crank, h+l*2],
			union(
				crank(args), // crankshaft
				rotate(-A, [0, 0, 1], // right connecting rod
					translate([0, 0, 2+l*4+args.tolHalf], Rod)
				),
				rotate(A, [0, 0, 1], // left connecting rod
					translate([0, 0, 4+l*4+args.tolerance],
						rotate(180, [0, 1, 0], Rod)
					)
				)
			)
		),
		translate([0, 0, -l],
			block(args) // engine block
			//cylinder({r: 4, h: 2, fn: args.fn}) // magnet
		),
		translate([0, 0, l],
			cylinder({r: 4, h: 2, fn: args.fn}) // crankshaft spacer
		)
	);
	if (args.part == 'exploded') {
		return translate([0, 0, args.size],
			rotate([90, 0, 0],
				translate([0, 0, -l*3],
					model
				)
			)
		);
	}
	return model;
}

function seperate(args) {
	var Rod = rod(args);
	var Piston = piston(args);
	return union(
		translate([0,0,4], rotate(180, [0,1,0], block(args))), // engine block
		translate([0, -args.crank/2, 0], crank(args)), // crankshaft
		translate([args.crank+20, -5, 0], Piston), // right piston
		translate([-args.crank-20, -5, 0], Piston), // left piston
		translate([args.crank+20, -args.rod-15, 0], Rod), // right connecting rod
		translate([-args.crank-20, -args.rod-15, 0], Rod), // left connecting rod
		translate([0, args.crank+15, 0],
			cylinder({r: 4, h: 2, fn: args.fn}) // crankshaft spacer
		)
	);
}

var parts = {
	'crank': crank,
	'rod': rod,
	'piston': piston,
	'mount': mount,
	'block': block,
	'combined': combined,
	'exploded': combined,
	'seperate': seperate
};

function main(args) {
	args.pin = 2; // Pin Radius
	args.mount /= 2; // Motor Mount Radius
	args.tolHalf = args.tolerance / 2;

	if (args.crank > args.size/2-1) {
		args.crank = args.size/2-1;
	}

	if (args.rod < args.crank+10) {
		args.rod = args.crank+10;
	}

	if (parts[args.part]) {
		return parts[args.part](args);
	}

	return combined(args);
}
