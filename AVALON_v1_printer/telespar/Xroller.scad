/*
The X roller slides along the X axis spar, and holds the actual printing tool.

Parts needed for fit out:
    - Four printed parts below:
        - frontframe attaches to everything else
        - backframe holds the front onto the spar
        - bullet toolholder holds the tool
        - toggle aligns the frontframe and bullet (and optional electrical hookups?)
    The printed parts need to be cleaned up by drilling out the 5mm shaft holes to true 5mm, and tapping at least the 3/8" holes to true 3/8". 
    
    - 20kgf load cell at bottom, connects frontframe and bullet
        - 2x 4mm x 20mm screws, used on bullet side of load cell
        - 2x 5mm x 20mm screws, used on frontframe side of load cell
    
    - Four large rollers:
        - 2x 3/8" x 4" bolts, which have 2.8 inches of smooth shaft for the top of spar rollers
        - 2x 3/8" x 3.5" bolts, which have 2.3 inches of smooth shaft for the bottom of spar rollers
        
        - 8x 3/8" ID needle bearings, type SCE66, to hold the tool loads
        - 4x roller_spacers, to space the rollers on the bolts
        - 8x 3/8" washers, stackup is frame - washer - bearing - spacer - bearing - washer - frame - nut
        - 4x nylock nuts to hold the roller bolts in place
    
    - 8x 625 bearings, used to constrain Y motion
    - 6x 5mm diameter by 50mm length rods, used to hold the toggle.  These should have gently beveled ends to allow them to slide into place.

    - 2x 3/8" diameter x 4" length all-thread bolts to connect front and back plates diagonally. 


Orion Lawlor, lawlor@alaska.edu, 2025-10-10 (Public Domain)
*/

include <interfaces.scad>

includebullet=1; // allow bullet to be included
include <tool_bullet.scad> // tool pickup

include <BOSL2/std.scad>
include <BOSL2/threading.scad>

include <AuroraSCAD/bearing.scad>
include <AuroraSCAD/bevel.scad>

// Coordinate system used in this file:
//   Z: up and down
//   Y: across spar, +Y toward tools
//   X: along spar


// Diameter under hex head of spar bolt
sparbolthex=9/16*inch/cos(30)+1.0;

// Bearings used to constrain Y axis motion of toolhead
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

// Origin of base of tool pickup (bullet)
toolO = [0,4*inch,-1.5*inch];
toolR = [90,0,0];

// Center of load cell
loadcellC = [0,plateYS+loadcellSZ[1]/2,-80];

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

// 2D solid outline of bottom roller frame, including the load cell
module Xroller_bottomframe2D(enlarge=0,Xshift=0,Zshift=0) {
    offset(r=+enlarge) hull()
    {
        mirrorX() for (p=Xroller_center_points) 
            translate(projectY(p)+[Xshift,(p[2]>0?1:-1)*Zshift])
                circle(d=sparbolt);
        translate(projectY(loadcellC)+[0,-Zshift]) square(projectY(loadcellSZ),center=true);
    }
}

// 3D upright retaining rod
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

// Put children at diagonal all-thread bolts that connect front and back
module Xroller_diagonalboltsC() 
{
    mirrorX() translate(loadcellC+[12,-25,-12])
        rotate([55,0,20])
            children();
}
// Outside wall around diagonal bolts
module Xroller_diagonalboltsW()
{
    Xroller_diagonalboltsC()
        cylinder(d=sparbolt + 2*XrollerW,h=4.1*inch);
}

// Slice XZ plane to XY at this Y coordinate
module sliceXZ(atY) {
    projection(cut=true) translate([0,0,atY]) rotate([-90,0,0]) children();
}

// Back frame electronics box mount holes
module Xroller_backframe_EmountC() {
    mirrorX() mirrorZ() translate([-1*inch,-plateYS-plateYB+0.01,-1.25*inch])
        rotate([90,0,0])
            children();
}

// 3D shape of back frame
module Xroller_backframe3D() {
    difference() {
        union() {
            Xroller_extrudeXZ(-plateYS-plateYB,plateYB) 
                Xroller_frameround2D() {
                    Xroller_baseframe2D(enlarge=XrollerW);
                    sliceXZ(-plateYS) Xroller_diagonalboltsW();
                }
            // Heavier plate on top (avoid weakness around bearing rods
            roundIn=3;
            Xroller_extrudeXZ(-plateYS-2*plateYB,2*plateYB) 
                Xroller_frameround2D() 
                offset(r=+roundIn) offset(r=-roundIn)
                difference() {
                    Xroller_baseframe2D(enlarge=XrollerW);
                    translate([0,22-200]) square([2*XrollerDX,400],center=true);
                    translate([0,-22-200]) square([400,400],center=true);
                }
            
            Xroller_bearing_rod(-1,XrollerW);
            Xroller_diagonalboltsW();
            
            Xroller_backframe_EmountC() 
                scale([1.5,1,1]) cylinder(d1=15,d2=8,h=10);
        }
        
        Xroller_bearing_rod(-1,0,50);
        Xroller_bearing_space();
        
        Xroller_bolts();
        
        // Cut threads that match the front plate for diagonal bolts:
        if (is_undef(entire)) Xroller_diagonalboltsC() translate([0,0,3*inch])
            threaded_rod(d=sparbolt,pitch=sparbolt_pitch,h=1.5*inch,anchor=BOTTOM);
        
        // Tap these electronics box mount points for M5 screws
        Xroller_backframe_EmountC() cylinder(d=4.4,h=50,center=true);
        
        // Trim bottom flat
        translate([0,200-plateYS,0]) cube([400,400,400],center=true);
    }
}

