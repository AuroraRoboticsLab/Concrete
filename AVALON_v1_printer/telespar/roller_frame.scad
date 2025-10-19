/*
 This roller frame slides along a spar, and there are copies:
   - Yroller: holds each end of the X spar onto the Y spar
   - rframe: holds the tool onto the X spar
 
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
rframeDX = 60; // distance of roller bolts from centerline

rframeDZ_preload = 0.2; // take up slop in bolt holes, cling to spar more strongly
rframeDZ = sparOD/2 + bearingOD/2 - rframeDZ_preload; // distance from spar center to bolt center as printed
rframe_sparR = [0,90,0]; // rotate down to the spar orientation


rframeW=2.32; // wall thickness around main components (integer number of lines)
rframeS=sparbolt; // size of main walls


// Center of chain that we grab above us
XchainC = [+1.5*inch/2,sparOD/2+chainC[2],-chainC[0]-chain_sprocketR];
XchainDX = 3.0*inch; // start points of chain retainer (needs to be integer multiple of chain link distance)

// Put children at chain attachment points
module rframe_chain_attachC() {
    mirrorX() translate([XchainDX,0,0])
        translate(XchainC) 
            rotate([90,0,0]) rotate([0,0,90-10])
                children();
}

// Add 2D circle to chain attachment behind our bolt
module rframe_chain_bolt2D() {
    // Hull out to our bolt itself
    translate([-15,chain_retainN*chain_retainDY])
        circle(d=sparbolt+2*rframeW);
}

// List of 3D centerpoints for roller bolt centers
rframe_center_points = [
    [-rframeDX,0,+rframeDZ],
    [-rframeDX,0,-rframeDZ]
];
// List of 3D centerpoints for Y constaint bearings
bearingY_center_points = [
    [-bearingYDX,0,+bearingYDZ],
    [-bearingYDX,0,-bearingYDZ]
];

// Put children at the centers of the cross-spar roller bolts
//   Only 2D
module rframe_centers() {
    mirrorX() for (p=rframe_center_points) translate(p)
        rotate([90,0,0])
            children();
}

// Space for bolts holding sides together
module rframe_bolts() {
    rframe_centers() cylinder(d=sparbolt,h=sparOD+40,center=true);
}
// Space for bolts hex heads above Y=0
module rframe_bolthex() {
    rframe_centers() cylinder(d=sparbolthex+2,h=sparOD+40);
}

// Put children at the centers of the Y constraint bearings
module bearingY_centers(frontback=[-1,+1]) {
    mirrorX() for (ys=frontback) translate([0,ys*bearingYDY,0])
        for (p=bearingY_center_points) translate(p)
            children();
}


// Project XYZ point down to XZ plane, removing Y
function projectY(p) = [p[0],p[2]];

// 2D outline of roller frame main bolt holes
module rframe_holes2D(enlarge=0) 
{
    mirrorX() for (p=rframe_center_points) translate(projectY(p))
        circle(d=sparbolt+2*enlarge);
}

// 2D outline of basic roller frame, shared between front and back features
module rframe_baseframe2D(enlarge=0, hsides=1, trim=0)
{ 
    offset(r=+enlarge)
    difference() {
        union() 
        {
            // Material around bolts
            rframe_holes2D();
        
            // Vertical upright sides
            sideH=sparbolt*0.25; // horizontal sideplate width
            sideV=sparbolt*0.5; // vertical sideplate width
            mirrorX() hull()
            for (p=rframe_center_points) translate(projectY(p))
                circle(d=sideV);
            
            // Horizontal (top and bottom) sides
            if (hsides) {
                for (i=[0,1])
                hull() mirrorX() translate(projectY(rframe_center_points[i]))
                    circle(d=sideH);
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
    
        // Trim top surface (avoids hitting chain)
        if (trim) translate([0,200+rframeDZ+sparbolt/2+rframeW-enlarge]) square([400,400],center=true);
    }
}

// Space for 3D upright retaining rod, the bearings slide on here.
//  Side=+1 is the +Y direction, side=-1 is the -Y direction
//  The rods need to be beveled, and the hole needs to be drilled out.
module rframe_bearing_rod(side,enlarge=0,enlargeZ=0,exit=0) {
    mirrorX() 
        translate([bearingYDX,side*bearingYDY,-bearingYL/2])
        {
            bevelcylinder(d=bearingYOD+2*enlarge,h=bearingYL+enlargeZ,bevel=0.7*enlarge);
            
            if (exit) { // add an exit path, so the rod can be driven out too
                scale([1,1,-1])
                    cylinder(d=bearingYOD-2,h=bearingYL+enlargeZ);
            }
        }
}

// Retain the bearing rods, by tapering back to the frame
module rframe_bearing_retain(side,enlarge,Yflat,extraZ=0) {
    round=enlarge*0.8;
    mirrorX()
        translate([bearingYDX,side*bearingYDY,0])
        {
            linear_extrude(height=bearingYL+2*extraZ,center=true,convexity=4)
            offset(r=-round) offset(r=+round)
            {
                circle(d=bearingYOD+2*enlarge);
                translate([0,Yflat-side*bearingYDY,0])
                    scale([1,side,1])
                        translate([0,-2,0])
                            square([15,4],center=true);
            }
        }
}

// 3D space around bearings
module rframe_bearing_space(enlarge=0) {
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

// Apply frame rounding to our 2D children (round inside corners)
module rframe_frameround2D(roundinside=12) 
{
    offset(r=-roundinside) offset(r=+roundinside)
        children();
}

// Slice XZ plane to XY at this Y coordinate
module sliceXZ(atY) {
    projection(cut=true) translate([0,0,atY]) rotate([-90,0,0]) children();
}


// Extrude this 2D frame shape to this thickness, starting at this Y coord.
//    Height extrudes in the +Y direction
module rframe_extrudeXZ(start,height) 
{
    translate([0,start+height,0])
    rotate([90,0,0])
    linear_extrude(height=height, convexity=4)
        children();
}
// Bevelled version of above (only works for convex shapes)
module rframe_extrudeXZbevel(start,height,bevel) 
{
    translate([0,start+height,0])
    rotate([90,0,0])
    bevel_extrude_convex(height=height, convexity=4, bevel=bevel)
        children();
}

// Heavier frame plate on one side
module rframe_heavyplate(topslot=25, bottomtrim=-22, roundIn=3, trim=0)
{
    rframe_frameround2D() 
        offset(r=+roundIn) offset(r=-roundIn)
        difference() {
            union() {
                difference() {
                    rframe_baseframe2D(enlarge=rframeW,trim=trim);
                    translate([0,topslot-200]) square([1.95*rframeDX,400],center=true);
                }
                children();
            }
            translate([0,bottomtrim-200]) square([400,400],center=true);
        }
}



