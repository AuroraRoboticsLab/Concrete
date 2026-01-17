/*
Flexure wire clip for telespar-style perforated tubing.
Holds wires up to 3/8" via push-in clip. 

Dr. Orion Lawlor, lawlor@alaska.edu, 2025-12-15 (Public Domain)
*/
$fs=0.1; $fa=2;

inch=25.4; // file units are mm

wall=1.6; // The shape is mostly this thick

wirehole=3/8*inch; // inside size of hole for wires

wireDX=15; // centerline +-

// Put children at wire holes
module wirehole_centers() {
    for(dx=[-1,+1]) translate([dx*wireDX,wirehole/2+wall]) children();
}

clipDX=0.430*inch; // size of holes in telespar
clipDY=0.1*inch; // distance of center of clip
clipthick=0.125*inch+0.3; // wall thickness of tubing (plus clearance)
clipspring=1.5; // spring-out distance

clipZ=4.0; // Z thickness


// Outside of spring clip shape
module springclip(enlarge=0) {
    translate([0,0])
    {
        hull() for (dy=[-1,+1]) translate([0,dy*clipDY]) circle(d=clipDX+2*enlarge);
        
        offset(r=+enlarge)
        translate([0,-clipthick])
        hull() {
            dy=1.0;
            translate([0,-dy/2]) square([clipDX+2*clipspring,dy],center=true);
            translate([0,-clipDX/2]) square([2*clipspring,0.01],center=true);
            
        }
        translate([0,-clipthick-clipDX/2])
            if (enlarge<0) // fully open between prongs
                square([3*clipspring,clipDX],center=true);
    }
}

// 2D shape of wire clip
module wireclip2D() {
    round=0.75*wall;
    offset(r=-round) offset(r=+round)
    difference() {
        union() {
            difference() {
                union() {
                    // Outside of wire clips
                    wirehole_centers() circle(d=wirehole+2*wall);
                    
                    // Bottom plate
                    translate([0,+wall/2]) square([2*wireDX,wall],center=true);
                }
                wirehole_centers() circle(d=wirehole);
                // Space to slide in wires
                translate([0,+wirehole/4+wall]) square([2*wireDX,wirehole/2],center=true);
                translate([0,+wirehole*3/4-0.1+wall]) square([2*(wireDX-wirehole/2-wall),wirehole],center=true);
            }
            springclip(0);
        }
        springclip(-1.4*wall);
    }
}

// 3D shape of wire clip
module wireclip3D() {
    difference() {
        linear_extrude(height=clipZ,convexity=4,center=true) wireclip2D();
        
        // Round the edge of inside of clip
        translate([0,-clipthick/2,0])
        difference() {
            cube([100,clipthick,100],center=true);
            rotate([90,0,0]) cylinder(d=clipDX,h=50,center=true);
        }
    }
}

wireclip3D();