// Put children at chain attachment points
module Xroller_chain_attachC() {
    mirrorX() translate([XchainDX,0,0])
        translate(XchainC) 
            rotate([90,0,0]) rotate([0,0,90-10])
                children();
}

// Add 2D circle to chain attachment behind our bolt
module Xroller_chain_bolt2D() {
    // Hull out to our bolt itself
    translate([-15,chain_retainN*chain_retainDY])
        circle(d=sparbolt+2*XrollerW);
}

// Space around load cell
module Xroller_loadcell(enlarge=0,raiseZ=0)
{
    translate(loadcellC+[0,0,raiseZ/2]) {
        bevelcube(loadcellSZ+enlarge*2*[1,-0.01,1]+[0,0,raiseZ],center=true,bevel=0.5*enlarge);
    }
    loadcell_boltC(-1) { // M5 side bolts
        if (enlarge==0) 
            scale([1,1,-1]) cylinder(d=5+2*enlarge,h=13+enlarge); // thru down
        scale([1,1,+1]) cylinder(d=4.4+2*enlarge,h=13+enlarge); // tap up
    }
    loadcell_boltC(+1) { // M4 side bolts
        if (enlarge==0) 
            scale([1,1,-1]) cylinder(d=4+2*enlarge,h=13+enlarge); // thru down
        scale([1,1,+1]) cylinder(d=3.5+2*enlarge,h=13+enlarge); // tap up
    }
}
// Toggle keeps the tool holder from moving in X or Y, but leaves it free to move in Z (so the load cell reads accurately)
toggleIX = 30; // inside X width where it mates on both sides 
toggleOX = toggleIX + 2*5; // X thickness including earplates
toggle_plateC = [0,plateYS+10,toolO[2]-8]; // plate side center point
toggle_toolC = toggle_plateC + [0,toolO[1]-toggle_plateC[1]-18,0]; // tool side center point
toggle_pivots=[toggle_plateC,toggle_toolC]; // centers of both pivot points

toggle_pivotID = 5.0; // pivots on a 5mm steel shaft
toggleW = 2.5; // wall thickness around ears
toggle_earOD = toggle_pivotID+2*toggleW; // YZ size of ears
toggle_slotOD = 18; // Y thickness of gap around ears

/* Top-down cross section of toggle */
module Xroller_toggleXY2D(enlarge=0) {
    round=6;
    offset(r=-round) offset(r=+round+enlarge)
    difference() {
        hull() {
            for (end=toggle_pivots) translate(end)
                square([toggleOX,toggle_earOD],center=true);
        }
        
        // Slots in both ends (with a little assembly room)
        for (end=toggle_pivots) translate(end)
            square([toggleIX+0.4,toggle_slotOD],center=true);
    }
}

/* Side cross section of toggle:
   Rotated after extrude so X->Z, Y->Y
 */
module Xroller_toggleZY2D(enlarge=0) {
    ends = [
        [toggle_plateC[2],toggle_plateC[1]],
        [toggle_toolC[2],toggle_toolC[1]]
    ];
    difference()
    {
        // Overall rounded outside shape
        hull() for (end=ends) translate(end)
            circle(d=toggle_earOD);
        
        // Holes for pins (or bolts)
        for (end=ends) translate(end)
            circle(d=toggle_pivotID);
    }
}

module Xroller_toggle3D(enlarge=0) {
    intersection() {
        // XY cross section sets top-down shape
        translate([0,0,toggle_plateC[2]]) 
            linear_extrude(height=toggle_earOD+2*enlarge,convexity=4,center=true)
                Xroller_toggleXY2D(enlarge=enlarge);
        
        // ZY cross section sets side profile
        rotate([0,-90,0]) linear_extrude(height=toggleOX+2*enlarge,convexity=4,center=true)
            Xroller_toggleZY2D(enlarge=enlarge);
    }
}

// 2D shape of front of frame reinforcing and toggle holder
module Xroller_frontbars2D() {
    crossW=6; // width of crossbars
    
