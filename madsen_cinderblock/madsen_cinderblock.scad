/*
 Cinderblock made from sintered or cast material.
 Slots cast into the brick, that do multiple duties:
    - forklift pickup spots
    - place for earth anchor with nice face out
    - place for attaching hangers with nice face toward dirt
 
 Interior volume with 1/10 scale heavy taper version is about 12cc, and requires about 24g of concrete.
 
 Original sketch by Elliot Madsen.
 CAD by Dr. Orion Lawlor, lawlor@alaska.edu, 2024-04-11 (Public Domain)
*/
include <../BOSL2/std.scad>;
include <../BOSL2/rounding.scad>;
include <../BOSL2/regions.scad>;
include <../BOSL2/skin.scad>;

// Bricksize is the spacing between bricks
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
forksize = [75,bricksize[1],szZ]; // size of gaps for forks
forkSpacing=bricksize[0]/2; // distance between fork centers
forkBevel=szZ; // steep sides to reduce slipping

// Diameter of rebar hole on fork sides
rebarOD=16;
rebarX=bricksize[1]/2; // X coordinate of holes
rebarY=rebarX; // Y coordinate of holes (near fork slots)
rebarPins=12; // size of pins holding form sides together

// Hollow spaces to reduce concrete mass

// Light taper: 3D printed or full size version
hollowWall=15; // wall thickness
hollowFloor = hollowWall; 
hollowThick=szZ+hollowFloor; // base thickness (minimum)
hollowRound=25; // corner rounding
hollowTaper=10; // core removal taper (offset)

/*
// Heavy taper: cast concrete in small size (still a pain to remove)
hollowWall=20; // wall thickness
hollowFloor = 50; 
hollowThick=szZ+hollowFloor; // base thickness (minimum)
hollowRound=25; // corner rounding
hollowTaper=45; // core removal taper (offset)    
*/

// Limit x to be between lo and hi
function limit(x,lo,hi) = max(min(x,hi),lo);

// Clamp the X coordinate
function clampX(x) = limit(x,mortarspace/2,szX-mortarspace);

// Makes a 2D grid of points, which get skinned into our 3D shape
function make_slices(loZ,offZ=0,offY=0) = [ 
    for (y=[0:stepY:1]) 
    [
        [clampX(szX),y*szY+offY,loZ],
        [clampX(0),y*szY+offY,loZ],// flat base for shape
        for (x=[0:stepX:1]) 
        [
            clampX(x*szX), y*szY,
            limit(szZ/2*(1.0-steep*cos(x*360.0*lobeX)*cos(y*360.0*lobeY))+offZ,
                0,szZ)
        ],
    ],
];

// Make one 3D slab profile ending at loZ
module make_slab(loZ,offZ=0,offY=0)
{
    skin(make_slices(loZ,offZ,offY),1);
}

// Make solid brick profile
module make_brick() 
{
    split = bricksize[2]/2;
    union() {
        make_slab(split+5,0,0.01);
        translate([0.01,0.01,bricksize[2]])
            make_slab(split-bricksize[2],-1);
    }
}

// Make forks
module forks_solid()
{
    for (side=[-1,+1]) translate([bricksize[0]/2+side*forkSpacing/2,0,0])
        hull() {
            cube([forksize[0]+2*forkBevel,2*forksize[1]+forkBevel,0.1],center=true);
            translate([0,0,forksize[2]])
                cube([forksize[0],2*forksize[1],0.1],center=true);
        }
}

// Puts children at rebar centers
module rebar_centers() 
{
    for (frontback=[0,1])
    for (side=[0,+1]) 
        translate([
            side?bricksize[0]-rebarX:rebarX,
            frontback?bricksize[1]-rebarY:rebarY,
            forksize[2]-0.01])
            children();
}

// Pins that hold form sections together
module rebar_pins() {
    rebar_centers() cylinder(d=rebarPins,h=4*rebarPins,center=true);
}


// Cuts holes to thread rebar down
module rebar_holes() 
{
    rebar_centers()
    {
        bevel=12; // slope entrance to rebar
        h = hollowFloor-bevel; 
        // Minimal taper straight segment first
        cylinder(d1=rebarOD,d2=rebarOD+1,h=h+1); 
        
        // Tapered entrance (so you can thread rebar down through stack of bricks)
        translate([0,0,h])
            cylinder(d1=rebarOD,d2=rebarOD+3*bevel,h=bevel*1.5+1);
    }
}

