/*
 'Piston' moves down the extruder barrel and pushes concrete down a tube.
 
 Barrel is mounted vertically, outlet tube down, so it can be gravity-loaded.
 
 Air will vibrate to the top, where we have some M3 holes to remove air.
   - Idea: Q tip wedged in the hole, to filter out air (and excess water)
 
 Dr. Orion Lawlor, lawlor@alaska.edu 2025-03-01 (Public Domain)
*/
$fs=0.1; $fa=2;
include <AuroraSCAD/bevel.scad>;
include <piston_pump_interface.scad>;

// Puts children at the piston bolt radius
module pistonBoltCenters()
{
    da=360/pistonBolts;
    for (angle=[da/2:da:360-1]) rotate([0,0,angle])
        translate([pistonBoltR,0,0])
            children();
}

pistonDrivepinWall=2.4; // wrap for everything
pistonDrivepinSlotX = 22; // width of slot

module pistonDrivepinCylinder(d,h) {
    translate(pistonDrivepinC) rotate([0,90,0]) children();
}

module pistonDrivepinMount()
{
    retainID=2.7; // retaining bolt tap diameter
    retainOD = 3.2+2*pistonDrivepinWall; // outside plastic
    retainC = pistonDrivepinC+[pistonDrivepinLen/2+retainID/2+0.5,0,0];
    retainZ = pistonDrivepinOD+2*pistonDrivepinWall;
    floor=3;
    difference() {
        hull() {
            pistonBoltCenters() cylinder(d=7,h=floor);
            pistonDrivepinCylinder()
                cylinder(d=pistonDrivepinOD+2*pistonDrivepinWall,h=pistonDrivepinLen+2*pistonDrivepinWall,center=true);

            translate(retainC) cylinder(d=retainOD,h=retainZ,center=true);
        }
        
        pistonBoltCenters() {
            cylinder(d=3.3,h=50);
            translate([0,0,floor]) bevelcylinder(d=8,h=50,bevel=0.5);
        }
        
        // scoop out space for linear actuator travel
        pistonDrivepinCylinder() {
            bevelcylinder(bevel=3,d=2*pistonDrivepinC[2]+1,h=pistonDrivepinSlotX,center=true);
            cylinder(d=pistonDrivepinOD,h=pistonDrivepinLen,center=true);
            cylinder(d=pistonDrivepinOD,h=pistonDrivepinLen);
        }
        
        translate(retainC) cylinder(d=retainID,h=retainZ+3,center=true); 
    }
}

// Actual piston face, facing down
module pistonFace() {
    pistonOD = barrelID-1.0; // space to insert (seal with silicone)
    outerwall=1.8;
    floor=6;
    
    scale([1,1,-1]) 
    difference() {
        cylinder(d=pistonOD,h=pistonZ);
        sealDeep=0.8;
        
        // Carve out pressure wall, so material pushes seal closed
        round=8;
        difference() {
            rotate_extrude(convexity=4) 
            union() {
                offset(r=+round) offset(r=-round)
                {
                    translate([pistonOD/2-outerwall,5]) scale([-1,1])
                        square([16+0.1,50]);
                }
                
                translate([0,floor]) square([pistonOD/2-round,50]);
                
                // Sealing rings
                sealRound=0.8;
                offset(r=+sealRound) offset(r=-sealRound)
                for (sealZ=[3:4:pistonZ-3]) 
                    translate([pistonOD/2-sealDeep,sealZ])
                        rotate([0,0,-90+45])
                            square([10,10]);
            }
            
            difference() {
                for (angle=[0:360/8:180-1]) rotate([0,0,angle]) {
                    translate([0,0,pistonZ/2])
                    cube([pistonOD-3*sealDeep,outerwall,pistonZ],center=true);
                }
                cylinder(d1=55,d2=pistonOD,h=pistonZ+1);
            }
            
            pistonBoltCenters() cylinder(d1=20,d2=10,h=floor);
        }
        
        // Tap M3 in here to mount piston to linear actuator driver
        pistonBoltCenters() cylinder(d=3.4,h=15);
        
        if (0)
        for (vent=[0:180:360-1]) rotate([0,0,vent])
            translate([pistonOD/2-1.5*round,0,+8])
            rotate([0,20,0])
            scale([1,1,-1])
            {
                in=2.8;
                cylinder(d1=in+2,d2=in,h=4);
                cylinder(d=in,h=20);
            }
        
        //color([1,0,0]) cube([200,200,200]);
    }
}

sealOD = barrelID+2.5; // extra friction fit onto barrel walls
sealH = 12; 
sealW = 1.2;

// Flexible ring
module sealingRing(enlarge=0) {
    round=3;
    rotate_extrude()
    offset(r=-round) offset(r=+round + enlarge)
    {
        translate([sealOD/2 - sealW,0]) square([sealW,sealH]);
        translate([sealOD/2 - sealH,0]) square([sealH,sealW]);
    }
}

// Occupies space around exit point
module taperPlug() {
    difference() {
        cylinder(d1=barrelID-3,d2=52,h=20);
        
        sealingRing(0.0);
        
        pistonBoltCenters() cylinder(d=2.7,h=15);
    }
}




//pistonDrivepinMount();
pistonFace();
//sealingRing();
//taperPlug();

