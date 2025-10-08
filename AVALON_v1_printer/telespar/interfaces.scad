/*
 Interface definitions between printed parts

 Dr. Orion Lawlor, lawlor@alaska.edu, 2025-09-29 (Public Domain)
*/

$fs=0.1; $fa=2; // smooth finish

inch=25.4; // file units are mm

sparOD=2.0*inch+0.4; // spar size (plus some clearance)
sparR=3.0; // rounding on corners

module spar2D(enlarge=0,round=1) {
    offset(r=+round*sparR+enlarge) offset(r=-round*sparR)
        square(sparOD*[1,1],center=true);
}

// Clearance for bolts on spar X axis
module spar2Dbolts(enlarge=0) {
    deep=8; // space for 3/8" bolt head
    wide=20; // space for hex, plus some clearance
    round=3;
    offset(r=+round) offset(r=-round)
    offset(r=-round) offset(r=+round)
    {
        spar2D(enlarge=enlarge);
        offset(r=+enlarge)
            square([sparOD+2*deep,wide],center=true);
    }
    
}

sparbolt=3/8*inch+0.5; // diameter of bolts going through spar

rollerR = 9/16/2*inch; // rolling radius of rollers (bare steel) on top of spar
rollerOD = 40; // clearance diameter of outside of roller flanges

ZrollerZ = 1.0*inch; // width of roller
ZrollerMD = 1.5*inch; // maximum diameter of roller
ZrollerDX = 1.0*inch; // shift from surface of spar to surface of next spar
ZrollerSX = 1.75*inch; // shift from center of spar to center of Z roller 
Zroller_bolt=3/8*inch; // axle bolt





