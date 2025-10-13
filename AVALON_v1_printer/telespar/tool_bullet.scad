/*
 Bullet-shaped hook for the print head to pick up tools 
 that have 2" telespar-style punched pipe.

 Shaped like a big square bullet, with a rounded coarse align taper on top.
 
 Gravity retains most tools, some will require an additional retaining pin.  
 
 Dr. Orion Lawlor and Dylan Frick, lawlor@alaska.edu, 2025-10-04 (Public Domain)
*/

include <AuroraSCAD/bevel.scad>

$fs=0.1; $fa=2;

inch=25.4;

bsparOD = 2.0*inch;
sparID = bsparOD-2*0.105*inch-0.3; // final alignment size (plus clearance)
sparIR=sparID/2; // inside radius across spar interior

bulletTR = 50.0; // radius of ogive along top of bullet
bulletR = 8.0; // rounding radius on corners
bulletHZ = 75.0; // hold-on height of bullet, up to start of rounded ogive

finalR=0.5; // final approach clearance on each side
finalZ=bulletHZ-10; // height of final taper

/* 2D cross section of bullet */
module bullet2D() {
    hull() {
        // Bottom
        translate([-sparIR,0]) square([2*sparIR,0.1]);
        // Top flush
        translate([-sparIR,finalZ]) square([2*sparIR,0.1]);
        
        // Top inset with final approach taper
        translate([-sparIR+finalR,bulletHZ]) square([2*sparIR-2*finalR,0.1]);
        
        // Rotate a series of circles to make tapered entrance
        translate([0,bulletHZ]) {
            for (side=[-1,+1]) scale([side,1])
            for (a=[0:5:45]) 
                translate([+sparIR-finalR-bulletTR,0])
                rotate([0,0,a])
                translate([+bulletTR-bulletR,0])
                    circle(r=bulletR);
        }
    }
}

/* Flat test piece */
module bullet_flat() 
{
    linear_extrude(height=1.5)
    {
        wall=5;
        difference() {    
            bullet2D();
            offset(r=+wall) offset(r=-wall)
            difference() {
                offset(r=-wall) bullet2D();
                translate([0,bulletHZ]) square([bsparOD,wall],center=true);
            }
        }
        base=3;
        translate([-sparIR-base,-base]) square([2*sparIR+2*base,base]);
    }
}

/* 3D bullet shape, facing in +Y direction.
   Print this flat, so layer lines run along slide direction. */
module bullet3D() {
    sq2 = sqrt(2.0);
    intersection() {
        hull() 
        {
            // Rounded sides
            for (sides=[0:90:360-1]) rotate([0,sides,0])
            {
                // Bottom sides
                for (y=[0,finalZ]) translate([0,y])
                    translate([1,0,1]*(sparIR-bulletR))
                        rotate([90,0,0]) cylinder(r=bulletR,h=0.01);
                
                // Rotate a series of spheres to make tapered entrance
                translate([0,bulletHZ]) {
                    for (a=[0:5:45]) 
                        rotate([0,45,0])
                        translate([1,0,0]*(+sparIR-finalR-bulletTR)*sq2)
                        rotate([0,0,a])
                        translate([1,0,0]*(+bulletTR-bulletR)*sq2)
                            sphere(r=bulletR);
                }
            }
        }
        
        // Slots to let interior bolt heads slide through
        boltheadOD = 9/16*inch/cos(30)+2;
        boltheadZ = 0.25*inch+1;
        round=3;
        rotate([-90,0,0]) linear_extrude(height=2*bulletHZ,convexity=4) 
        offset(r=+round) offset(r=-2*round) offset(r=+round)
        difference() {
            square((2*sparIR+0.01)*[1,1],center=true); // outside of bullet
            translate([0,sparIR])
                square([boltheadOD,2*boltheadZ  ],center=true);
        }
    }
}

/* Crossbolt holes for retaining perf pipe.  Needs to-be-designed retaining pin. */
module bullet_crossholes(d=3/8*inch+0.5,start=0.5*inch,n=3)
{
    for (angle=[0,90]) rotate([0,angle,0])
        for (i=[0:n-1]) translate([0,start+i*1*inch,0])
            cylinder(d=d,h=2.5*inch,center=true);
}

/* Full bullet */
module bullet_holder(coreOD=3/8*inch,crossholes=1)
{
    difference() {
        union() {
            bullet3D();
            children();
        }
        if (crossholes) bullet_crossholes();
        
        // 3/8 rod up the center (for stiffening, optional)
        translate([0,-0.1,0]) rotate([-90,0,0]) 
            bevelcylinder(d=coreOD,bevel=0.15*coreOD,h=bulletHZ + 1.0*inch);
    }
}


if (is_undef(entire) && is_undef(includebullet)) { // show the part
    bullet_holder();
}


