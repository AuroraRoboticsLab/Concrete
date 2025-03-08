/*
 
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
 
*/
include <AuroraSCAD/bevel.scad>;
$fs=0.1; $fa=2;

inch = 25.4; // file units: mm

crank_OD = 0.5*inch+0.3;
stator_ID = 2.04*inch; // 2" nominal ABS pipe interior


//rotor_hole();

//stator(); // 3D printed shell
//stator_interior(); // solid interior part
//stator_exterior(); // solid exterior part

if (1) difference() { 
    pumping_animated();
    //gap(); 
    scale([-1,-1,1]) cube([H,H,H]); 
}

//pipe_interior();


rotation = $t*360;

R1=10; // radius of rolling circle
R2=15; // radius of rotor
H=100; // height
wall=2*0.4*1.6; // wall thickness

crank_spiral=10;
top=3; // crank thickness
c1=0.25; // crank clearance
c2=0.3; // stator clearance
lobes = 3; // number of repeating sections
phi=360*lobes/2; // degrees of rotation of stator (>360)
//$fn=40; // number of facets in circles

v=4*R1*R2*H*360/phi;
echo(str("Pumping speed is ",v/1000," cc per revolution"));

// Rotor itself
module rotor(){
    linear_extrude(height=H,convexity=20,twist=2*phi)
        translate([R1/2,0,0])
            circle(r=R2);
    
    // end taper
    translate([0,0,H])
        linear_extrude(height=H/lobes,convexity=20,twist=2*phi/lobes,scale=0.1)
        translate([R1/2,0,0])
            circle(r=R2);
            
}

// Rotor with drive hole
module rotor_hole() {
    hole=4; // clearance for 1/8" or 3mm wire
    difference() {
        rotor();
        
        bevelcube([crank_OD,crank_OD,2*H+2],center=true,bevel=1);
        
        /*
        // central corewire
        cylinder(d=hole,h=3*H,center=true);
        // L shaped foot to key for driving
        translate([0,0,hole/4]) rotate([0,90,0]) cylinder(d=hole,h=R2);
        
        // M3 screws to hold corewire in place
        for (side=[-1,+1]) translate([R2/2,(hole+3)/2*side,-0.01])
            cylinder(d=2.4,h=8);
        */
    }
}

module crank(){ 
    translate([R2*4,R2/2,0])cylinder(r=R2/2,h=30);

    difference(){
        linear_extrude(height=top)
        union(){
            circle(r=R2);
            polygon(points=[[0,R2],[R2*4,R2],[0,0],[R2*4,R2/2]],paths=[[0,1,3,2]]);
            mirror([R2/2,-R2*4,0])
            polygon(points=[[0,R2],[R2*4,R2],[0,0],[R2*4,R2/2]],paths=[[0,1,3,2]]);
        }
        
        linear_extrude(height=top,convexity=20,twist=crank_spiral,slices=10)
            square(R2+2*c1,center=true);
    }
}

module hollow(Rc,Rr){
    linear_extrude(height=H,convexity=10,twist=phi,slices=100)
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

// Stator interior mold (for cast rubber stator)
module stator_interior(){
    hollow(R1,R2+c2);
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
        hollow(R1,R2+wall+c2);
        difference(){
            hollow(R1,R2+c2);
        }
    }
}

module gap(){
    difference(){
        hollow(R1,R2);
        
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

    union(){
    /*
        translate([cos(2*phi)*R1/2,-sin(2*phi)*R1/2,H])
            crank();
    */
        rotor_hole();
    }

    color([0,1,1,0.2])stator();
} 
