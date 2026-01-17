/*
 Mounting bracket for Raspberry Pi 4 computer in Vilross clear fan case.
*/

include <AuroraSCAD/bevel.scad>;

bevel=4; // XY size of bevels on case
piSZ = [67,92,34];  // outside size, with minimal wiggle room

// Solid pi case
module pi_case_solid(enlarge=0) {
    bevelcube(piSZ+2*enlarge*[1,1,1], bevel=bevel+0.7*enlarge, center=true);
}

// Hollow pi case
module pi_case(wall=1.6) {
    difference() {
        pi_case_solid(wall);
        
        pi_case_solid(0.0);
        
        // Hole for ventilation
        #translate([0,0,20]) bevelcube(piSZ+[-12,-12,0],bevel=bevel,center=true);
        
        // Hole for pi removal
        hull() {
            pi_case_solid();
            translate([+30,+50,0]) pi_case_solid();
        }
        
        // Remove webbing on top
        translate([-20,-30,0]) cube([200,200,200]);
        
        // Screw mounting holes
        for (dx=[-20,+20]) for (dy=[-30,+30]) translate([dx,dy])
            cylinder(d=5,h=50,center=true);
    }
}


pi_case();





