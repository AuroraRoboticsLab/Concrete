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

    
 Coordinate system used in this file:
   Z: up and down
   Y: across spar, +Y toward tools
   X: along spar

Orion Lawlor, lawlor@alaska.edu, 2025-10-10 (Public Domain)
*/

include <roller_frame.scad> //<- basic frame

includebullet=1; // allow bullet to be included
include <tool_bullet.scad> // tool pickup



// Start of plastic from spar centerline (X axis plate, distance along Y axis)
plateXS = sparOD/2+2;
plateXF = 5.0; // floor thickness of plate in front (also gets a bunch of ribs and such)
plateXB = 6.0; // floor thickness of back plate



// Origin of base of tool pickup (bullet)
toolO = [0,4*inch,-1.5*inch];
toolR = [90,0,0];

// Center of load cell
loadcellC = [0,plateXS+loadcellSZ[1]/2,-80];


// 2D solid outline of bottom roller frame, including the load cell
module Xroller_bottomframe2D(enlarge=0,Xshift=0,Zshift=0) {
    offset(r=+enlarge) hull()
    {
        mirrorX() for (p=rframe_center_points) 
            translate(projectY(p)+[Xshift,(p[2]>0?1:-1)*Zshift])
                circle(d=sparbolt);
        translate(projectY(loadcellC)+[0,-Zshift]) square(projectY(loadcellSZ),center=true);
    }
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
        cylinder(d=sparbolt + 2*rframeW,h=4.1*inch);
}

// Back frame electronics box mount holes
module Xroller_backframe_EmountC() {
    mirrorX() mirrorZ() translate([-1*inch,-plateXS-plateXB+0.01,-1.25*inch])
        rotate([90,0,0])
            children();
}

// 3D shape of back frame
module Xroller_backframe3D() {
    difference() {
        union() {
            rframe_extrudeXZ(-plateXS-plateXB,plateXB) 
                rframe_frameround2D() {
                    rframe_baseframe2D(enlarge=rframeW);
                    sliceXZ(-plateXS) Xroller_diagonalboltsW();
                }
            // Heavier plate on top (avoid weakness around bearing rods
            rframe_extrudeXZ(-plateXS-2*plateXB,2*plateXB) 
                rframe_heavyplate();
            
            translate([0,0,2]) //<- close gap on top, continuous part
            rframe_bearing_retain(-1,rframeW,-plateXS-plateXB,extraZ=2);
            
            
            Xroller_diagonalboltsW();
            
            Xroller_backframe_EmountC() 
                scale([1.5,1,1]) cylinder(d1=15,d2=8,h=10);
        }
        
        rframe_bearing_rod(-1,0,50,exit=1);
        rframe_bearing_space();
        
        rframe_bolts();
        
        // Cut threads that match the front plate for diagonal bolts:
        if (is_undef(entire)) Xroller_diagonalboltsC() translate([0,0,3*inch])
            threaded_rod(d=sparbolt,pitch=sparbolt_pitch,h=1.5*inch,anchor=BOTTOM);
        
        // Tap these electronics box mount points for M5 screws
        Xroller_backframe_EmountC() cylinder(d=4.4,h=50,center=true);
        
        // Trim bottom flat
        translate([0,200-plateXS,0]) cube([400,400,400],center=true);
    }
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
toggle_plateC = [0,plateXS+10,toolO[2]-8]; // plate side center point
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
            [-rframeDX,0], // horizontal crossbar
            [-rframeDX,+sparOD+20] // diagonals up
        ])
    hull() for (p=[joint,joint+target]) translate(p) circle(d=crossW);
    
}

// 3D shape of front of frame, without holes
module Xroller_frontframe3D_solid() {
    rframe_extrudeXZ(+plateXS,plateXF)
    rframe_frameround2D()
    {
        // Basic top
        difference() {
            rframe_baseframe2D(+rframeW,hsides=0,trim=1);
        }
        
        // Bottom and hole
        difference() {
            union() {
                Xroller_bottomframe2D(+rframeW);
                sliceXZ(+plateXS) Xroller_diagonalboltsW();
            }
            
            // Carve interior hole
            hull() Xroller_bottomframe2D(-rframeS-rframeW);
        }
    }
    
    ribW=rframeW;
    ribZ=10; // height of ribs and frontbars over baseplate
    
