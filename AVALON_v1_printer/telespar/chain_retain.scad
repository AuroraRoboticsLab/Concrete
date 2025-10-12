/*
 Bolt-on structures that hold on to #40 roller chain.
 
 
*/
include <interfaces.scad>;
include <BOSL2/std.scad>
include <BOSL2/threading.scad>


// Thickness of plastic around bolts in Z axis chain holder bracket
Zchain_holder_thick=14;

retainOD=3/8*inch+0.2; // retaining bolt outside diameter (plus some print clearance)
retainP=1/16*inch; // bolt thread pitch (16 TPI)

// Centerline of Z axis chain loop, relative to Y spar
Zchainedge = [-chainC[0]-chain_sprocketR,chainC[2],0] + [ZrollerDX+sparOD,0,-0.70*inch+Zchain_holder_thick/2];
echo("Zchain edge: ",Zchainedge);

// Make hollow space for a retaining bolt of this total length to thread in.
//   Bolt faces along +X direction, starting at the origin.
//   Bolts are to transmit mechanical forces to the attached spar
module retain_bolt(total_len, thread_len=1.5*inch, extra_len=1/4*inch)
{
    threadstart = total_len+extra_len-thread_len;
    rotate([0,90,0]) {
        // Smooth base of bolt
        cylinder(d=retainOD,h=threadstart);
        
        // Tapered transition to threads
        translate([0,0,threadstart]) {
            taper=3;
            cylinder(d1=retainOD,d2=retainOD-taper,h=taper);
        }
        
        // Threads (backed off one turn for smoother startup)
        translate([0,0,threadstart-retainP]) {
            if (is_undef(entire)) 
                threaded_rod(d=retainOD,pitch=retainP,h=thread_len+retainP,anchor=BOTTOM);
            else // higher speed approximation
                cylinder(d=retainOD,h=thread_len);
        }
    }
    
}

// Cross section of Z axis chain holder
module Zchain_holder2D() {
    round=12; // round inside corners, for strength
    roundo=3; // round outside corners, for aesthetics
    
    offset(r=+roundo) offset(r=-roundo)
    offset(r=-round) offset(r=+round)
    union() {
        // back plate holds everything
        translate([+sparOD/2,-Zchain_holder_thick/2]) {
            square([0.8*inch,1*inch+Zchain_holder_thick]);
        }
        
        // Material around long bolt
        translate([+sparOD/2,1*inch-Zchain_holder_thick/2]) {
            square([3*inch,Zchain_holder_thick]);
        }
        
        // Smooth transition up to chain plate
        translate(Zchainedge+[-8,-chain_thickness*0.5]) scale([-1,1])
            square([25,chain_thickness*0.9]);
    }
}

// Z axis holder: secured to Y axis spars with two bolts.  
//   Long outside bolt transmits forces.
//   Short 2.5" inside bolt stops rotation. (flush with Z spar face)
module Zchain_holder() {
    difference() {
        union() {
            // Basic outline
            linear_extrude(height=Zchain_holder_thick,center=true,convexity=4) 
                Zchain_holder2D();
            
            // Plate connecting to chain
            plateC=[-32,-Zchainedge[2]-5]; plateZ=[32,10]; // extra behind plate
            translate(Zchainedge) rotate([90,0,0]) chain_retain_plate3D()
                translate(plateC) square(plateZ);
            
            // Chamfers to blend holder-plate transition
            chamfer=10;
            intersection() {
                // XY cross section to trim chamfer (huge Z)
                linear_extrude(height=Zchain_holder_thick+2*chamfer,center=true,convexity=4) 
                    Zchain_holder2D();
                
                // Huge rounded cross chamfer (along X)
                rotate([0,90,0])
                linear_extrude(height=500,center=true,convexity=4) 
                offset(r=-chamfer) offset(r=+chamfer)
                {
                    square([Zchain_holder_thick,100],center=true);
                    #translate(Zchainedge) 
                        square([500,chain_thickness],center=true);
                }
                
                // Trim to dimensions of plate
                translate(Zchainedge) rotate([90,0,0]) chain_retain_plate3D(100.0)
                    translate(plateC) square(plateZ);
            }
        }

        // Cut in the big structural bolts
        translate([-sparOD/2,0,0]) retain_bolt(2.5*inch,extra_len=0.5*inch); 
        translate([-sparOD/2,+1.0*inch,0]) retain_bolt(5*inch);
        
        // Re-cut the small retain bolt holes (got stomped by chamfer)
        translate(Zchainedge) rotate([90,0,0]) chain_retain_holes(0.8*inch);
        
        // Make bottom be flat and version labelled
        translate([0,0,-Zchain_holder_thick/2]) {
            translate([0,0,-200]) cube([400,400,400],center=true);
            
            if (is_undef(entire)) 
            translate([+sparOD/2+0.5*inch,0.5*inch,0]) linear_extrude(height=1,center=true)
                rotate([0,0,-90]) scale([-1,1,1]) text("Zc v1A",size=5,halign="center",valign="center");

        }
    }
}

if (is_undef(entire)) 
{
    Zchain_holder();

}

