/*
 Cinderblock made from sintered or cast material.
 Slots cast into the brick, that do multiple duties:
    - forklift pickup spots
    - place for earth anchor with nice face out
    - place for attaching hangers with nice face toward dirt
 
 Original sketch by Elliot Madsen.
 CAD by Dr. Orion Lawlor, lawlor@alaska.edu, 2024-04-11 (Public Domain)
*/
include <../BOSL2/std.scad>;
include <../BOSL2/rounding.scad>;
include <../BOSL2/regions.scad>;
include <../BOSL2/skin.scad>;

bricksize = [400,200,200]; // approximately US cinder block size, 16 x 8 x 8 inches
mortarspace = 2; // space for mortar between bricks (+-X ends)

// Parameters of wavy brick-brick interface
//stepX=1.0/16; stepY=1.0/8; // coarse facets
//stepX=1.0/64; stepY=1.0/32; // medium facets
stepX=1.0/128; stepY=1.0/64; // fine facets
szX=bricksize[0];
szY=bricksize[1];
szZ=20;
lobeX=2;
lobeY=1;
steep=3; // makes Z change steeper (sets interface angle)

// Size of forks for a forklift pickup spot
forksize = [75,bricksize[1]-50,szZ]; // size of gaps for forks
forkSpacing=bricksize[0]/2; // distance between fork centers
forkBevel=szZ/2; // steep sides to reduce slipping

// Diameter of rebar hole on fork sides
rebarOD=16;
rebarY=50; // Y coordinate of holes (near fork slots)

// Hollow spaces to reduce concrete mass
hollowWall=15; // wall thickness
hollowThick=szZ+hollowWall; // base thickness (minimum)
hollowRound=20; // corner rounding
hollowTaper=5; // core removal taper (offset)
hollowTaperScale=0.9; // core removal taper (lame scale version)


// Limit x to be between lo and hi
function limit(x,lo,hi) = max(min(x,hi),lo);

// Makes a 2D grid of points, which get skinned into our 3D shape
function make_slices(loZ,offZ=0) = [ 
    for (y=[0:stepY:1]) 
    [
        [szX,y*szY,loZ],
        [0.0,y*szY,loZ],// flat base for shape
        for (x=[0:stepX:1]) 
        [
            x*szX, y*szY,
            limit(szZ/2*(1.0+steep*cos(x*360.0*lobeX)*cos(y*360.0*lobeY))+offZ,
                0,szZ)
        ],
    ],
];

// Make one 3D slab profile ending at loZ
module make_slab(loZ,offZ=0)
{
    skin(make_slices(loZ,offZ),1);
}

// Make solid brick profile
module make_brick() 
{
    split = bricksize[2]/2;
    union() {
        make_slab(split+1,0);
        translate([0,0,bricksize[2]])
            make_slab(split-bricksize[2],-1);
    }
}


module forks_solid()
{
    for (side=[-1,+1]) translate([bricksize[0]/2+side*forkSpacing/2,0,0])
        hull() {
            cube([forksize[0]+2*forkBevel,2*forksize[1]+2*forkBevel,0.1],center=true);
            translate([0,0,forksize[2]])
                cube([forksize[0],2*forksize[1],0.1],center=true);
        }
}

module rebar_holes() 
{
    // Rebar holes
    for (side=[-1,+1]) 
        translate([bricksize[0]/2+side*bricksize[0]/4,rebarY,
            forksize[2]-0.01])
            {
                h = hollowWall/2; 
                // Minimal taper straight segment first
                cylinder(d1=rebarOD,d2=rebarOD+1,h=h+1); 
                
                // Tapered entrance (so you can thread rebar down through stack of bricks)
                translate([0,0,h])
                    cylinder(d1=rebarOD,d2=rebarOD+3*h,h=1.5*h+1);
            }
}

module block_hollows()
{
    // Reinforcing cylinder down middle (avoid crushing middle wall)
    reinforceOD=hollowWall*2.0;
    reinforceTaper=5;
    reinforcecenter=[bricksize[0]/2,bricksize[1]/2,0];

    // Can bias hole centers to set center wall thickness
    centerWall = hollowWall*1.0;
    holeXsize = bricksize[0]/2-centerWall/2 - hollowWall;
    hollowSpacing = holeXsize/2+centerWall/2;
    
    totalHeight = bricksize[2]+szZ;
    difference() {
        for (side=[-1,+1])
            translate([0,0,totalHeight])
            scale([1,1,-1]) //rotate([180,0,0]) // flip so facing down
            {
                
                hole=move([bricksize[0]/2+side*hollowSpacing,bricksize[1]/2,0],
                    square([holeXsize,bricksize[1]-2*hollowWall],center=true));                
                    
                
                roundhole = round_corners(hole,radius=hollowRound);
                
                // use BOSL2 regions to subtract off reinforcing circle
                holeR = [roundhole];
                reinforce = move([bricksize[0]/2,bricksize[1]/2,0],
                    ellipse(d=[reinforceOD,2*reinforceOD],$fn=10)
                );
                reinforceR = [reinforce];
                diffR = difference(holeR,reinforceR);
                roundhole2=diffR[0];
                roundhole3 = round_corners(roundhole2,radius=5);
                
                
                h = totalHeight-hollowThick;
                // Hollow inside rounding profile: x is offset, y is height for that offset to apply
                profile = os_profile(points=[
                    [0,0],
                    [hollowTaper,h-1-hollowRound], // straight taper inward
                    [hollowRound*0.13+hollowTaper,h-1-hollowRound*0.5], // coarse circular curve
                    [hollowRound*0.34+hollowTaper,h-1-hollowRound*0.25],
                    [hollowRound+hollowTaper,h-1]
                ]);

                offset_sweep(roundhole3, height=h, top=profile, $fn=8); //top=os_circle(r=hollowRound), steps=8);
            }
        //translate(reinforcecenter)
        //    cylinder(d1=reinforceOD+2*reinforceTaper,d2=reinforceOD,h=totalHeight);
    }
}

module block() {
    difference() {
        intersection() {
            make_brick();
            
            h=bricksize[2]+szZ+1;
            translate([bricksize[0]/2,bricksize[1]/2,h/2])
                cube([bricksize[0]-mortarspace,bricksize[1],h],center=true);
        }
        
        forks_solid();
        
        rebar_holes();
        
        block_hollows();
        
        //cube([bricksize[0]/4,bricksize[1]/2,bricksize[2]+szZ]); // cutaway
    }
}


if (0)  // just the inside
    block_hollows();
else // full block
    block();
    