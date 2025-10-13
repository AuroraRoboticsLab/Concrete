/*
 Clamp on a circular tool.  Spar connectors on both sides.
*/
include <interfaces.scad>;

include <BOSL2/std.scad>
include <BOSL2/threading.scad>

toolcircleOD = 4.5*inch; // actual outside of 4 inch (nominal) pipe

toolcircleC = [2.5*inch,0,0]; // centerpoint of tool circle

sparC = [0,-3.0*inch,0]; // center of bullet spars

toolcZ = 25; // thickness of us

// Top down view of this tool
module toolc2D() {
    difference() {
        translate([25.4,0,0])
            square([70,120],center=true);
    
        translate(toolcircleC) circle(d=toolcircleOD);
        mirrorY() translate(sparC) spar2D();
    }
}


// Make children at each mounting bolt center point
module toolc_mountboltsC()
{
    mirrorY() translate(sparC+[0,0.99*inch,0]) rotate([-90,0,0]) children();
}


// Whole thing
module toolc3D() {
    difference() {
        linear_extrude(height=toolcZ,center=true,convexity=4)
            toolc2D();
        
        if (is_undef(entire)) toolc_mountboltsC()
            threaded_rod(d=sparbolt,pitch=sparbolt_pitch,h=1.5*inch,anchor=BOTTOM);
    }
}
    
    
if (is_undef(entire)) 
{ // draw this tool
    toolc3D();
}
