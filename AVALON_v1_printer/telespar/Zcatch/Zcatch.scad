/*
 This bracket catches the Z axis gantry:
   - Rests here when powered off
   - Reduces damage if power failure causes Z to fall and crash

Mounted onto the bottom X-direction spars.

*/
$fs=0.1; $fa=2;

inch=25.4;

holeOD=3/8*inch+0.5;
holepegZ=10;

reachZ=5*inch; // total vertical: 2 inch cross beam, then 2.7 inch roller chain path.
reachX=0.75*inch; // horizontal reach over
startX=0.125*inch; // start location (space away from crossbar)
baseX=2.5*inch; // base size

wall=2.32; // thickness of plastic (==6 profiles)
wide=0.75*inch;

middleStart = 1.25*inch; // bowed middle portion starting Z height
middleX=0.75*inch;
middleBow=0.85*inch;

// Bowed-out middle section
module middle2D(enlarge=0) {
    offset(r=+enlarge)
    hull() {
        translate([startX,middleStart])
            square([middleX-startX,reachZ-middleStart]);
        translate([startX+(middleX-startX)/2,middleStart+(reachZ-middleStart)/2])
            circle(d=middleBow);
    }
}

// 2D profile, XY -> XZ
module Zcatch2D()
{
    round=4; // round inside corners
    offset(r=-round) offset(r=+round)
    {
        difference() {
            union() {
                // Main uprights
                for (x=[startX,middleX-wall]) translate([x,0]) square([wall,reachZ]); 
                // Bowed middle
                middle2D(0);
            }
            middle2D(-wall);
        }
        
        // Reach over on tip
        translate([-reachX,reachZ-wall]) square([reachX+startX,wall]);
        // Base plate
        translate([startX,0]) square([baseX-startX,wall]);
        // Diagonal
        translate([2*inch,wall]) rotate([0,0,90+45]) square([1.8*inch,wall]);
    }
}

// 3D shape, upright and as-installed
module Zcatch3D() 
{
    backpeg=[2.0*inch,0,0];
    
    difference() {
        union() {
            rotate([90,0,0])
                linear_extrude(height=wide,center=true,convexity=4)
                    Zcatch2D();
            
            // front peg, to stop rotation
            translate([1.0*inch,0]) scale([1,1,-1]) cylinder(d=holeOD,h=holepegZ);
            
            // Back peg, for a 3" bolt
            translate(backpeg) cylinder(d1=wide,d2=holeOD+2*wall,h=0.375*inch);
        }
        translate(backpeg) cylinder(d=holeOD,h=50,center=true);
        
    }
}

Zcatch3D();




