// Aglet crimping anvil
//
// Parametric model of the aglet crimping anvil described on Ian's Shoelace Site:
// https://www.fieggen.com/shoelace/agletmetal.htm
//
// A block with a hole through it holds metal tubing slipped over a shoelace end,
// and a slot from the top face down into the hole guides a thin metal chisel.
// Tapping the chisel with a hammer crimps the tubing lengthwise onto the shoelace.
//
// All dimensions are in millimeters. Change the parameters in the Customizer panel
// (Window > Customizer), render with F6, then export with File > Export.

/* [Tubing hole] */

// Outer diameter of the tubing (1/8 in = 3.18, 5/32 in = 3.97, 3/16 in = 4.76).
tubing_outer_diameter = 5.0; // [1:0.01:12]

// Added to the tubing diameter to size the hole. Raise it if the tubing binds.
hole_clearance = 0.3; // [0:0.05:1]

// Size of the 45-degree chamfer at each end of the hole.
hole_entry_chamfer = 0.5; // [0:0.1:2]

/* [Chisel slot] */

// Thickness of the thin metal chisel.
chisel_thickness = 0.45; // [0.2:0.05:3]

// Added to the chisel thickness to size the slot. Raise it if the chisel binds.
slot_clearance = 0.3; // [0:0.05:1]

// Depth of the slot, from the top face down to the hole.
slot_depth = 5; // [2:0.5:40]

// Size of the 45-degree lead-in chamfer where the slot meets the top face.
slot_entry_chamfer = 0.5; // [0:0.1:2]

/* [Anvil block] */

// Length of the block along the hole. Make it at least as long as the aglet.
anvil_length = 40; // [10:1:100]

// Width of the block across the hole.
anvil_width = 30; // [10:1:100]

// Height of the block, from the bench to the top face.
anvil_height = 20; // [10:1:100]

// Size of the 45-degree chamfer on the outer edges that run along the hole.
outer_edge_chamfer = 1.0; // [0:0.25:5]

/* [Mounting flange] */

// Add a base flange with countersunk screw holes for fastening to a bench.
mounting_flange_enabled = true;

// Distance the flange extends past each side of the block.
mounting_flange_width = 14; // [6:0.5:40]

// Thickness of the flange.
mounting_flange_thickness = 5; // [2:0.5:15]

// Diameter of the screw clearance holes (4.5 fits #8 and M4 screws).
mounting_screw_diameter = 4.5; // [2:0.1:8]

// Head diameter of the flat-head screws, which sit in 90-degree countersinks.
mounting_screw_head_diameter = 9.0; // [3:0.1:16]

/* [Orientation] */

// Stand the anvil on end with the hole vertical, the strongest print orientation.
orient_for_printing = true;

/* [Hidden] */

// Hole diameter and slot width, including clearance.
hole_diameter = tubing_outer_diameter + hole_clearance;
slot_width = chisel_thickness + slot_clearance;

// Height of the hole axis above the bottom face.
hole_center_height = anvil_height - slot_depth - hole_diameter / 2;

// Material left below the hole and on each side of it.
floor_thickness = anvil_height - slot_depth - hole_diameter;
side_wall_thickness = (anvil_width - hole_diameter) / 2;

// Width of the whole part, including the flange when it is enabled.
overall_width = mounting_flange_enabled
    ? anvil_width + 2 * mounting_flange_width
    : anvil_width;

// Smallest outer dimension that a corner chamfer has to fit within.
smallest_outer_dimension = mounting_flange_enabled
    ? min(anvil_width, anvil_height, mounting_flange_thickness)
    : min(anvil_width, anvil_height);

// Distance from the center of the anvil to each mounting screw.
mounting_screw_offset = (anvil_width + mounting_flange_width) / 2;

// Depth of each screw countersink.
countersink_depth = (mounting_screw_head_diameter - mounting_screw_diameter) / 2;

// Smallest wall allowed below and beside the hole.
minimum_wall_thickness = 2;

// Smallest gap allowed between a countersink and the edges of the flange.
minimum_countersink_margin = 1;

// Overlap that keeps boolean operations free of coincident faces.
epsilon = 0.01;

// Segment count of the hole and its chamfers.
hole_fragments = 96;

// Resolution of all other curves.
$fa = 1;
$fs = 0.2;

// Parameter checks

assert(
    slot_width < hole_diameter,
    "slot_width must be smaller than hole_diameter, or the tubing is unsupported."
);
assert(
    floor_thickness >= minimum_wall_thickness,
    str(
        "Only ", floor_thickness, " mm of material is left below the hole. ",
        "Increase anvil_height or reduce slot_depth."
    )
);
assert(
    side_wall_thickness >= minimum_wall_thickness,
    "Increase anvil_width to leave material on both sides of the hole."
);
assert(
    2 * outer_edge_chamfer < smallest_outer_dimension,
    "Reduce outer_edge_chamfer so that it fits the block and the flange."
);
if (mounting_flange_enabled) {
    assert(
        mounting_screw_head_diameter > mounting_screw_diameter,
        "The screw head must be larger than the screw clearance hole."
    );
    assert(
        countersink_depth < mounting_flange_thickness,
        "Increase mounting_flange_thickness to fit the screw countersinks."
    );
    assert(
        mounting_flange_width
            >= mounting_screw_head_diameter + 2 * minimum_countersink_margin,
        "Increase mounting_flange_width to fit the screw countersinks."
    );
}