    // Rib and frontbars around inside
    difference() {
        floor=2; // material remaining on bottom (for torsion stiffness)
        in=-rframeS-rframeW; // inside edge
        Xshift=8; Zshift=6; // adjusts bottomframe to hit parts that need support
        roundIn=5;
        difference() {
            // Outside of ribs
            roundOut=5;
            rframe_extrudeXZ(+plateXS,+plateXF+ribZ)
                offset(r=-roundIn) offset(r=+roundIn)
                offset(r=+roundOut) offset(r=-roundOut) 
                {
                    Xroller_bottomframe2D(in+ribW,Xshift,Zshift);
                    // Taper up to top bolts
                    mirrorX() translate([-rframeDX+16,rframeDZ-8])
                        circle(r=8);
                }
            
            // Inside holes in ribs
            difference() {
                rframe_extrudeXZ(+plateXS+floor,+plateXF+ribZ)
                    offset(r=+roundIn) offset(r=-roundIn)
                        difference() {
                            Xroller_bottomframe2D(in,Xshift+2,Zshift);
                            Xroller_frontbars2D();
                        }
                // Don't remove material around the bearings
                rframe_bearing_space(ribW);
            }
        }
        // Carve gap in the thick center block
        walls=4;
        difference() {
            rframe_extrudeXZbevel(+plateXS+floor,+plateXF+ribZ-2*floor,bevel=floor)
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
        Xroller_loadcell(rframeW,5);
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
    rframe_bearing_retain(+1,rframeW,+plateXS+plateXF);
    
    // Chain attach plates
    rframe_chain_attachC()
        chain_retain_plate3D() rframe_chain_bolt2D();
    
    // Tapered transitions out of chain attach plates.
    //  These are just a cone, intersected with an extended extrusions
    taper=13;
    OD = sparbolthex+2*rframeW;
    // Taper frontside
    intersection() {
        rframe_extrudeXZ(-100,200)
            Xroller_bottomframe2D(+rframeW);
        
        mirrorX() translate(rframe_center_points[0]+[0,plateXS,0])
            rotate([-90,0,0])
                cylinder(d1=OD+2*taper,d2=OD,h=taper);
    }
    // Taper backside
    intersection() {
        round=5;
        rframe_chain_attachC()
            linear_extrude(height=200,center=true,convexity=6)
            difference() {                    
                chain_retain2D() rframe_chain_bolt2D();
                square([0.55*inch,100],center=true); // chain outer plates
            }
        taper=7.5;
        mirrorX() translate(rframe_center_points[0]+[0,plateXS,0])
            rotate([-90,0,0])
                cylinder(d1=OD,d2=OD+taper,h=taper);
    }
    
    
}

// 3D shape of front of frame, full with holes
module Xroller_frontframe3D() {
    difference() {
        Xroller_frontframe3D_solid();

        rframe_bearing_rod(+1,0,50);
        rframe_bearing_space();
        // Space to insert bearings from below
        translate([0,-4,0])
            bearingY_centers() bearing3D(bearingY,clearance=1.5,center=true);
        
        rframe_chain_attachC() chain_retain_holes();
        rframe_bolts();
        
        Xroller_loadcell();
        
        translate(toggle_plateC) rotate([0,90,0])
            cylinder(d=toggle_pivotID,h=100,center=true);
        
        if (is_undef(entire)) Xroller_diagonalboltsC()
            threaded_rod(d=sparbolt,pitch=sparbolt_pitch,h=1*inch,anchor=BOTTOM);
        
        // Trim bottom flat
        translate([0,-200+plateXS,0]) cube([400,400,400],center=true);
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

                Xroller_loadcell(rframeW);
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
    rotate([90,0,0]) translate([0,-plateXS,0]) Xroller_frontframe3D();
}
module printable_backframe() {
    rotate([-90,0,0]) translate([0,+plateXS,0]) Xroller_backframe3D();
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
    
    if (spar) #rotate(rframe_sparR) linear_extrude(height=300,center=true) spar2D();
    #bearingY_centers() bearing3D(bearingY,center=true);
    #rframe_bolts();
    #Xroller_diagonalboltsC() cylinder(d=sparbolt,h=4*inch);
    #for (end=toggle_pivots) translate(end) rotate([0,90,0])
        cylinder(d=toggle_pivotID,h=50,center=true);
    
    #translate(loadcellC) cube(loadcellSZ,center=true);
    #loadcell_boltC() cylinder(d=4,h=20,center=true);
    
}
 

if (is_undef(entire)) 
{
    Xroller_demo();
    
    //printable_frontframe();
    //printable_backframe();
    
    //printable_toggle();
    
    //printable_bullet();
}


 
 
 
