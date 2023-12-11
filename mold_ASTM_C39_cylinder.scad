/*
 Two-part mold for casting ASTM C39 compression test samples,
 for testing the compressive strength of concrete and such.
 
 Uploaded to:
    https://www.thingiverse.com/thing:5967002
 
 Dr. Orion Lawlor, lawlor@alaska.edu, 2023-04 (Public Domain)
*/
$fs=0.1; $fa=2;

// Full-scale ASTM test cylinder:
diameter_full=150; 
height_full=300;

//scale=2/3; //<- makes a 100mm diameter cylinder
//scale=1/5; //<- makes a 30mm diameter cylinder
//scale=1/2; //<- makes a 75mm diameter cylinder
scale=1/3; //<- makes a 50mm diameter cylinder
//scale=1/6; //<- makes a 25mm diameter cylinder
//flange=15; // size of clamping flange around edges (for spring clamps)

//scale=1/12.5; //<- makes a 12mm diameter cylinder

flange=12; // size of clamping flange around edges (for bolts or spring clamps)
open_clearance=0.3; // shrink end flange this far

bolt_threadID=2.5; // M3, tap directly into plastic
bolt_threadOD=3.1; // M3 thru hole
bolt_headOD=7; // M3 socket cap diameter
bolt_boss=4; // thickness of bolt head / thread boss (== bolt length / 2)

diameter = diameter_full*scale;
height = height_full*scale;

bolt_Z = [0.25*height, 0.75*height];
bolt_X = diameter/2 + flange/2;

wall=1.5;
floor=1.5;

base_flange=3; // stop leaks out bottom
top_flange=1; // reinforce top, allow strike-off flat

fullwid=2*flange+diameter;

module C39_half(fatten=0) {
    circle(d=diameter+2*fatten);
    translate([-fullwid/2-wall,fatten,0])
        scale([1,-1,1]) 
            square([fullwid+wall-open_clearance,10]);
}

module C39_2D(extra_center=0,boss=0) {
    round=2;
    difference() {
        // Outer surface
        offset(r=-round) offset(r=+round)  {
            C39_half(wall+extra_center);
            
            if (boss)
                for (side=[-1,+1]) 
                    translate([side*bolt_X,bolt_boss/2])
                        square([wall,bolt_boss],center=true);
        }
        
        // Space for sample
        C39_half();
        
        // Wedge to pry open the set
        if (0) translate([fullwid/2-wall,0]) rotate([0,0,-45])
            square([20,20]);
        
        // Trim off bottom flat
        translate([0,-1000,0]) square([2000,2000],center=true);
    }
}

module C39_3D(boss=0) {
    difference() {
        union() {
            // main walls
            linear_extrude(height=height,convexity=6)
                C39_2D(0,boss);
            // base
            for (z=[0,1])
                translate([0,0,z*(height-floor)])
                    linear_extrude(height=floor,convexity=6)
                        hull() C39_2D(z?top_flange:base_flange);
            // taper to base
            d=diameter+2*wall;
            taper=3;
            cylinder(d1=d+2*taper,d2=d,h=taper);
            
        }
        // Clean out middle
        translate([0,0,-0.1])
            cylinder(d=diameter+0.01,h=height+1);
        translate([0,-1000,0]) cube([2000,2000,2000],center=true);
        
    }
}

module bolt_centers(sides=[-1,+1])
{
    for (s=sides) scale([s,1,1])
       for (z=bolt_Z) translate([bolt_X,0,z])
            rotate([-90,0,0]) children();
}

module C39_bolted() {
    difference() {
        union() {
            C39_3D(boss=1);
            
            // Block leaks with lip
            translate([-diameter/2-flange-wall+0.1,-wall,0])
                rotate([0,0,-5]) // <- kick out for clearance
                cube([wall,2.5*wall,height]);
            
            // Reinforce bolt centers
            bolt_centers() {
                cylinder(d1=flange-1,d2=bolt_headOD,h=bolt_boss);
                translate([-1/2,0,bolt_boss/2])
                    cube([flange-1,wall,bolt_boss],center=true);
            }
        }
        bolt_centers([+1]) cylinder(d=bolt_threadID,h=2*bolt_boss+1,center=true);
        
        bolt_centers([-1]) cylinder(d=bolt_threadOD,h=2*bolt_boss+1,center=true);
        
    }
}

module C39_endcap() {
    space=wall/2;
    capID=diameter+2*space;
    capOD=capID+2*wall;
    difference() {
        cylinder(d=capOD,h=2*floor);
        translate([0,0,floor]) cylinder(d=capID,h=100);
    }
}

C39_bolted();
translate([0,-10.1,0]) rotate([0,0,180]) C39_bolted();
/*    
for (copy=[0,1]) translate([copy*(fullwid+3),0,0])
{
    C39_3D();

    // Endcaps, seal in place with epoxy (or ice)
    if (0) translate([0,-diameter,0]) 
        C39_endcap();
}
*/
