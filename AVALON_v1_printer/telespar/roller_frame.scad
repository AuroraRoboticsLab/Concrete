/*
 This roller frame slides along a spar, and there are copies:
   - Yroller: holds each end of the X spar onto the Y spar
   - Xroller: holds the tool onto the X spar
 
 It's designed to constrain motion on all axes except along the spar.

 Coordinate system used in this file:
   Z: up and down
   Y: across spar, +Y toward tools
   X: along spar
*/
include <interfaces.scad>

include <BOSL2/std.scad>
include <BOSL2/threading.scad>

include <AuroraSCAD/bearing.scad>
include <AuroraSCAD/bevel.scad>



// Diameter under hex head of spar bolt
sparbolthex=9/16*inch/cos(30)+1.0;

// Bearings used to constrain Y axis motion of frame
bearingY = bearing_625;
bearingYS = 1; // space around bearing
bearingYZ = 10; // length of space for rods retaining Y bearings
bearingYL = 50; // total length of rod
bearingYOD = 5.0; // diameter of rods retaining Y bearings
bearingYDX = 50; // radius in X from centerline
bearingYDY = sparOD/2+bearingOD(bearingY)/2; // position from spar to center of bearing
bearingYDZ = 16; // radius in Z from spar center to center of bearing

// Top and bottom rollers constrain Z motion
XrollerDX = 60; // distance of roller bolts from centerline

XrollerDZ_preload = 0.2; // take up slop in bolt holes, cling to spar more strongly
XrollerDZ = sparOD/2 + bearingOD/2 - XrollerDZ_preload; // distance from spar center to bolt center as printed
Xroller_sparR = [0,90,0]; // rotate down to the spar orientation

// Center of chain that we grab above us
XchainC = [+1.5*inch/2,sparOD/2+chainC[2],-chainC[0]-chain_sprocketR];
XchainDX = XrollerDX+20; // start points of chain retainer



// Start of plastic from spar centerline
plateYS = sparOD/2+2;
plateYF = 5.0; // floor thickness of plate in front (also gets a bunch of ribs and such)
plateYB = 6.0; // floor thickness of back plate

// List of 3D centerpoints for X roller centers
Xroller_center_points = [
    [-XrollerDX,0,+XrollerDZ],
    [-XrollerDX,0,-XrollerDZ]
];
// List of 3D centerpoints for Y constaint bearings
bearingY_center_points = [
    [-bearingYDX,0,+bearingYDZ],
    [-bearingYDX,0,-bearingYDZ]
];

// Put children at the centers of the cross-spar roller bolts
//   Only 2D
module Xroller_centers() {
    mirrorX() for (p=Xroller_center_points) translate(p)
        rotate([90,0,0])
            children();
}

// Space for bolts holding sides together
module Xroller_bolts() {
    Xroller_centers() cylinder(d=sparbolt,h=sparOD+40,center=true);
}

// Put children at the centers of the Y constraint bearings
module bearingY_centers(frontback=[-1,+1]) {
    mirrorX() for (ys=frontback) translate([0,ys*bearingYDY,0])
        for (p=bearingY_center_points) translate(p)
            children();
}


// Project XYZ point down to XZ plane, removing Y
function projectY(p) = [p[0],p[2]];

// 2D outline of basic roller frame, shared between front and back features
module Xroller_baseframe2D(enlarge=0, hsides=1)
{ 
    offset(r=+enlarge)
    {
        // Material around bolts
        mirrorX() for (p=Xroller_center_points) translate(projectY(p))
            circle(d=sparbolthex);
    
        // Left and right upright sides
        mirrorX() hull()
        for (p=Xroller_center_points) translate(projectY(p))
            circle(d=sparbolt);
        
        // Top and bottom sides
        if (hsides) {
            for (i=[0,1])
            hull() mirrorX() translate(projectY(Xroller_center_points[i]))
                circle(d=sparbolt);
        }
        
        // Bearing area
        mirrorX() 
        for (p=bearingY_center_points) translate(projectY(p)) 
        {
            // Bearing itself
            offset(r=bearingYS)
            square([bearingOD(bearingY),bearingZ(bearingY)],center=true); 
            // Bearing axle
            square([bearingYOD,bearingYZ],center=true); 
        }
    }
}



// 3D upright retaining rod, the bearings slide on here
module Xroller_bearing_rod(side,enlarge=0,enlargeZ=0) {
    mirrorX() 
        translate([bearingYDX,side*bearingYDY,-bearingYL/2])
            bevelcylinder(d=bearingYOD+2*enlarge,h=bearingYL+enlargeZ,bevel=0.7*enlarge);
}

// Space around bearing
module Xroller_bearing_space(enlarge=0) {
    bearingY_centers() 
    difference() {
        OD = bearingOD(bearingY);
        h = bearingZ(bearingY)+2*bearingYS;
        bevelcylinder(
            d=OD+2*bearingYS+2*enlarge, h=h+2*enlarge,
            bevel=bearingYS+0.7*enlarge, center=true);
        
        // Carve in supports to define Z position of bearing
        if (enlarge==0) {
            taper=bearingYS;
            for (side=[-1,+1]) scale([1,1,side])
            translate([0,0,-h/2])
                cylinder(d1=bearingYOD+1+2*taper,d2=bearingYOD+1,h=taper);
        }
    }
}

XrollerW=2.4; // wall thickness around main components
XrollerS=sparbolt; // size of main walls

// Apply frame rounding to this 2D children
module Xroller_frameround2D() 
{
    roundinside=12;
    offset(r=-roundinside) offset(r=+roundinside)
        children();
}


// Slice XZ plane to XY at this Y coordinate
module sliceXZ(atY) {
    projection(cut=true) translate([0,0,atY]) rotate([-90,0,0]) children();
}


// Extrude this 2D frame shape to this thickness, starting at this Y coord.
//    Height extrudes in the +Y direction
module Xroller_extrudeXZ(start,height) 
{
    translate([0,start+height,0])
    rotate([90,0,0])
    linear_extrude(height=height, convexity=4)
        children();
}
// Bevelled version of above (only works for convex shapes)
module Xroller_extrudeXZbevel(start,height,bevel) 
{
    translate([0,start+height,0])
    rotate([90,0,0])
    bevel_extrude_convex(height=height, convexity=4, bevel=bevel)
        children();
}