// Rectangle centered on the origin, with 45-degree chamfers on all four corners.
//
// Args:
//   size: Width and height of the rectangle, as [x, y].
//   chamfer: Leg length of each corner chamfer. Zero gives square corners.
module chamfered_rectangle(size, chamfer) {
    half_width = size[0] / 2;
    half_height = size[1] / 2;
    if (chamfer > 0) {
        polygon([
            [-half_width + chamfer, -half_height],
            [half_width - chamfer, -half_height],
            [half_width, -half_height + chamfer],
            [half_width, half_height - chamfer],
            [half_width - chamfer, half_height],
            [-half_width + chamfer, half_height],
            [-half_width, half_height - chamfer],
            [-half_width, -half_height + chamfer]
        ]);
    } else {
        square(size, center = true);
    }
}

// Outline of the block and the optional flange, before the hole and slot are cut.
module anvil_outline() {
    translate([0, anvil_height / 2])
        chamfered_rectangle([anvil_width, anvil_height], outer_edge_chamfer);
    if (mounting_flange_enabled) {
        translate([0, mounting_flange_thickness / 2])
            chamfered_rectangle(
                [overall_width, mounting_flange_thickness], outer_edge_chamfer
            );
    }
}

// Cross-section of the chisel slot, including the lead-in at the top face.
//
// The slot starts at the hole axis so that it opens fully into the hole. Below the
// top of the hole, it only overlaps material that the hole already removes.
module chisel_slot_outline() {
    lead_in_half_width = slot_width / 2 + slot_entry_chamfer + epsilon;
    translate([-slot_width / 2, hole_center_height])
        square([slot_width, anvil_height - hole_center_height + epsilon]);
    if (slot_entry_chamfer > 0) {
        polygon([
            [-lead_in_half_width, anvil_height + epsilon],
            [lead_in_half_width, anvil_height + epsilon],
            [slot_width / 2, anvil_height - slot_entry_chamfer],
            [-slot_width / 2, anvil_height - slot_entry_chamfer]
        ]);
    }
}

// Cross-section of the anvil perpendicular to the hole, with the slot cut out.
//
// X spans the width of the anvil, and Y rises from the bottom face to the top face,
// where the slot opens.
module anvil_profile() {
    difference() {
        anvil_outline();
        chisel_slot_outline();
    }
}

// Hole that holds the tubing, with a 45-degree chamfer at each end.
//
// A single solid of revolution puts the bore and its chamfers on shared vertices,
// which keeps zero-area faces out of the exported mesh.
module tubing_hole() {
    hole_radius = hole_diameter / 2;
    flared_radius = hole_radius + hole_entry_chamfer + epsilon;
    translate([0, hole_center_height, 0])
        rotate_extrude($fn = hole_fragments)
            polygon([
                [0, -epsilon],
                [flared_radius, -epsilon],
                [hole_radius, hole_entry_chamfer],
                [hole_radius, anvil_length - hole_entry_chamfer],
                [flared_radius, anvil_length + epsilon],
                [0, anvil_length + epsilon]
            ]);
}

// Countersunk screw holes through the flange, one on each side of the block.
module mounting_screw_holes() {
    for (side = [-1, 1]) {
        translate([side * mounting_screw_offset, 0, anvil_length / 2])
            rotate([-90, 0, 0]) {
                translate([0, 0, -epsilon])
                    cylinder(
                        h = mounting_flange_thickness + 2 * epsilon,
                        d = mounting_screw_diameter
                    );
                translate([0, 0, mounting_flange_thickness - countersink_depth])
                    cylinder(
                        h = countersink_depth + epsilon,
                        d1 = mounting_screw_diameter,
                        d2 = mounting_screw_head_diameter + 2 * epsilon
                    );
            }
    }
}

// The anvil, standing on one end with the hole along the Z axis.
//
// In this orientation every crimping load lies in the layer plane and the hole
// prints round, so it is also the print orientation.
module anvil() {
    difference() {
        linear_extrude(height = anvil_length) anvil_profile();
        tubing_hole();
        if (mounting_flange_enabled) mounting_screw_holes();
    }
}

if (orient_for_printing) {
    anvil();
} else {
    // Upright, as used on the bench, with the hole along the Y axis.
    translate([0, anvil_length / 2, 0])
        rotate([90, 0, 0])
            anvil();
}
