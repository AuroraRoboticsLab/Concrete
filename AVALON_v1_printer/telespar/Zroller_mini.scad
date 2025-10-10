/*
 Z axis corner roller model, miniature version with 5mm shaft and 625 bearings.
 
*/

include <interfaces.scad>;
include <AuroraSCAD/bearing.scad>;
include <AuroraSCAD/bevel.scad>;
include <BOSL2/std.scad>
include <BOSL2/threading.scad>

// Bearings that let the Z roller spin under load
bearing = bearing_625;
ZaxleOD = 5; // 5mm shaft is axle

// Coordinate system centered on Z roller centerline
module ZrollerC() {
    translate([0,ZrollerDX+sparOD])
        rotate([0,0,-45])
            translate([ZrollerSX,0,0])
                rotate([90,0,0])
                    children();
}

// Z roller 2D cross section
module Zroller2D(holes=1) {
    difference() {
        round=1;
        offset(r=+round) offset(r=-round)
        difference()
        {
            intersection() {
                square([ZrollerSX, ZrollerZ],center=true);
                
                // Clearance around bolted-on spar
                rotate([0,0,45])
                    square(ZrollerMD*[1,1],center=true);
            }
            
            // Cut V shaped Z axis spar space
            translate([ZrollerSX,0,0])
                rotate([0,0,-45])
                        spar2D();
        }
        
        if (holes) {
            // Axle space
            square([ZaxleOD+2,200],center=true);
            
            // Bearing space
            bearing_clearance=0.2;
            offset(r=bearing_clearance)
            for (topbot=[-1,+1]) scale([1,topbot,1])
                translate([0,ZrollerZ/2])
                {
                    // Bearing itself
                    square([bearingOD(bearing),2*bearingZ(bearing)],center=true);
                    // Space above bearing
                    square([bearingOD(bearing)-3,2*bearingZ(bearing)+2],center=true);
                }        
        }
            
        // Delete left half for rotate_extrude
        translate([-100,0,0]) square([200,200],center=true);
    }
}

// Z roller 3D revolved
module Zroller3D() {
    rotate_extrude()
        Zroller2D();
}

// Add children at centers of Z roller holder mounting bolts
module Zroller_bolt_centers() {
    // inner bolt
    translate([0,sparOD/2,0]) rotate([-90,0,0])
        children();

    // outer bolt
    translate([2.0*inch,sparOD/2,0]) rotate([-90,0,0])
        children();
    
}

// All Z roller bolts, with this enlargement
module Zroller_bolts_all(enlarge=0,extraZ=0,bolts=1) {
    ZaxleL=1.5*inch; // roller shaft length
    boltL=0.75*inch; // bolt threaded length
    
    // Axle for roller
    ZrollerC() translate([0,0,-ZaxleL/2-enlarge])
        bevelcylinder(d=ZaxleOD+2*enlarge,h=ZaxleL+2*enlarge+extraZ,bevel=enlarge*0.7);
       
    
    // Mounting bolts
    if (bolts)
    Zroller_bolt_centers()  translate([0,0,-enlarge-extraZ])
        bevelcylinder(d=Zroller_bolt+2*enlarge,h=boltL+2*enlarge+extraZ,bevel=enlarge*0.7); 
}

// Holds Zroller
module Zroller_holder() {
    wall=2.4; // plastic around threads or axle
    clear=1.0; // clearance around moving roller
    
    difference() {
        union() {
            hull() Zroller_bolts_all(enlarge=wall);

            // Big heavy lump to stop roller from pivoting
            translate([1*inch,sparOD/2-wall]) rotate([-90,0,0]) 
                scale([1.75,1.0,1]) // stretch
                bevelcylinder(d=1.3*inch,h=1.2*inch,bevel=wall*0.7);
        
            // Thin shroud to keep debris out
            shroud=clear+wall/2;
            ZrollerC() 
                    bevelcylinder(d=ZrollerMD+2*shroud,h=ZrollerZ+2*shroud,bevel=3,center=true);
        }
        // Insert the axle here
        Zroller_bolts_all(enlarge=0.2,extraZ=20,bolts=0);
        // Drive the axle back out here
        ZrollerC() cylinder(d=ZaxleOD-1.5,h=100,center=true);
        
        // Actual threaded bolt holes
        Zroller_bolt_centers() translate([0,0,-wall-1])
        {
            OD=3/8*inch-0.1;
            len=1.5*inch;
            if (is_undef(entire))
                threaded_rod(d=OD,pitch=1/16*inch,length=len,anchor=BOTTOM);
            else // faster simpler version
                cylinder(d=OD,h=len);
        }
        
        
        // Make space to insert the roller
        ZrollerC() difference() {
            hull() {
                for (insert=[0,1]) translate([-insert*20,0,0])
                    bevelcylinder(d=ZrollerMD+2*clear,h=ZrollerZ+2*clear,bevel=3,center=true);
            }
            // Securely hold the bearings from the inside
            taper=3;
            for (topbot=[-1,+1]) scale([1,1,topbot])
                translate([0,0,ZrollerZ/2])
                    cylinder(d1=ZaxleOD+3,d2=ZaxleOD+3+2*taper,h=taper);
        }
        
        // Make space for other spar
        sparClear=3.0;
        linear_extrude(height=100,center=true)
            translate([0,ZrollerDX+sparOD]) 
                for (angle=[0,90]) rotate([0,0,angle])
                    spar2Dbolts(enlarge=sparClear);
        
        // Trim base flat to bolt against spar
        translate([0,-200+sparOD/2,0]) cube([400,400,400],center=true);
    }
}


module Zroller_demo(cuataway=1) {
    scale([5,1,1]) spar2D();
    translate([0,sparOD/2+ZrollerDX+sparOD/2]) spar2D();
    difference() {
        union() {
            Zroller_holder();
            ZrollerC() Zroller3D();
        }
        if (cutaway) cube([100,100,100]);
    }
}

// 3D printable configuration for parts
module printable_Zroller_holder() {
    rotate([90,0,0]) translate([0,-sparOD/2]) Zroller_holder();
}

module printable_Zroller3D() {
    translate([-40,0,ZrollerZ/2]) Zroller3D(); 
}

if (is_undef(entire)) { // show the part
    //Zroller2D();
    //Zroller_demo();
    printable_Zroller_holder();
    printable_Zroller3D();
}


