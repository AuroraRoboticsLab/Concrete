/*
  Wedge Volor Z axis's ACME leadscrew nut down into its slot.
  The leadscrew nut (machined from HDPE) and this wedge sit inside 1" square tubing with 0.050" walls.
  
*/
$fs=0.1;
$fa=3;

shaftOD=13;
slotID=22;
Z = 11.5; // Z height of wedge, should be very tight to reduce backlash


module volor_nut_wedge()
{
    difference() {
        // body
        cube([slotID,slotID,Z],center=true);
        
        // thru shaft
        cylinder(d=shaftOD,h=2*Z,center=true);
        
        // spring loaded slot for insertion
        hull() {
            for (y=[0,slotID]) translate([0,y,0])
                cylinder(d=shaftOD-0.5,h=2*Z,center=true);
        }
        
        // sloped insertion wedge
        translate([0,0,Z]) rotate([-2,0,0])
            cube([2*slotID,2*slotID,Z],center=true);
    }
}

volor_nut_wedge();