    joint = [0,-sparOD/2]; // place where front bars meet
    
    // Circle in middle to distribute forces
    translate(joint) circle(d=toggleIX);
    
    // Vertical down to toggle and load cell
    hull() for (p=[joint,joint+[0,-50]]) translate(p) square([toggleIX,crossW],center=true);
    
    // Thinner crossbars going to bolts
    mirrorX()
    for (target=[
            [-XrollerDX,0], // horizontal crossbar
            [-XrollerDX,+sparOD+20] // diagonals up
        ])
    hull() for (p=[joint,joint+target]) translate(p) circle(d=crossW);
    
}

// 3D shape of front of frame, without holes
module Xroller_frontframe3D_solid() {
    Xroller_extrudeXZ(+plateYS,plateYF)
    Xroller_frameround2D()
    {
        // Basic top
        difference() {
            Xroller_baseframe2D(+XrollerW,hsides=0);
            // Trim tops
            translate([0,200+XrollerDZ+sparbolt/2+XrollerW]) square([400,400],center=true);
        }
        
        // Bottom and hole
        difference() {
            union() {
                Xroller_bottomframe2D(+XrollerW);
                sliceXZ(+plateYS) Xroller_diagonalboltsW();
            }
            
            // Carve interior hole
            hull() Xroller_bottomframe2D(-XrollerS-XrollerW);
        }
    }
    
    ribW=XrollerW;
    ribZ=10; // height of ribs and frontbars over baseplate
    
    // Rib and frontbars around inside
    difference() {
        floor=2; // material remaining on bottom (for torsion stiffness)
        in=-XrollerS-XrollerW; // inside edge
        Xshift=8; Zshift=6; // adjusts bottomframe to hit parts that need support
        roundIn=5;
        difference() {
            // Outside of ribs
            roundOut=5;
            Xroller_extrudeXZ(+plateYS,+plateYF+ribZ)
                offset(r=-roundIn) offset(r=+roundIn)
                offset(r=+roundOut) offset(r=-roundOut) 
                {
                    Xroller_bottomframe2D(in+ribW,Xshift,Zshift);
                    // Taper up to top bolts
                    mirrorX() translate([-XrollerDX+16,XrollerDZ-8])
                        circle(r=8);
                }
            
            // Inside holes in ribs
            difference() {
                Xroller_extrudeXZ(+plateYS+floor,+plateYF+ribZ)
                    offset(r=+roundIn) offset(r=-roundIn)
                        difference() {
                            Xroller_bottomframe2D(in,Xshift+2,Zshift);
                            Xroller_frontbars2D();
                        }
                // Don't remove material around the bearings
                Xroller_bearing_space(ribW);
            }
        }
        // Carve gap in the thick center block
        walls=4;
        difference() {
            Xroller_extrudeXZbevel(+plateYS+floor,+plateYF+ribZ-2*floor,bevel=floor)
                offset(r=+roundIn) offset(r=-roundIn-walls)
                    intersection() {
                        Xroller_bottomframe2D(in,Xshift,Zshift);
                        Xroller_frontbars2D();
                    }
            // Don't remove material around the toggle axle
            translate(toggle_plateC) cube([2*inch,8,8],center=true);
        }
    }
    // Extra material around the load cell
    intersection() {
        Xroller_loadcell(XrollerW,5);
        difference() {
            // Limit to back side
            translate(loadcellC+[0,-loadcellSDY/2,0])
                cube([100,25,100],center=true);
            // Space for wires on left
            hull() for (shift=[0:4])
            translate(loadcellC+[-loadcellSZ[0]/2,-loadcellSDY/2+12-shift,0])
                sphere(d=loadcellSZ[0]+0.5);
        }
    }
    
    Xroller_diagonalboltsW();
    
    // Meat around little rollers
    Xroller_bearing_rod(+1,XrollerW);
    
    // Chain attach plates
    Xroller_chain_attachC()
        chain_retain_plate3D() Xroller_chain_bolt2D();
    
    // Tapered transitions out of chain attach plates.
    //  These are just a cone, intersected with an extended extrusions
    taper=13;
    OD = sparbolthex+2*XrollerW;
    // Taper frontside
    intersection() {
        Xroller_extrudeXZ(-100,200)
            Xroller_bottomframe2D(+XrollerW);
        
        mirrorX() translate(Xroller_center_points[0]+[0,plateYS,0])
            rotate([-90,0,0])
                cylinder(d1=OD+2*taper,d2=OD,h=taper);
    }
    // Taper backside
    intersection() {
        round=5;
        Xroller_chain_attachC()
            linear_extrude(height=200,center=true,convexity=6)
            difference() {                    
                chain_retain2D() Xroller_chain_bolt2D();
                square([0.55*inch,100],center=true); // chain outer plates
            }
        taper=7.5;
        mirrorX() translate(Xroller_center_points[0]+[0,plateYS,0])
            rotate([-90,0,0])
                cylinder(d1=OD,d2=OD+taper,h=taper);
    }
    
    
}

