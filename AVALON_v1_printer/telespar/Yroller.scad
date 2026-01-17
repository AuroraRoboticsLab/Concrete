/*
The Y roller slides along the Y axis spars, and holds the X axis spar.

roller cross bolts should be 3.5 inches long, attached with nylocks.


 Coordinate system used in this file:
   Z: up and down.  Z is flipped here, to make X and Y more similar.
   Y: across spar, -Y toward tools
   X: along spar

Orion Lawlor, lawlor@alaska.edu, 2025-10-15 (Public Domain)
*/

include <roller_frame.scad> //<- basic frame
include <AuroraSCAD/axes3D.scad>

// Shrink down roller frame default dimensions to get more travel
bearingYDX=35;
rframeDX=45;


// Start of plastic from spar centerline, Y roller plate, measured along local Y (cross spar)
plateYS = sparOD/2+2;
plateYF = 5.0; // minimum floor thickness of plate in front
plateYFH = 16.0; // heavy thickness of front plate (needs to transmit chain force)
plateYB = 5.0; // minimum floor thickness of back plate
plateYBH = 10.0; // heavy thickness of back plate

sparC=3; // clearance between X and Y spars
XsparC2D = [0,-sparOD - sparC]; // 2D center point of X axis spar relative to Y axis spar (Y is down relative to world)
XsparW = rframeW; // thickness of plastic surrounding the X spar
Xsparclear = 0.1; // clearance around X spar (to allow spar to slide into plastic)

/*
 Add a hole for the X axis spar to go through.
 Gets tacked on to existing 2D children in some reasonable way
*/
module Xspar_hole2D(wall = XsparW,round=12) {
    difference() {
        rframe_frameround2D(round)
        union() {
            children();
            translate(XsparC2D) spar2D(enlarge=wall+Xsparclear);
        }
        
        translate(XsparC2D) spar2D(enlarge=Xsparclear);
    }
}


// Create one end of the X-retained-to-Y roller bolt attachment point
XY_boltT=[0, 1.5*inch,XsparC2D[1]-sparOD/2-Xsparclear]; // top center
XY_boltB=XY_boltT+[0,0,sparOD+2*Xsparclear]; // bottom center
XY_boltBL = 1.25*inch; // length of attachment to bottom bolt
module XY_boltT() {
    translate(XY_boltT) scale([1,1,-1]) children();
}
module XY_boltB() {
    translate(XY_boltB) children();
}

XbossH = 0.25*inch; // height of cross bolt support boss
XbossW = 0.75*inch; // diameter of bolt support boss

// Crossbar to resist frame shear (mostly connecting the chain up to the frame)
module Yroller_cross() {
    mirrorX() 
    hull() {
        for (p=[
            [32,-bearingYDY], // X spar side
            [-40,+bearingYDY] // chain side
        ]) translate(p) circle(d=XsparW);
    }
}

// Reinforcing for Y roller
module Yroller_heavy2D(round=8) 
{
    Xspar_hole2D(wall=XsparW,round=round) {
        // Symmetric heavy plate (trimmed on chain side)
        for (flip=[1,-1]) scale([1,flip])
            rframe_heavyplate(trim=flip>0?1:0);
        // taper in material around axle holes
        translate([0,XsparC2D[1]]) for (angle=[0,90]) rotate([0,0,angle])
            square([sparOD+2*XbossH,XbossW],center=true);
        // Add cross support
        Yroller_cross();
    }
}

// Cut holes for bearing rods
module Yroller_bearing_rod_holes(side) {
    scale([1,1,-1]) //<- insert from -Z direction
        rframe_bearing_rod(side,0,enlargeZ=50,exit=1);
    
    rframe_bearing_space();
}

// The front frame sits outside the Y spars, and holds:
//    - The Y axis drive chain
//    - The X axis rod with a retaining bolt
module Yroller_frontframe3D()
{
    difference() {
        union() {
            // Thin plate
            rframe_extrudeXZ(+plateYS,plateYF) 
            {
                Xspar_hole2D() 
                    rframe_baseframe2D(enlarge=rframeW,trim=1);
                Yroller_heavy2D(); // include base plate everywhere
            }
            
            // Heavy plate
            rframe_extrudeXZ(+plateYS,plateYFH) 
                difference() {
                    Yroller_heavy2D();
                    
                    // Lighten cuts on interior of heavy
                    rframe_frameround2D(-8)
                    offset(r=-1.5*rframeW) Yroller_heavy2D();
                }
            
            rframe_bearing_retain(+1,rframeW,plateYS+plateYF,5);
            
            rframe_chain_attachC()
                chain_retain_plate3D() rframe_chain_bolt2D();
            
            // Taper to chain attachment
            intersection() {
                rframe_chain_attachC()
                    translate([-14,0,0]) 
                        cube([12,100,40],center=true); // cube below attachment
                rframe_chain_attachC()
                    chain_retain_plate3D(40) rframe_chain_bolt2D();
                mirrorX() translate(rframe_center_points[0])
                    translate([0,plateYS,0]) rotate([-90,0,0])
                    cylinder(d1=14,d2=32,h=14);
            }
            
            // Surround top of XY bolt
            XY_boltT() 
                    bevelcylinder(d=XbossW,h=XbossH,bevel=1.5);
            XY_boltB() 
                    bevelcylinder(d=XbossW,h=XY_boltBL,bevel=1.5);
        }
        
        Yroller_bearing_rod_holes(+1);
        
        rframe_chain_attachC() chain_retain_holes();
        rframe_bolts();
        
        XY_boltT() cylinder(d=sparbolt,h=50,center=true);
        
        if (is_undef(entire)) 
        XY_boltB()
            threaded_rod(d=sparbolt,pitch=sparbolt_pitch,h=XY_boltBL,anchor=BOTTOM);
    }
}


// The back frame sits inside the Y spars, mostly just holds the ends of the bolts.
module Yroller_backframe3D()
{
    difference() {
        union() {
            rframe_extrudeXZ(-plateYS-plateYB,plateYB) 
                Xspar_hole2D() 
                    rframe_baseframe2D(enlarge=rframeW);
            
            // Heavy reinforcing
            rframe_extrudeXZ(-plateYS-plateYBH,plateYBH)
            {
                Xspar_hole2D(wall=XsparW,round=5) {
                    for (flip=[1,-1]) scale([1,flip])
                        rframe_heavyplate();
                    Yroller_cross();
                }
            }
            
            rframe_bearing_retain(-1,rframeW,-plateYS-plateYB,4);
        }
        
        Yroller_bearing_rod_holes(-1);
        
        rframe_bolts();
    }
}


// Printable versions of parts above, with Z in the right direction
module printable_Yfrontframe() {
    rotate([90,0,0]) translate([0,-plateYS,0]) Yroller_frontframe3D();
}
module printable_Ybackframe() {
    rotate([-90,0,0]) translate([0,+plateYS,0]) Yroller_backframe3D();
}



// Demonstrate all parts of the Y roller
module Yroller_demo(spar=1) {
    Yroller_frontframe3D();
    Yroller_backframe3D();
    
    if (spar) #rotate(rframe_sparR) linear_extrude(height=300,center=true) spar2D();
    #bearingY_centers() bearing3D(bearingY,center=true);
    #rframe_bolts();
    
    echo("Bolt length minimum: ",(plateYB + 2*plateYS + plateYF)/inch+0.375," inches");
}

if (is_undef(entire)) 
{
    if (0) { // demo mode
        Yroller_demo();
    } else { // printable parts
        printable_Yfrontframe();
        //printable_Ybackframe();
    }
}



