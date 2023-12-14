/*
 Interlocking concrete mold: makes pavers that link together.

 Inspired directly by Lucas Samuel, in turn from Rick Ward (@rjward1775)

*/
include <BOSL2/std.scad>;
include <BOSL2/skin.scad>;

$fs=0.1; $fa=3;

R = 48.0; // radius from center to start of part
dR = 6.0; // change in radius for interlock
cospow = 1.0; // adjust flattening to corners
H = 12.0; 

anglestep=60; // angle distance between slices (hex)
//anglestep=90; // angle distance between slices (square)

num_handles=2; // 1 is doable, but a little tricky to unwind


anglecos=cos(anglestep/2+0.01); // X width of slices
anglesin=2*sin(anglestep/2+0.01); // Y width of slices

//stepX=1.0/32; stepZ=1.0/16; // medium facets
stepX=1.0/64; stepZ=1.0/32; // fine facets


// Limit x to be between lo and hi
function limit(x,lo,hi) = max(min(x,hi),lo);

// Makes a 2D grid of points, which get skinned into our 3D shape
function make_slices(dz,phase,outsetR=0,outsetZ=0) = [ 
    for (z=[0:stepZ:1]) 
    [
        [0,0,z*H],
        for (x=[-0.5:stepX:0.5]) 
        [
            (R+outsetR)*anglesin*x,
            (R+outsetR)*anglecos 
                + phase*cos(limit(z*180.0+dz,0.0,180.0))*dR*pow(cos(x*180.0),cospow),
            -outsetZ + (H + 2*outsetZ)*z
        ],
    ],
];

// Make one 3D slice
module make_slice(angle,dz,phase,outsetR=0,outsetZ=0)
{
    rotate([0,0,angle])
        skin(make_slices(dz,phase,outsetR,outsetZ),1);
}

// Make a full 3D set (solid)
module make_set(outsetR=0,outsetZ=0)
{
    dz=5; //<- degrees of vertical space on mating surfaces
    for (angle=[anglestep/2:2*anglestep:360-1]) rotate([0,0,angle])
    {
        make_slice(         0,-dz, -1, outsetR,outsetZ);
        make_slice( anglestep,+dz, +1, outsetR,outsetZ);
    }
}

// Make a sealing handle, to split the part after casting
module make_handle(width,holes=0,height=H/2)
{
    for (angle=[0:360/num_handles:360-1]) rotate([0,0,angle])
    {
        inset=2; // start parts this far in, so they're solid
        translate([0,R+height/2-inset/2,H/2])
        {
            cube([width,height+holes*2+inset,H],center=true);
            
            rotate([0,90,0]) cylinder(d=2,h=10,center=true); // for copper wire
        }
    }
}

// Make printable 3D perimeter wall
module make_wall(wall=2)
{
    difference() {
        union() {
            make_set(wall,0);
            make_handle(2*wall);
        }
        make_set(0.0,0.01);
        make_handle(0.2,1);
    }
}


make_wall();