// 3D shape of front of frame, full with holes
module Xroller_frontframe3D() {
    difference() {
        Xroller_frontframe3D_solid();

        Xroller_bearing_rod(+1,0,50);
        Xroller_bearing_space();
        // Space to insert bearings from below
        translate([0,-4,0])
            bearingY_centers() bearing3D(bearingY,clearance=1.5,center=true);
        
        Xroller_bolts();
        
        Xroller_loadcell();
        
        translate(toggle_plateC) rotate([0,90,0])
            cylinder(d=toggle_pivotID,h=100,center=true);
        
        if (is_undef(entire)) Xroller_diagonalboltsC()
            threaded_rod(d=sparbolt,pitch=sparbolt_pitch,h=1*inch,anchor=BOTTOM);
        
        // Trim bottom flat
        translate([0,-200+plateYS,0]) cube([400,400,400],center=true);
    }
}


// Put children at centers of load cell mounting bolts
module loadcell_boltC(sides=[-1,+1])
{
    translate(loadcellC) {
        for (s=sides) translate([0,s*(loadcellSDY/2),0])
            for (bolt=[-1,+1]) translate([0,bolt*loadcellBDY,0])
                children();
    }
}

// Hollow inside bullet shaped tool holder
bullet_clearOD = 1.0*inch;

// Bullet shaped tool holder, without holes
module Xroller_bullet_solid() 
{
    // Tapered top tool holder
    translate(toolO) rotate(toolR) bullet_holder(bullet_clearOD);
    
    // Carrier coordinates tool endstop
    lip=sparOD/2-sparIR; // stop tool's vertical travel here
    stopSZ=[2*sparIR+2*lip,2*sparIR+lip,2.5];
    stopC=toolO+[0,+lip/2,-stopSZ[2]/2+0.01];
    
    translate(stopC) bevelcube(stopSZ,center=true,bevel=5,bz=0);
    
    // Carrier coordinates toggle pivot point
    toggleplusY=22; // extra Y thickness around toggle
    toggleC=toggle_toolC+[0,toggleplusY/2,0];
    toggleSZ=[toggleIX,2*toggleplusY,25];
    toggleB=3; // bevel on sides
    
    hull() {
        difference() {
            union() {
                translate(toggleC) bevelcube(toggleSZ,center=true,bevel=toggleB);

                Xroller_loadcell(XrollerW);
            }
            // Chop everything off flush with tool face
            translate(toolO + [0,-200-sparIR,0]) cube([400,400,400],center=true);
        }
    }
}

// Bullet shaped tool holder, finished version
module Xroller_bullet() {
    difference() {
        Xroller_bullet_solid();
        
        translate(toolO) sphere(d=bullet_clearOD,$fn=8);
        
        Xroller_loadcell();
        
        // Drill this to size, and press in a 5mm shaft pivot
        translate(toggle_toolC) rotate([0,90,0]) cylinder(d=5,h=50,center=true);
    }
}

// Printable versions of parts above, with Z in the right direction
module printable_frontframe() {
    rotate([90,0,0]) translate([0,-plateYS,0]) Xroller_frontframe3D();
}
module printable_backframe() {
    rotate([-90,0,0]) translate([0,+plateYS,0]) Xroller_backframe3D();
}
module printable_toggle() {
    rotate([0,-90,0]) translate([+toggleOX/2,0,0]) Xroller_toggle3D();
}
module printable_bullet() {
    rotate([90,0,0]) translate(-toolO+[0,sparIR,0]) Xroller_bullet();
}

// Demonstrate all parts of the X roller
module Xroller_demo(spar=1) {
    Xroller_frontframe3D();
    Xroller_backframe3D();
    Xroller_toggle3D();
    Xroller_bullet();
    
    if (spar) #rotate(Xroller_sparR) linear_extrude(height=300,center=true) spar2D();
    #bearingY_centers() bearing3D(bearingY,center=true);
    #Xroller_bolts();
    #Xroller_diagonalboltsC() cylinder(d=sparbolt,h=4*inch);
    #for (end=toggle_pivots) translate(end) rotate([0,90,0])
        cylinder(d=toggle_pivotID,h=50,center=true);
    
    #translate(loadcellC) cube(loadcellSZ,center=true);
    #loadcell_boltC() cylinder(d=4,h=20,center=true);
    
}
 

if (is_undef(entire)) 
{
    //Xroller_demo();
    
    //printable_frontframe();
    printable_backframe();
    
    //printable_toggle();
    
    //printable_bullet();
}


 
 
 
