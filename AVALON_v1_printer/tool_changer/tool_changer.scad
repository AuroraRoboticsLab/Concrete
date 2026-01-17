/*
 Tool holder block for an automated toolchanger.
 
*/
$fs=0.1; $fa=2;
include <AuroraSCAD/bevel.scad>;

toolblock=[30,30,5];
toolbevel=2; // bevels on leading edge, to self-funnel into place

toolaccessOD=22; // circular access slot
toolaccessX=0; // X center of circular access slot

// Bolted to a tool, to allow automated pickup
module toolblock(enlarge=0,insert=0) {
    e3=2*enlarge*[1,1,1];
    hull() {
        for (insertX=[0,insert])
        translate([-toolblock[0]/2+1-insertX,0,0])
            cube([2,toolblock[1],toolblock[2]]+e3,center=true);
        
        /*
        translate([+toolblock[0]/2-10,0,0])
            bevelcube([20,toolblock[1],toolblock[2]]+e3,bevel=toolbevel,center=true);
        */
        r=toolblock[1]/2;
        translate([+toolblock[0]/2-r,0,0])
            bevelcylinder(d=2*r+2*enlarge,h=toolblock[2]+2*enlarge,bevel=toolbevel+0.5*enlarge,center=true);
        
    }
}

// Make copies of children in +Y and -Y directions
module mirrorY() {
    children();
    scale([1,-1,1]) children();
}

// On robot arm to allow toolblocks to be picked up
module toolsleeve(wall=1.6,space=0.3,pickup=10) {
    difference() {
        // outside (and any optional mounting stuff)
        union() {
            toolblock(enlarge=wall+space);
            children();
        }
        
        springslot=0.3;
        
        difference() {
            // all subtracted parts
            union() { 
                // inside (space for block)
                toolblock(enlarge=space,insert=wall+0.1);
                
                // circular access slot
                hull() {
                    for (slot=[0,1])
                        translate([slot?+toolaccessX:-toolblock[0]/2,0,0])
                            cylinder(d=toolaccessOD+1,h=20);
                }
                
                // pickup slot (space for toolblock to slide in)
                hull() 
                    for (slide=[0,1])
                        translate([-pickup-slide*10,0,slide*toolblock[2]]) 
                            toolblock(enlarge=space+slide*2);
            }
            
            // Pickup tip
            pickupInY=-2; // inward reach of clamp along Y
            mirrorY()
            hull() 
            for (p=[
                [0,+2,0], // inside corner
                [0,pickupInY,0], // actual clamp
                [0,pickupInY,1.5], // actual clamp
                [0,+2,4], // top surface (beveled)
                [-5,+2,0], // back edge
                ])
                translate(p+[-toolblock[0]/2,toolblock[1]/2,-toolblock[2]/2-space])
                    cube(0.01*[1,1,1]);
        }
        
        // Cut slot under spring-loaded retain clip
        springlen=18;
        for (slotZ=[0,4]) translate([0,0,slotZ])
        mirrorY()
        translate([-toolblock[0]/2-3,+toolblock[1]/2-3,-toolblock[2]/2-space])
        {
            cube([springlen,6,springslot]);
            // strain relief at end of cut
            translate([springlen,0,springslot*0.25]) rotate([-90,0,0]) cylinder(d=1.5*springslot,h=10);
        }
    }
}

translate([0,50,(toolblock[2]/2+1.6+0.3)]) toolsleeve();

translate([0,0,toolblock[2]/2]) {
    toolblock();
    translate([toolaccessX,0,0]) cylinder(d=toolaccessOD,h=toolblock[2]/2+2);
}