// Tapered slots to save concrete in middle of blocks
module block_hollows()
{
    // Reinforcing cylinder down middle (avoid crushing middle wall)
    reinforceOD=hollowWall*2.0;
    reinforcecenter=[bricksize[0]/2,bricksize[1]/2,0];

    // Can bias hole centers to set center wall thickness
    centerWall = hollowWall*1.0;
    holeXsize = bricksize[0]/2-centerWall/2 - hollowWall;
    hollowSpacing = holeXsize/2+centerWall/2;
    
    totalHeight = bricksize[2]+szZ+0.01;
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
    }
}

// Solid block, with space for mortar
module block_solid(h=bricksize[2]+szZ+1) {
    translate([bricksize[0]/2,bricksize[1]/2,h/2])
        cube([bricksize[0]-mortarspace,bricksize[1]+0.01,h],center=true);
}

module block(hollows=1) {
    difference() {
        intersection() {
            make_brick();
            //block_solid();
        }
        
        forks_solid();
        translate([0,0,bricksize[2]+szZ/2]) forks_solid();
        
        rebar_holes();
        
        if (hollows)
            block_hollows();
        //translate([0,-1,0]) cube([bricksize[0]/4-0.01,bricksize[1]/2,bricksize[2]+szZ+1]); // cutaway
    }
}

// Former tools
formerThick=10;
formerInterface=forksize[2]; // Z height of split angle


// Block former tool for top surface
module former_top() 
{
    bottom = formerInterface+0.1;
    top = bricksize[2]+szZ+formerThick;
    difference() {
        translate([0,0,bottom]) block_solid(top-bottom);
        block();
        rebar_pins();
        
        // Add former-pulling holes: M3 machine screws at 1/10 scale
        rebar_centers() translate([0,0,bricksize[2]/2]) cylinder(d=25,h=300);
        /*
        // lighten the former by adding holes
        for (x=[0.25,0.75]) translate([x*bricksize[0],bricksize[1]/2,top])
            rotate([0,0,90/4]) scale([1,1,-1]) 
                cylinder($fn=8,d1=0.75*bricksize[1],d2=0.6*bricksize[1],h=0.75*top);
        */
        //cube([0.25*bricksize[0],0.5*bricksize[1],300]);
    }
}

// Block former tool for bottom surface
module former_bottom() 
{
    difference() {
        translate([0,0,-formerThick]) block_solid(formerInterface + formerThick);
        block();
        rebar_pins();
    }
}


formerSides=10; // walls to hold in cast material
formerFlange=75; // clamping flange outside brick
formerRim=20; // clamping flange along insides
formerTop=10; // top/bottom layers
formerDiag=75; // diagonal reinforcing
formerFillOD=150; // diameter of filling hole

// Block former sides
module former_sides()
{
    x=bricksize[0]-mortarspace;
    y=bricksize[1];
    z=bricksize[2]+szZ+2*formerThick+2;
    pts = [
        [-formerFlange,0],
        [0,0],
        
        [0,y-formerDiag],
        [0,y],
        [formerDiag,y],
        
        [x+formerFlange,y]
    ];
    difference() {
        union() {
            // Walls
            linear_extrude(height=z+2*formerTop,convexity=4)
            for (i=[0:4]) 
                hull() 
                {
                    translate(pts[i]) circle(d=formerSides);
                    translate(pts[i+1]) circle(d=formerSides);
                }
            
            // Rim on bottom
            linear_extrude(height=formerTop)
                translate([0,y]) scale([1,-1,1])
                {
                    square([x,formerRim]);
                    square([formerRim,y]);
                }
            
            // Diagonal
            for (ht=[0,formerTop+z]) translate([0,0,ht])
                linear_extrude(height=formerTop)
                    hull() 
                        for (i=[2:4]) 
                            translate(pts[i]) circle(d=formerSides);
        }
        
        // Cut out holes
        translate([bricksize[0]/2,0,formerTop+z/2])
            rotate([-90,0,0]) children();
    }
}

output=1;

//block_solid();

if (output==0) block(0); // block without hollows
if (output==1) block(); // full block
if (output==2) block_hollows(); // just the inside
if (output==3) former_top(); // forms top of block
if (output==4) former_bottom(); // forms bottom of block
if (output==5) former_sides();
if (output==6) scale([-1,1,1]) former_sides() cylinder(d=formerFillOD,h=300);


