/*
 Towers to support Volor bearings.
 
 Basic stack:
 
 
 
 20mm 
 
 1" tubing
 
 
*/
$fs=0.1; $fa=5;

inch=25.4; // file units are mm

basicZ = 20; // Z main U tube up to bottom of towers
stackOC = 11; // Z distance from bearing to bearing, on center

OD = 22; // diameter of most towers
ID = 8.2; // diameter of hole through towers
dualOD=ID+4; // diameter of dual towers
dualY=25; // Y distance between dual towers
dualZ=basicZ - 14; // starts at smaller stub of frame

module basic(height=basicZ)
{
    difference() {
        cylinder(d=OD,h=height);
        cylinder(d=ID,h=3*height,center=true);
    }
}


module dual() 
{
    z=dualZ+stackOC;
    difference() {
        hull() {
            for (y=[0,dualY])
                translate([0,y,0])
                    cylinder(d=dualOD,h=z);
        }
        
        // cut in axle holes
        for (y=[0,dualY])
            translate([0,y,0])
                cylinder(d=ID,h=3*z,center=true);
         
         // Make space for lower axle and belt
         axlespace = 1.25*inch+3;
         hull() {
            for (x=[0,-dualY]) //<- space for belt to zoom off
                 translate([x,0,dualZ])
                    cylinder(d=axlespace,h=z);
         }
    }
}



part = 2;

if (part==0) basic(); // need 3 basic towers
if (part==1) basic(basicZ + stackOC); // high idler on bottom left
if (part==2) dual(); // dual towers on X carriage





