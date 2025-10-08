/*
 Telespar 2" tubing roller CAD
 
 Dr. Orion Lawlor, lawlor@alaska.edu, 2025-09-29 (Public Domain)
*/
include <interfaces.scad>;

flange=12; // height of plastic guards over spar (relative to bearing)
flangeW=3.0; // thickness of guards
flangeA=3; // angle of guards (degrees)

rollerW=1.55; // wall thickness of roller plastic

/*
// Roller bearing: 5/16" ID, SCE55 needle bearing
//  Similar to https://www.amazon.com/dp/B08J3KZ9WW?th=1
bearingID=5/16*inch+0.4; // space for bolt
bearingOD=1/2*inch+0.25; // cavity for bearing (with clearance)
bearingZ=5/16*inch+0.5; // height of bearing
*/

// Roller bearing: 3/8" ID, SCE66, https://www.amazon.com/dp/B08J3QR52C?th=1
bearingID=3/8*inch+0.4; // space for bolt
bearingOD=9/16*inch+0.25; // cavity for bearing (with clearance)
bearingZ=3/8*inch+0.5; // height of bearing

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




