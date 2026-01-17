/*
Drain plug for a positive displacement pump.
Fits on the bottom stainless steel drain hole.

*/
$fs=0.1; $fa=2;

ID=29.5;
OD=34.1;
wall=1.84; // 4 lines
floor=2.0; // bottom thickness
flange=3.0; // hand grab ridge
Z=38;

difference() {
    union() {
        rotate_extrude() 
        offset(r=-floor) offset(r=+floor) {
            square([OD/2+wall,Z+floor]);
            square([OD/2+wall+flange,floor]);
        }
    }
    
    // Ring hole for wall of pipe
    rotate_extrude() 
        translate([ID/2,+floor])
            square([(OD-ID)/2,Z+1]);
    
    // Remove interior
    cylinder(d=ID-2*wall,h=Z-floor);
}

