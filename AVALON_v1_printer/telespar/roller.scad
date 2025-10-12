/*
 Telespar 2" tubing roller CAD - NOT USED IN PRINTER

 This plastic roller directly rolls on the spars.

 This approach didn't seem t work as well as directly rolling steel bearings
 on the steel spars--a plastic roller's sides break off, and surfaces wear.
 
 Dr. Orion Lawlor, lawlor@alaska.edu, 2025-09-29 (Public Domain)
*/
include <interfaces.scad>;

flange=12; // height of plastic guards over spar (relative to bearing)
flangeW=3.0; // thickness of guards
flangeA=3; // angle of guards (degrees)

rollerW=1.55; // wall thickness of roller plastic

bearingStickout=1; // bearing protrudes from part this far

echo("rollerR actual: ",(bearingOD/2+rollerW)/inch," inches");
echo("rollerOD actual: ",bearingOD + 2*flange," mm");



/* Cross section of roller */
module roller2D() {
    bearingY = sparOD/2+flangeW+bearingStickout-bearingZ; // start of bearing

    roundIn=0.75*rollerW; // rounding on inside corners
    roundOut=0.2*rollerW; // rounding on outside corners
    //offset(r=+roundOut) offset(r=-roundOut)
    offset(r=-roundIn) offset(r=+roundIn)
    difference() {
        union() {
            for (end=[-1,+1]) scale([1,end])
            {
                offset(r=-sparR) offset(r=+sparR) // round inside corners
                {
                    // flanges
                    translate([bearingOD/2,sparOD/2])
                        rotate([0,0,flangeA])
                            square([flange,flangeW]);
                    // Bearing surface
                    start=bearingY-2*rollerW;
                    translate([bearingOD/2,start])
                        square([rollerW,sparOD/2-start+rollerW]);
                }
                
                // Middle tube
                translate([((bearingID+bearingOD)/2)/2,0])
                    square([rollerW,bearingY]);
            }
        }
        
        for (end=[-1,+1]) scale([1,end])
        {
            // Trim top and bottom flat
            translate([bearingOD/2,sparOD/2+flangeW])
            {
                square([flange,flangeW]);
                
                // Trim outside corner of flange (self-aligning)
                translate([flange,-flangeW*0.33])
                    rotate([0,0,-90-65])
                        square([flange/2,flange/2]);
            }
            
            // Space for bearings
            translate([0,bearingY])
                square([bearingOD/2,bearingZ]);
        }
        
    }
}

rotate_extrude() roller2D();




