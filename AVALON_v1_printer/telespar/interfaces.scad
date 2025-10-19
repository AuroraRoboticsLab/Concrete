/*
 Interface definitions between printed parts

 Dr. Orion Lawlor, lawlor@alaska.edu, 2025-09-29 (Public Domain)
*/

$fs=0.1; $fa=2; // smooth finish

inch=25.4; // file units are mm

sparOD=2.0*inch+0.2; // spar size (plus some clearance)
sparR=3.0; // rounding on corners

module spar2D(enlarge=0,round=1) {
    offset(r=+round*sparR+enlarge) offset(r=-round*sparR)
        square(sparOD*[1,1],center=true);
}

// Clearance for bolts on spar X axis
module spar2Dbolts(enlarge=0) {
    deep=8; // space for 3/8" bolt head
    wide=20; // space for hex, plus some clearance
    round=3;
    offset(r=+round) offset(r=-round)
    offset(r=-round) offset(r=+round)
    {
        spar2D(enlarge=enlarge);
        offset(r=+enlarge)
            square([sparOD+2*deep,wide],center=true);
    }
    
}

sparbolt=3/8*inch+0.2; // diameter of bolts going through spar
sparbolt_pitch=1/16*inch; // thread spacing of spar bolt


// Roller bearing: 3/8" ID, SCE66, https://www.amazon.com/dp/B08J3QR52C?th=1
bearingID=3/8*inch+0.4; // space for bolt
bearingOD=9/16*inch+0.25; // outside diameter of roller bearing
bearingZ=3/8*inch+0.5; // height of roller bearing along bolt


rollerR = 9/16/2*inch; // rolling radius of rollers (bare steel) on top of spar
rollerOD = 40; // clearance diameter of outside of roller flanges

// Z axis diagonal rollers:
ZrollerDX = 1.0*inch; // shift from surface of spar to surface of next spar


// Centerline of chain circuit, relative to spar mounting bolt
//   X: across spar.  Y: along spar.  Z: above spar mounting face
chainC = [-75,0,0.5*inch];

// X radius of chain centerline, measured at tips of sprockets
chain_sprocketR = 34.5579;
chain_thickness = 7.0; // thickness between chain plates
chain_retainhole = 4; // tap diameter for #10-32 machine screw
chain_retainN = 3; // number of chain retaining bolt holes
chain_retainDY = 0.5*inch; // spacing between chain holes
chain_retainHD = 5/16*inch; // roller diameter for chain

// Make a plate chain retaining structure, relative to the chain centerline.
//   Chain runs in +Y direction
//   Structure sits in -X half
//   Hulls the structure with any 2D children.
module chain_retain2D(width=0.5*inch) {
    tooth=chain_retainHD/2; // teeth stick up this far
    height=chain_retainN*chain_retainDY;
    clearance=0.1;
    offset(r=-clearance)
    difference() {
        union() {
            hull() {
                translate([-width,0])
                    square([width+tooth,height]);
                children();
            }
        }
        
        // Cut in roller holes
        for (r=[0:chain_retainN]) translate([0,r*chain_retainDY])
        hull() {
            for (xshift=[0,tooth+1]) translate([xshift,0])
                circle(d=chain_retainHD+0.1*xshift);
        }
    }
}
// Cut in 3D holes facing in +X, spaced along +Y
module chain_retain_holes(depth=0.4*inch) {
    for (r=[0.5:chain_retainN]) translate([0,r*chain_retainDY])
        rotate([0,90,0]) cylinder(d=chain_retainhole,h=2*depth,center=true);
}

// Plate that retains the chain.  Chain at origin, facing along +Y.  Plate extruded along +Z.
module chain_retain_plate3D(extraZ=0)
{
    difference() {
        linear_extrude(height=chain_thickness+extraZ,convexity=4,center=true)
            chain_retain2D()
                children();
        chain_retain_holes();
    }
}


// Load cell measures downward force on tool. 
//  Can be used as a simple scale, to detect mechanical contact, or sense tool pickup
// Example supplier: https://www.amazon.com/dp/B0CRDG24R8
loadcellSZ=[0.5*inch+0.3, 80+0.5, 0.5*inch+0.3];
loadcellBDY=7.5; // bolt delta-Y (space from center to bolts on each side)
loadcellSDY=55; // side delta-Y (space between bolt groups)




// Symmetry around X axis
module mirrorX() {
    children();
    scale([-1,1,1]) children();
}
// Symmetry around Y axis
module mirrorY() {
    children();
    scale([1,-1,1]) children();
}
// Symmetry around Z axis
module mirrorZ() {
    children();
    scale([1,1,-1]) children();
}





