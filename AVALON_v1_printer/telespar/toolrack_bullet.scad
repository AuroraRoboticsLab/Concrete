/*
  Bullet tool-holding post, with tool rack mount at bottom.
  
  Used on the opposite side from the robot's toolhead.
*/
include <interfaces.scad>

includebullet=1; // allow bullet to be included
include <tool_bullet.scad> // tool pickup

include <BOSL2/std.scad>
include <BOSL2/threading.scad>

include <AuroraSCAD/bevel.scad>


// Put children at mounting bolt centers
module rackmount_boltC() 
{
    for (side=[-1,+1]) translate([side*0.5*inch,0,0]) children();
}

module bullet_toolrack() {
    Z = 2.0*sparIR;
    difference() {
        union() {
            translate([0,0,0]) rotate([0,180,0]) {
                bullet_holder(coreOD=1.0*inch,crossholes=0);
            }
            // Tapped space below
            hull()
                rackmount_boltC() bevelcylinder(d=sparbolt+8,h=Z,bevel=2,center=true);
        }
        
        // Threaded mount points
        if (is_undef(entire)) rackmount_boltC() 
            threaded_rod(d=sparbolt,pitch=sparbolt_pitch,h=2.0*inch);
        
        // Clearance for toolrack spar
        translate([0,0,-1.0*inch]) rotate([0,90,0])
            linear_extrude(height=100,center=true) spar2D();
        
        
        // Cutaway (demo)
        //cube([200,200,200]);
    }
}

if (is_undef(entire)) {
    rotate([0,90,0]) bullet_toolrack();
}
