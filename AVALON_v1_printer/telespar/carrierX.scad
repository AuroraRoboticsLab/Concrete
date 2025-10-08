/*
 This carrier holds the X axis spar above the Y axis spar.
 Two rollers help the X axis move smoothly.
 
*/
include <interfaces.scad>
include <BOSL2/std.scad>
include <BOSL2/threading.scad>


carrierXW=2.4; // minimum wall thickness of X carrier
carrierXF=2.0; // floor plate thickness
carrierEdge=0.100*inch; // space between carrier and spar, for washer to roll
carrierXZ=1.5*inch-carrierEdge; // total along-spar length of X carrier
carrierXH=0.5*inch; // distance from bottom surface up to mounting bolt hole

sparC=3; // clearance between X and Y spars

rollerboltT=5/16*inch; // tap diameter of 3/8" bolts holding rollers
rollerTW=3.2; // wall thickness around roller tap area
rollerY = -sparOD/2-sparC+rollerR; // Y centerline for roller bolts
rollerX = +sparOD/2+rollerOD/2; // X centerline for roller bolts

rollerboltOD=3/8*inch+0.2; // thru diameter of bolts holding rollers

// Make basic 2D parts of carrierX
module carrierX2Dbasic(outside=0) {
    spar2D(outside?+carrierXW:0);
    
    for (side=[-1,+1]) translate([side*rollerX,rollerY])
        circle(d=rollerboltT+outside*2*rollerTW);
}


// Make 2D shape of carrierX, for holes of this diameter.  Fully rounded
module carrierX2D(hole=rollerboltT) {
    round=0.4*hole;
    difference() {
        offset(r=-round) offset(r=+round)
        union() {
            carrierX2Dbasic(1);
            
            // Crossbar over top of roller bolts
            translate([0,rollerY + rollerboltT/2+rollerTW/2])
                square([rollerX*2,rollerTW],center=true);
            
            // Hull to grab onto bolts
            difference() {
                hull() carrierX2Dbasic(1);
                hull() carrierX2Dbasic(0);
            }
        }
        
        spar2D();
        
        if (hole>0)
        for (side=[-1,+1]) translate([side*rollerX,rollerY])
            circle(d=hole);
    }
}

// Make 3D shape of carrier
module carrierX(crossbolt=1, baseplate=1, hole=rollerboltT, height=carrierXZ)
{
    boss=0.75*height; // size of bosses over bolt entrances
    taper=3.2;

    difference() {
        union() {        
            // Base plate
            if (baseplate) 
            for (z=[0,height-carrierXF]) translate([0,0,z])
            linear_extrude(height=carrierXF) 
            difference() {
                hull() carrierX2Dbasic(1);
                spar2D();
            }
            
            // Walls
            linear_extrude(height=height,convexity=6) 
                carrierX2D(hole=hole);
                
            if (crossbolt) { // bosses around crossbolt entrances
                intersection() {
                    translate([-200,-200,0]) cube([400,400,height]);
                    for (side=[-1,+1]) scale([side,1,1])
                        translate([sparOD/2,0,carrierXH]) rotate([0,90,0])
                            cylinder(d1=boss+2*taper,d2=boss,h=taper);
                }
            }
        }
        
                
        
        // Cut in threads
        for (side=[-1,+1]) translate([side*rollerX,rollerY])
        {
            threaded_rod(d=3/8*inch-0.2,pitch=1/16*inch,h=height+5,anchor=BOTTOM);
            if (crossbolt) 
                translate([0,0,height+0.01]) scale([1,1,-1])
                    cylinder(d1=sparbolt,d2=5/16*inch,h=5); // taper 
        }
        
        if (crossbolt) {
            translate([0,0,carrierXH]) rotate([0,90,0]) { 
                // thru hole for crossbolt
                cylinder(d=sparbolt,h=2*sparOD,center=true);
        
                // end clearances for crossbolt head
                nutOD=9/16*inch/cos(30);
                translate([0,0,sparOD/2+taper])
                    cylinder(d=nutOD+4,h=sparOD);
                
                scale([1,1,-1]) // hex to hold crossbolt nut
                    translate([0,0,sparOD/2+taper])
                        rotate([0,0,30])
                            cylinder(d=nutOD+0.2,h=sparOD,$fn=6);
            }
        }

        
        // Version stamp
        if (crossbolt) translate([sparOD/2+5,-15,0])
            linear_extrude(height=1.0) rotate([0,0,-90]) scale([-1,1,1])
                text("v1A",size=5,halign="center",valign="center");
    }
}

// Thin far-side support slice frame
module carrierXsupport() {
    carrierX(crossbolt=0,baseplate=0,hole=rollerboltOD,height=5);
}

if (is_undef(entire)) 
{
    // Big carrier
    carrierX();

    // Small support slice on far side
    translate([0,10+sparOD]) carrierXsupport();
}
