/*
 A 3D printed positive displacement pump:
    Helical plastic rotor
    Double-lobe spiral rubber stator
 
 Drive rod: square 1/2" square steel tube

 Based on "Moineau Pump by emmett" in 2011:
 from https://www.thingiverse.com/thing:7958/files
    CC BY-SA
 
 Paper on Moineau updates:
     http://www2.mat.dtu.dk/people/J.Gravesen/pub/30-2008.pdf
 
 
 Idea for 3D printer: standard 'auger' gear transitions to a swing linkage rod.
 Linkage has de-aerator and feed prongs, doesn't even need a spiral though.
 Connects down to pump rotor.
 Pump stator is just sitting in 2" PVC pipe?
 
 Dr. Orion Lawlor, lawlor@alaska.edu, 2025-03 (Public Domain)
*/
include <AuroraSCAD/bevel.scad>;
$fs=0.1; $fa=2;

inch = 25.4; // file units: mm

crank_OD = 0.5*inch+0.3; // 1/2" box tubing steel drive crank
stator_ID = 2.04*inch; // 2" nominal ABS pipe interior


//rotor_holy(); // helix rotor

//stator(); // 3D printed shell
stator_interior(); // solid interior part (castable)
//stator_exterior(); // solid exterior part

if (0) difference() { 
    pumping_animated();
    //gap(); 
    scale([-1,-1,1]) cube([H,H,H]); 
}

//pipe_interior();


rotation = $t*360;

R1=10; // radius of rolling circle
R2=15; // radius of rotor
H=100; // height
wall=2*0.4*0.8; // wall thickness

c2=0.2; // stator clearance
lobes = 3; // number of repeating sections
phi=360*lobes/2; // degrees of rotation of stator (>360)
//$fn=40; // number of facets in circles

v=4*R1*R2*H*360/phi;
echo(str("Pumping speed is ",v/1000," cc per revolution"));

// Rotor itself
module rotor(){
    linear_extrude(height=H,convexity=8,twist=2*phi)
        translate([R1/2,0,0])
            circle(r=R2);
    
    // end taper
    translate([0,0,H])
        linear_extrude(height=H/lobes,convexity=20,twist=2*phi/lobes,scale=0.1)
        translate([R1/2,0,0])
            circle(r=R2);
            
}

// Rotor with drive hole and bolt holes
module rotor_holy() {
    difference() {
        rotor();
        
        // Crank rod goes here
        bevelcube([crank_OD,crank_OD,2*H+2],center=true,bevel=1);
                
        // M3 screw to hold crank in place
        translate([0,0,H-8]) 
        for (angle=[ //[0,-90,0], 
            [90,0,0] ]) rotate(angle)
        {
            cylinder(d=3.2,h=12);
            translate([0,0,8])
                cylinder(d=6.2,h=3+10);
        }
    }
}

// 2D shape of stator interior void
module hollow2D(clearance=0) {
    Rc=R1;
    Rr=R2+clearance;
    
    union(){
        translate([-Rc,0,0])
            circle(r=Rr);
        translate([Rc,0,0])
            circle(r=Rr);
        
        square([2*Rc,2*Rr],center=true);
        // for a smoother mesh:
        square([2/5*Rc,2.003*Rr],center=true);
        square([5/5* Rc,2.002*Rr],center=true);
        square([8/5*Rc,2.001*Rr],center=true);
    }
}

// 3D twisted shape of stator interior
module hollow(clearance=0){
    linear_extrude(height=H,convexity=8,twist=phi)
        hollow2D(clearance);
}

// Flared end of stator
module hollow_ramp(clearance,flare,h) {
    hull() {
        linear_extrude(height=0.01) hollow2D(clearance);
        translate([0,0,h]) //rotate([0,0,-phi*h/H])
            linear_extrude(height=0.01) hollow2D(clearance+flare);
    }
}

// Stator interior mold (for cast rubber stator)
module stator_interior(){
    flare=4; // mm of ramp diameter
    h=4; // height of ramp
    intersection() {
        union() {
            hollow(c2);
            //translate([0,0,H-0.01]) 
            //    hollow_ramp(c2,flare,h);
            translate([0,0,0.01]) 
                hollow_ramp(c2,flare,-h);
        }
        
        cylinder(d=stator_ID,h=3*H,center=true);
    }
}

// Stator pipe interior volume
module pipe_interior() {
    cylinder(d=stator_ID,h=H);
}


// Stator exterior solid, like for printing from TPU,
//   or computing the volume for casting.
module stator_exterior() {
    difference() {
        pipe_interior();
        stator_interior();
    }
}


// Printed stator, with walls
module stator(){
    difference(){
        hollow(wall+c2);
        difference(){
            hollow(c2);
        }
    }
}

module gap(){
    difference(){
        hollow();
        
        rotate([0,0,-rotation])
        scale([1,1,1.002])
        translate([R1/2,0,-0.001])
        rotate([0,0,2*rotation])rotor();
    }
}

module pumping_animated()
{
    // rotate in a hypocycloid
    rotate([0,0,-rotation])
    translate([R1/2,0,0])
    rotate([0,0,2*rotation])
        rotor_holy();

    color([0,1,1,0.2])stator();
} 
