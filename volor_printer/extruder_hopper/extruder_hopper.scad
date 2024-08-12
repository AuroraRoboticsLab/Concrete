/*
3D printed hopper for a concrete / mortar / clay extruder


2024-08-09 version:

Uses a section of welded 2 inch diameter steel earth auger to push concrete down:
    https://www.amazon.com/gp/product/B09MFB84WR/

This is welded onto a 1/2" steel bolt.  The bolt's hex head drives the inducer stir bar.  The top of the bolt drilled so a pull pin can clip it to the top of the drive gear.

The lower half of the auger is surrounded by a 2 inch schedule 40 PVC pipe.  Nominal size, actual OD is 60.4mm.

The nozzle threads onto a 2 inch PVC slip x thread adapter, so the nozzle threads into 2 inch FPT.

PVC cement does seem to successfully join PVC plastic pipe and PETG prints (Weld-On 700 tested with Overture black PETG).

A NEMA17 stepper at 24VDC doesn't quite have enough torque to break sand particles at 10:1 gear reduction.  Constraints:
    - There's up to 20mm of vertical space for a gear on the output shaft
    - Could pin the gear onto the shaft with a 3mm dia, 32mm long pin (slides in and clips on?)
    - Intermediate stage needs a shaft: 10mm bushings on 8mm (5/16") shaft?


Design by Dr. Orion Lawlor, lawlor@alaska.edu, 2024-08 (Public Domain)
*/
include <BOSL2/std.scad> /* https://github.com/BelfrySCAD/BOSL2/ */
include <BOSL2/gears.scad> /* for drive gears */
include <BOSL2/threading.scad> /* for pipe thread on auger barrel */

$fs=0.1; $fa=5;

inch=25.4; // file units are mm


// Replace [x,y,z] with [x,y,newz]
function replaceZ(p,newz) = [p[0], p[1], newz];


// Auger barrel parameters
clearance=0.2; //<- space around printed parts so they can be assembled

// Pipe size at nozzle
nozzle_pipe_size = 2; // inch nominal pipe thread for nozzle
nozzle_pipe_OD = 2.32 * inch+0.5;
nozzle_pipe_ID = 2*inch + 2;

// Pipe size around auger
pipe_OD = 60.6+2*clearance; // outside diameter of pipe, with a little clearance
pipe_coupler_OD = 69.4 + 2*clearance; // diameter of pipe coupler
pipe_ID = 2*inch + 1; // inside diameter of pipe (for flow paths)

pipe_thread_Z=24; // height of end of threaded zone


// Auger itself
auger_thread_pitch=40; // mm between full turns
auger_thread_centerID=9; // central screw (plus some clearance)
auger_thread_edgeOD=25; // edge cross section thickness (plus some clearance)
auger_thread_OD=51; // outside diameter of auger (plus a bit of clearance)

auger_hex_flats=0; // 11.1; // across the flats of hex shaft on auger (0 if round)
//auger_hex_len=30; // length of auger's hex flats
auger_shaft_OD = 1/2*inch; // diameter of auger shaft
auger_pin_OD = 1/8*inch; // diameter of hole for retaining pin
auger_pin_len = 32; // space around auger pin
auger_pin_Z = 57; // mm between auger bolt flats and pin hole



// Stepper mount dimensions
// NEMA 17
stepper_NEMA=17; // identifier
stepper_boltOD=3.5; // bolt hole size, M3 taps up into stepper
stepper_boltXY=31.0/2; // distance in XY between holes
stepper_frameXY=42.5; // overall outside size of box
stepper_holeOD=22.5; // central hole
stepper_shaftOD=5.1; // shaft where drive gear sits
stepper_height = 55; // Z height of stepper hole

stepper_old_frameXY=42.5; // historic stepper size, for backward compatibility

/*
// NEMA 23: stepper mass is 1.5kg
stepper_NEMA=23; // identifier for stepper size
stepper_boltOD=4.3; // bolt hole size, M5 taps down into plastic
stepper_boltXY=47.2/2; // distance in XY between holes
stepper_frameXY=57.2; // overall outside size of box
stepper_holeOD=38.4; // central hole, plus some clearance
stepper_shaftOD=10.1; // shaft where drive gear sits
*/


// Tap plastic for M3 screw at this diameter
M3_tapID = 2.3;
M3_shaftOD = 3.1;
M3_thru = 3.6;
M3_headOD = 6.1;
M3_headZ = 3.2;

M3_insertOD=3.8; // space for heat-insert bit
M3_insertZ=6;

/* --------------- Geartrain ------------------
 Gear1: output gear on auger
 
 Gear2: input gear on stepper
*/
gear_clearance=0.1;

gear1_module=1.5; // large teeth for robustness and easy printing
gear1_teeth_drive=10; 
gear1_teeth_auger=gear1_teeth_drive*6; // torque amplification factor
gear1_thickness=16;

gear_taper=2; // Z taper leading into each gear
gear12_space=gear_taper; // space between levels 1 and 2

gear2_module=1.25; // smaller teeth on stepper side (to fit more teeth)
gear2_teeth_stepper=8; // few teeth on stepper side
gear2_teeth_reducer=gear2_teeth_stepper*6;
gear2_thickness=10;


gear1_augerR = outer_radius(teeth=gear1_teeth_auger, mod=gear1_module);
gear1_driveR = outer_radius(teeth=gear1_teeth_drive, mod=gear1_module);
gear2_reducerR = outer_radius(teeth=gear2_teeth_reducer, mod=gear2_module);
gear2_stepperR = outer_radius(teeth=gear2_teeth_stepper, mod=gear2_module);


gearZ_floor = 2.5; // base plate on top of hopper print
gearZ_auger = gearZ_floor + 1.5; // washer spaces auger gear over floor

gearZ2_floor = gearZ_auger + gear1_thickness + gear12_space; // Z start of gearplane 2
gearZ_stepper = gearZ2_floor + gear2_thickness + 12; // face of stepper, to let stepper's shaft reach drive gear



gear12_axle = [0,gear_clearance + gear_dist(mod=gear1_module, teeth1=gear1_teeth_drive, teeth2=gear1_teeth_auger), 0];


// location of reducer gear axle
auger_reducer_angle=100; // angle of auger gear from reducer gear
auger_reducer_dist = gear_clearance + gear_dist(mod=gear1_module, teeth1=gear1_teeth_drive, teeth2=gear1_teeth_auger);
reducer1_center = [
    cos(auger_reducer_angle)*auger_reducer_dist,
    sin(auger_reducer_angle)*auger_reducer_dist,
    gearZ_auger];
reducer1_rotate = [0,0,0];

// absolute location of stepper gear axle top
stepper_reducer_angle=0; // angle of stepper gear from reducer gear
stepper_reducer_dist = gear_clearance + gear_dist(mod=gear2_module, teeth1=gear2_teeth_stepper, teeth2=gear2_teeth_reducer);
stepper_center = reducer1_center + [
    cos(stepper_reducer_angle)*stepper_reducer_dist, 
    sin(stepper_reducer_angle)*stepper_reducer_dist, 
    gearZ_stepper - gearZ_auger];
stepper_rotate = [0,0,0];

// historic stepper location, for baseplate and hopper compatibility
stepper_old_center = [0,56, 29];
stepper_old_rotate = [180,0,-45];



// Gear on stepper's output shaft.  Origin is base of gear, at gearZ2_floor
module gear_stepper() {
    boss_OD=16;
    boss_Z=18; // full length of stepper's shaft, minus mount plate thickness
    
    boss_tapD=M3_tapID; // tapped for M3 setscrew
    
    shaft_ID=5;
    
    translate([0,0,boss_Z])
    rotate([180,0,0])
    difference() {
        union() {
            spur_gear(teeth=gear2_teeth_stepper, mod=gear2_module, thickness=gear2_thickness+gear_taper, anchor=BOTTOM);
            translate([0,0,gear2_thickness+gear_taper-0.01]) cylinder(d=boss_OD,h=boss_Z-gear2_thickness-gear_taper);
            
            // bevel out to teeth
            translate([0,0,gear2_thickness-0.01]) cylinder(r1=gear2_stepperR-gear2_module*1.6, r2=boss_OD/2, h=gear_taper);
        }
        
        difference() {
            cylinder(d=stepper_shaftOD,h=100,center=true); // stepper's 5mm shaft (thru)
            // printable flat on stepper shaft (often prevents fitting)
            //flat_x = stepper_shaftOD/2 - 0.5; // nominal start of flat from center
            //translate([flat_x+100,0,3+100]) cube([200,200,200],center=true);
        }
        
        // sideways M3 grub screws
        grubZ = gear2_thickness + 0.5*(boss_Z + gear_taper/2 - gear2_thickness);
        for (angle=[0,90]) rotate([0,0,angle])
        translate([0,0,grubZ])
            rotate([0,90,0])
                cylinder(d=boss_tapD,h=10);
    }
}

// Rib cuts for a gear, between rI inside and rO outside.
module gear_ribs2D(rI,rO, ribcount=6, rib=6, round=6)
{
    offset(r=+round) offset(r=-round)
    difference() {
        circle(r=rO);
        circle(r=rI);
        for (ribAngle=[0:360/ribcount:180]) rotate([0,0,ribAngle])
            square([200,rib],center=true);
        children();
    }
}


// Reduction gear connects stepper to auger drive gear
module gear_reducer() {
    
    difference() {
        union() {
            translate([0,0,gearZ_auger])
                spur_gear(teeth=gear1_teeth_drive, mod=gear1_module, thickness=gear1_thickness + gear12_space + 1, anchor=BOTTOM);
            translate([0,0,gearZ2_floor])
                spur_gear(teeth=gear2_teeth_reducer, mod=gear2_module, thickness=gear2_thickness, anchor=BOTTOM);
                
            // bevel out, for strength
            translate([0,0,gearZ2_floor-gear_taper])
                cylinder(r1=10/2,r2=gear1_driveR+1,h=gear_taper);
            
        }
        
        // lighten holes/ribs
        translate([0,0,gearZ2_floor+gear2_thickness-1]) scale([1,1,-1])
        linear_extrude(height=gear2_thickness,convexity=4) 
            gear_ribs2D(gear1_driveR + 2,
                pitch_radius(teeth=gear2_teeth_reducer, mod=gear2_module) - 4,
                round=3);
        
        // shaft hole
        cylinder(d=8.0+2*clearance,h=100,center=true);
        
        // press-in bushing holes
        bushingD=10+clearance;
        bushingZ=10;
        translate([0,0,gearZ_auger])
            cylinder(d=bushingD,h=bushingZ);
        translate([0,0,gearZ2_floor+gear2_thickness-bushingZ])
            cylinder(d=bushingD,h=bushingZ);
        
    }
    
}

// Make space for auger's shaft
module auger_mount_hole() 
{
    if (auger_hex_flats>0) {
        // hex hole
        cylinder($fn=6, d=auger_hex_flats/cos(30), h=100,center=true);
    } else {
        // shaft
        cylinder(d=auger_shaft_OD,h=100,center=true);
    }
}


// Big gear on auger shaft.  Hopper origin.
module gear_auger() {
    difference() {
        union() {
            // baked-in washer to keep gear teeth above floor
            translate([0,0,gearZ_floor])
            cylinder(d=auger_shaft_OD+10,h=gear1_thickness);
            
            // Gear itself
            translate([0,0,gearZ_auger])
            difference() {
                spur_gear(teeth=gear1_teeth_auger, mod=gear1_module, thickness=gear1_thickness, anchor=BOTTOM);
                
                // lighten holes/ribs
                translate([0,0,-0.01])
                linear_extrude(height=gear1_thickness+0.02,convexity=4) 
                    gear_ribs2D(auger_shaft_OD/2 + 3,
                        pitch_radius(teeth=gear1_teeth_auger, mod=gear1_module) - 6)
                            // Add reinforcing around auger pin
                            square([auger_pin_len+20,14],center=true);
            }
        }
        // M3 screws can be added to hold the gear's layers together
        translate([0,0,gearZ_auger])
        for (screw=[-1,+1]) translate([screw*auger_pin_len*0.3,-screw*5,0])
            cylinder(d=M3_tapID,h=gear1_thickness+3);
        
        // pull pin through auger shaft
        translate([0,0,inducer_Z_cylinder + auger_hex_Z + auger_pin_Z])
        rotate([0,90,0])
        {
            // Space for shaft of pin
            hull() {
                for (extract=[0,1]) translate([-extract*20,0,0])
                    cylinder(d=auger_pin_OD,h=auger_pin_len+6,center=true);
            }
            // Space for head of pin (modified M3 screw) to slide back out
            difference() 
            {
                hull() {
                    for (extract=[[0,1],[1,1],[1,2]]) translate([-extract[0]*20,0,extract[1]*auger_pin_len/2])
                        cylinder(d=7,h=20);
                }
                // clip to retain back of head
                translate([-6,2,auger_pin_len/2 + 4])
                    cube([3,5,2]);
            }
            translate([0,0,auger_pin_len/2+4+M3_shaftOD/2])
            rotate([0,-90,0]) cylinder(d=M3_tapID,h=20,center=true);
            
            // Slot so pin's clip can deflect for add/remove
            translate([-3,0,auger_pin_len/2 - 3])
                cube([0.5,10,20]);
            
        }
        auger_mount_hole();
        
    }
}


hopper_bearing_stack_OD = 32; // diameter of the auger bearing part

// Internal parts for auger bearing stack
module auger_bearing_stack_internals() {
    h=hopper_top - hopper_bearing;
    bearingOD=1.125*inch+0.2;
    bearingZ=8;
    
        // space for bearing
        translate([0,0,h-bearingZ])
            cylinder(d=bearingOD,h=bearingZ+1);
        
        // thru shaft
        translate([0,0,-0.1])
        cylinder(d1=0.5*inch, d2=16,h=h);
}

// Cylinder underneath gear plate, spaces the auger thrust bearing
module auger_bearing_stack() {
    h=hopper_top - hopper_bearing;
    difference() {
        // outer body
        cylinder(d=hopper_bearing_stack_OD,h=h);

        auger_bearing_stack_internals();
    }
}

// One set of ribs that connect to this bolt hole
module auger_bearing_rib_solid(boltloc,enlarge=0.0) {
    hull() {
        circle(d=hopper_bearing_stack_OD + 2*enlarge);
        translate(boltloc) circle(d=10 + 2*enlarge);
    }
}
module auger_bearing_rib(boltloc) {
    rib_thick=3.5;
    round=5.0;
    difference() {
        auger_bearing_rib_solid(boltloc,0.0);
        offset(r=+round) offset(r=-round)
        auger_bearing_rib_solid(boltloc,-rib_thick);
    }
}

// Ribs that connect the auger bearing up to the geartrain frame plate
module auger_bearing_ribs() {
    rib_inset=1.0; // clearance between ribs and hopper walls
    
    for (side=[-1,+1])
    for (bolti=[0:2]) 
    {
        difference() {
            boltloc = hopper_plate_bolts[bolti];
            
            scale([side,1,-1])
            intersection() {
                // main body of rib is 2D extrusion
                linear_extrude(height=hopper_top - hopper_bearing, convexity=4)
                intersection() {
                    auger_bearing_rib(boltloc);
                    offset(r=-rib_inset) hopper_top_plate_2D();
                }
                
                hull() { // tapered top slope of each rib
                    cylinder(d=hopper_bearing_stack_OD, h=hopper_top - hopper_bearing);
                    translate(boltloc) cylinder(d=10, h=1);
                }
            
            }
        }
    }
}

geartrain_cover_clearR = 2.0; // side clearance for gear teeth
geartrain_cover_clearZ = 2.0; // top clearance above gear
geartrain_cover_bigR = geartrain_cover_clearR + gear1_augerR;
geartrain_cover_wall = 1.7;

// Covers up front of main drive gear, to keep concrete out of the gear teeth
module geartrain_cover() {
    wall = geartrain_cover_wall;
    floor = wall; // thickness of top and bottom plates
    rib_thick=2.5;
    
    lo = gearZ_floor; // bottom of bottom floor
    hi = gearZ_auger + gear1_thickness + geartrain_cover_clearZ; // bottom of top floor
    
    bigR = geartrain_cover_bigR;
    
    ribX=hopper_feedR+6;
    ribYrange=0.6666*bigR; // distance covered by ribs
    
    difference() {
        union() {
            // Outside:
            h=hi-lo + 2*floor;
            translate([0,0,lo]) {
                cylinder(r=geartrain_cover_bigR+wall,h=h);
                
                translate([0,0,floor/2])
                linear_extrude(height=floor,center=true,convexity=4)
                    intersection() {
                        //translate([0,-ribYrange*0.5,0])
                        //    square([2*(hopper_plate_bolts[0][0]+5),ribYrange],center=true);
                        hopper_mount_plate_2D();
                    }
            }
            
            // Reinforcing ribs
            for (ribYI=[0.5,1]) 
            intersection() {
                ribY = ribYI * (-ribYrange)-rib_thick;
                // taper down from cylinder to base plate
                hull() {
                    front_extra = (ribYI==1)?12:0; // lip in front, to stop spilling material during loading
                    translate([0,0,lo]) cylinder(r=bigR+wall,h=h+front_extra);
                    translate([-ribX,ribY,lo])
                        cube([2*ribX,rib_thick,gearZ_floor]);
                }
                // slab along rib slice
                translate([-ribX,ribY,lo])
                    cube([2*ribX,rib_thick,100]);

            }
        }
        
        // Inside with space for gear
        translate([0,0,gearZ_floor-0.01])
        difference() {
            cylinder(r=bigR,h=hi-lo+floor);
            
            // support material under bottom rib
            supportX=bigR*0.6;
            supportThick=1.0;
            translate([0,-ribYrange,hi/2]) {
                cube([2*supportX,supportThick,hi],center=true);
                cube([supportThick,10,hi],center=true);

            }
        }
        
        // Space for auger drive clip, and gear insertion
        hull() for (d=[[0,0], [50,50],[-50,50]]) translate(d)
            cylinder(d=1.9*ribYrange,h=100,center=true);
        
        // trim off back side
        translate([0,-ribYrange/2+200,0]) cube([400,400,400],center=true);
    }
}

stepper_mount_Ystart = 17; // Y coordinate to trim this part

// Holds stepper and reducer gear
module geartrain_stepper_mount2D(flatwall=1)
{
    block=2.5; // thickness of walls around stepper
    round=3.5; //< subtle: must be less than 8/2 for reducer shaft to fit here
    long = 54+stepper_frameXY+block; // tune to match Ystart
    offset(r=-round) offset(r=+round)
    {
        // Flat wall on bottom edge
        if (flatwall)
            translate([0,stepper_mount_Ystart+block/2,0])
                square([2*long,block],center=true);
        
        // Support walls around stepper
        translate(stepper_center) rotate(stepper_rotate) 
        translate([-stepper_frameXY/2-block,-stepper_frameXY/2-block,0])
        {
            // Vertical walls
            rX=stepper_frameXY+block;
            for (x=[0,rX/2,rX])
                translate([x,0]) scale([1,-1]) square([block,stepper_frameXY]);
            
            // Stepper surrounded by frame
            translate([block+stepper_frameXY/2,block+stepper_frameXY/2])
            difference() {
                square([2*block + stepper_frameXY,2*block + stepper_frameXY],center=true);
                square([stepper_frameXY,stepper_frameXY],center=true);
            }
        }
        
        // Reach out to hold the reducer gear
        translate(replaceZ(reducer1_center,0))
            union() {
                circle(d=25);
                for (ribangle=[45,90])
                rotate([0,0,ribangle]) translate([0,8]) scale([-1,1])
                    square([100,block]);
            }
    }
}

// Stepper motor bolts onto this
module geartrain_stepper_mount(support=0) 
{
    floor=2.5;
    
    
    if (support) {
        intersection() {
            translate([5,stepper_mount_Ystart,2]) scale([-1,1,1])
            {
                cube([25,100,1.5]);
                cube([2,100,6]);
            }
            cylinder(r=geartrain_cover_bigR-0.4,h=100,center=true);
        }
    }
    
    intersection() {
        
        // trim off entire part to Y>=Ystart and Z>=gearZ_floor
        difference() {
            union() {
                translate([0,stepper_mount_Ystart+500,gearZ_floor+500]) cube([168,1000,1000],center=true);

                // Allow stuff to stick down into old stepper hole
                linear_extrude(height=10)
                    geartrain_stepper_old2D(-1.0);
            }
            
            // stay away from central gear
            cyl(r=geartrain_cover_bigR,h=2*(gearZ_auger + gear1_thickness + geartrain_cover_clearZ+2), chamfer=3, anchor=CENTER);
            
            // stay away from reducer gear
            hull() {
                Zspace=1;
                translate(replaceZ(reducer1_center,gearZ2_floor-Zspace)) 
                    cyl(r=gear2_reducerR+geartrain_cover_clearR,h=gear2_thickness+2*Zspace, chamfer=Zspace, anchor=BOTTOM);
                translate(replaceZ(reducer1_center,gearZ_auger)) 
                    cyl(r=gear1_driveR+geartrain_cover_clearR,h=gear1_thickness+2*Zspace, chamfer=Zspace, anchor=BOTTOM);
            }
            
            // Leave space to insert reducer gear axle
            translate(replaceZ(reducer1_center,1))
                cylinder(d=8,h=100);
            
            //hull() translate(replaceZ(reducer1_center,0))  gear_reducer();
        }
        
        union() {
            // Base plate that gets bolted down
            translate([0,0,gearZ_floor])
                linear_extrude(height=floor,convexity=2) 
                    difference() {
                        
                        hopper_mount_plate_2D();
                        
                        // space to insert stepper bolts
                        translate(stepper_center) rotate(stepper_rotate)
                            square([stepper_frameXY,stepper_frameXY],center=true);
                    }
            
            // Stepper base plate with actual mounting bolt holes
            translate(stepper_center) rotate(stepper_rotate) 
                scale([1,1,-1]) // extrude walls down from stepper
                linear_extrude(height=floor,convexity=6) 
                difference() {
                    square([stepper_frameXY,stepper_frameXY],center=true);
                    circle(d=stepper_holeOD);
                    for_stepper_bolt_centers_local() circle(d=M3_thru);
                }
            
            // Walls around stepper and such
            scale([1,1,1]) // extrude walls down from stepper
                linear_extrude(height=stepper_center[2],convexity=6)
                    geartrain_stepper_mount2D();
            
            // Top closeout plate, for stiffening and debris rejection
            translate([0,0,stepper_center[2]]) scale([1,1,-1])
                linear_extrude(height=2,convexity=4) 
                difference() {
                    hull() geartrain_stepper_mount2D(0);
                    translate(stepper_center) rotate(stepper_rotate) 
                        square([stepper_frameXY,stepper_frameXY],center=true);
                }
        }
    }
}

// Bolt bosses above geartrain frame
module geartrain_frame_bolt_bosses() 
{
    for_hopper_plate_bolts() {
        translate([0,0,gearZ_floor-0.1])
            cylinder(d1=20,d2=10,h=3); // bolt bosses above plate
    }
}

// 2D shape of old stepper outline
module geartrain_stepper_old2D(enlarge=0)
{
    round=5; // rounding applied to stepper access cut (for strength)

    translate(stepper_old_center) rotate(stepper_old_rotate) 
        offset(r=+round+enlarge) offset(r=-round)
            square([stepper_old_frameXY,stepper_old_frameXY],center=true);
}

// Frame holds all the gear parts together.  Bolts down onto hopper.
module geartrain_frame() 
{
    difference() {
        union() {
            linear_extrude(height=gearZ_floor,convexity=4)
            difference() {
                union() {
                    hopper_mount_plate_2D();
                    
                    // material under front gear
                    difference() {
                        circle(r=geartrain_cover_bigR + geartrain_cover_wall);
                        circle(d=auger_shaft_OD+clearance);
                    }
                }
                
                geartrain_stepper_old2D();
            }
            
            
            translate([0,0,0.01]) rotate([180,0,0]) auger_bearing_stack(); // integrate the bearing stack into this part, for additional bending moment
            
            auger_bearing_ribs();
        }
        
        translate([0,0,0.01]) rotate([180,0,0]) auger_bearing_stack_internals();
    }
    
}


// Demo of how geartrain looks when assembled
module geartrain_assembled() 
{
    geartrain_frame();
    //rotate([180,0,0]) auger_bearing_stack(); // integrated into frame now
    
    color([0.7,0.7,0.7]) geartrain_cover();
    
    color([1,0.5,0.5]) 
            geartrain_stepper_mount();
    
    gear_auger();
    
    translate(replaceZ(reducer1_center,0)) gear_reducer();
    
    
    
    color([1,0,1]) {
        translate(stepper_center) rotate(stepper_rotate) 
        {
            #square([42,42],center=true); // NEMA 17 outside
            
            rotate([180,0,0])
                gear_stepper();
        }
    }
    
    //# geartrain_cover();
}

// Printable gears in geartrain, ready for printing
module gears_printable() {
    d=gear1_augerR; // distance between parts
    rotate([180,0,0]) 
        translate([0,0,-(gearZ_auger+gear1_thickness)]) gear_auger();
    
    translate([0,d+5+gear2_stepperR,0]) gear_stepper();
    
    translate([d+5+gear2_reducerR,0,0]) 
        rotate([180,0,0]) translate([0,0,-(gearZ2_floor+gear2_thickness)]) gear_reducer();
    
}


module geartrain_frame_printable() {
    rotate([180,0,0]) // auger needs to be upright for printing
        translate([0,0,-gearZ_floor]) 
            geartrain_frame();
}
module geartrain_stepper_printable() {
    rotate([90,0,0]) geartrain_stepper_mount(1);
}
module geartrain_cover_printable() {
    translate([0,0,-gearZ_floor]) geartrain_cover();
}


/* ---------------- Hopper-top Mount Plate ----------
 Mounts the auger gear and stepper motor to the top of the hopper.
*/
module for_stepper_bolt_centers_local() 
{
    for (dx=[-1,+1]) for (dy=[-1,+1]) translate([dx*stepper_boltXY, dy*stepper_boltXY]) 
        children();
}

module for_stepper_old_bolt_centers()
{
    translate(stepper_old_center) rotate(stepper_old_rotate) {
        for_stepper_bolt_centers_local()
            children();
    }
}

module hopper_mount_plate_2D() 
{
    difference() {
        union() {
            hull() {
                for_hopper_plate_bolts() circle(d=10);
                
                translate(stepper_old_center) rotate(stepper_old_rotate) 
                    offset(r=3)
                    square([stepper_old_frameXY,stepper_old_frameXY],center=true);
                
                for_stepper_old_bolt_centers() circle(d=16);
                offset(r=hopper_top_rim) intersection() {
                    hopper_top_plate_2D();
                    square([200,85],center=true);
                }
                children();
            }
        }
        
        for_hopper_plate_bolts() circle(d=M3_thru);
        circle(d=auger_shaft_OD+clearance); // hole for auger shaft to pass through
        
        //for_stepper_bolt_centers() circle(d=M3_thru);
        //translate(stepper_center) rotate(stepper_rotate) circle(d=stepper_holeOD);
    }
}

module hopper_mount_plate_3D() {
    linear_extrude(height=2,convexity=6) hopper_mount_plate_2D();
}


// Holds through bolt at same OD as auger, for welding
module auger_weld_support() 
{
    difference() {
        union() {
            cylinder(d1=auger_shaft_OD+5,d2=auger_shaft_OD+2,h=12);
            cylinder(d=auger_thread_OD,h=2);
        }
        cylinder(d=auger_shaft_OD+clearance,h=100,center=true);
    }
}


/* ---------------- Hopper ---------------------
  Stores material for extrusion.  Can be loaded manually, or via a fill tube.
*/
hopper_top = 0; // level with geartrain plate
// drive bearing here
hopper_bearing = -25; // Z height of bottom of hopper support bearing
// inducer mounts here
hopper_cylinder= -40; // Z height of top of cylindrical region
// main storage cylinder here
hopper_coneZ= -130; // Z height of cone closing taper

hopper_pipetopZ= -170; // Z height of top of PVC glue-in

// rounded cone tapering down to pipe here
hopper_bottom = -170; // top of extrusion auger barrel at bottom of hopper, start of mount plate
// top of PVC pipe, with taper coupler
hopper_taper_coupler = hopper_bottom-25; // taper coupler ends here
// just PVC pipe here
hopper_nozzle_coupler = hopper_taper_coupler-25;  // start of coupler going down and out to nozzle
// coupler heads to nozzle from here
hopper_nozzle_Z=hopper_nozzle_coupler-125; // exit area where nozzle threads on


hopper_feedZ= -150; // Z height of feed input 
hopper_feedR=75; // radius of feed box
hopper_coneR=50; // radius of central core of hopper (can glue in PVC pipe coupler with bevel)
hopper_augerXY=[2*hopper_feedR,100]; // top plate around auger

hopper_feed_center=[0,-60,0]; // center of feed area square (sticks out for manual feeding)

hopper_round=20; // corner rounding

hopper_top_rim=5; // thickness of top rim

// Thickness of wraparound tool mount
hopper_exitOD=pipe_OD+2*3; // pipe_coupler_OD+2*3;


// translation to tool mounting plate center
toolplate_center=[0,38,hopper_bottom-50]; // center point of our mount
toolplate_size=[45,12,80]; // plastic that bolts to the actual toolplate
toolplate_back = toolplate_center + [0,toolplate_size[1]/2,0]; // back face

toolplate_clearance=[60,14,45]; // space for belts and mounting bolts

// Printer's toolplate (no holes)
module toolplate_block()
{
    translate(toolplate_center+[0,toolplate_size[1],0]) 
        cube(toolplate_size,center=true);
}


// positive X plate mounting bolt centers (negative X is mirror image)
hopper_boltR=75; // outset distance for bolts
hopper_boltout=4; // outset of mount bolts
hopper_plate_bolts=[
    [hopper_boltR+hopper_boltout,-25,0], // -hopper_augerXY[1]/2,0], // front sides
    [hopper_boltR+hopper_boltout,+25,0], // -hopper_augerXY[1]/2,0], // mid sides
    [hopper_boltR-hopper_round,+hopper_augerXY[1]/2+3+hopper_boltout,0] // back 
];

// Mirror children at this hopper plate bolt center p
module mirror_hopper_plate_bolts(p) 
{
    translate(p) children();
    translate([-p[0],p[1],p[2]]) children();
}

// Put children at each hopper plate bolt center
module for_hopper_plate_bolts() 
{
    translate([0,0,hopper_top])
    for (p=hopper_plate_bolts) 
        mirror_hopper_plate_bolts(p) 
            children();
}


// 2D shape of hopper top plate
module hopper_top_plate_2D()
{
    offset(r=+hopper_round) offset(r=-hopper_round)
    union() {
        // Feed chute with flat front (for scraping off trowel)
        fe=2*hopper_feedR;
        translate(hopper_feed_center) 
            square([fe,fe],center=true);
        
        // Space and support around auger
        translate([0,0])
            square(hopper_augerXY,center=true);
    }
}

// Main 3D center cylinder of hopper
module hopper_cylinder(enlarge=0,shift_bottom=0)
{
    re=hopper_coneR + enlarge;
    // Central cylinder
    translate([0,0,hopper_coneZ+shift_bottom]) {
        h=hopper_cylinder - hopper_coneZ+enlarge;
        rounding = 1.0*hopper_round+0.5*enlarge;
        //cylinder(r=re,h=h);
        cyl(r=re,h=h - shift_bottom, rounding=rounding, anchor=DOWN);
    }
}

// 3D interior volume of hopper exit and central bulge
module hopper_bulge_exit(enlarge=0, enlarge_exit=0)
{
    hull() {
        // Exit point
        //pe=pipe_coupler_OD/2 + enlarge + enlarge_exit;
        pe=pipe_ID/2 + enlarge + enlarge_exit;
        translate([0,0,hopper_bottom+0.01*enlarge]) cylinder(r=pe,h=0.1);
        
        // Cone taper to central bulge to hold material
        re=hopper_coneR + enlarge;
        translate([0,0,hopper_coneZ]) scale([1,1,0.75]) sphere(r=re);
        
        hopper_cylinder(enlarge);
        
        // children for adding tapers or projections
        children();
    }
}


// 3D interior volume of hopper
module hopper_shape(enlarge=0, enlarge_exit=0)
{
    difference() {
        union() {
            hopper_bulge_exit(enlarge, enlarge_exit) children();
            hull() {
                //hopper_cylinder(enlarge, 0);
                // This is where feed hits the auger
                translate([0,0,hopper_feedZ]) 
                    scale([0.65,0.8,1]) // squish X for sloped intersection
                    rotate([45,0,0])
                        cylinder(r=hopper_coneR+enlarge,h=1);
                
                // Top feed plate
                translate([0,0,hopper_top])
                linear_extrude(height=0.1-0.01*enlarge,convexity=2)
                    offset(r=enlarge)
                        hopper_top_plate_2D();
            }
        
            // Slope the interface between feed and stir cylinder
            for (step=[0:2])
            translate([0,0,hopper_feedZ-pipe_OD*0.8])
                translate([0,0,step*8])
                rotate([8+8*step,0,0]) translate([0,0,+enlarge])
                difference() {
                    cylinder(d=pipe_OD+2*enlarge,h=pipe_OD-2*enlarge);
                    translate([0,100+pipe_OD*0.08,0]) cube([200,200,200],center=true); // only front half
                }
        }
        
        /*
        // Carve space for stepper gear head to not interfere with hopper
        translate(stepper_center) rotate(stepper_rotate) {
            enlargelimit=2; // keep enlarged rim from hitting gear
            enlargelimited = enlarge>enlargelimit?enlargelimit:enlarge;
            
            cyl(r=15 - enlargelimited, h=25 - 2*enlargelimited, rounding=5, anchor=CENTER);
        */
        /*
        // NEMA 17 hanging down:
            xy=44+2*5 - 2*enlarge;
            z=2*stepper_height - 2*enlarge;
            cuboid([xy,xy,z], rounding=10 - enlarge);
        */
    }
}

// 3D space for PVC pipe to be glued in
module hopper_pipe_space()
{
    // taper coupler, machined with a taper on the feed entrance
    //translate([0,0,hopper_taper_coupler])
    //    cylinder(d=pipe_coupler_OD,h=hopper_coneZ - hopper_taper_coupler);
    
    // through pipe in middle
    translate([0,0,hopper_nozzle_Z])
        cylinder(d=pipe_OD,h=0.01+hopper_pipetopZ - hopper_nozzle_Z);
    
    // nozzle coupler on bottom (cemented on after assembly)
    //translate([0,0,hopper_nozzle_Z])
    //    cylinder(d=pipe_coupler_OD,h=hopper_nozzle_coupler - hopper_nozzle_Z);
    
/*
        translate([0,0,hopper_bottom]) {
            pipe_inside_threads(false);
            cylinder(d=pipe_ID,h=50,center=true); // thru hole
            translate([0,0,-pipe_thread_Z]) scale([1,1,-1])
                cylinder(d=pipe_OD,h=100); // pipe extends down from here
        }
*/
}

// Ribs to strengthen the hopper walls (without adding too much weight)
module hopper_ribs(wall) 
{
    // increasing reinforcing ribs as we approach exit (& support point)
    rib_top = 2; // light ribs support top of cylinder
    rib_bottom=6; // added rib thickness at bottom of feed cone
    rib_wide = 3; // thickness of ribs
    rib_angle = 60; // tilt angle of ribs relative to vertical
    rib_centerZ = hopper_bottom;
    for (phase=[0,1])
    intersection() {
        hopper_shape(wall+rib_top,phase?0:rib_bottom)
            // taper out ribs on bottom
            if (phase==0) translate([0,0,hopper_taper_coupler]) cylinder(d=hopper_exitOD,h=1);
        
        union() {
            // Vertical and slanted ribs are thin cubes
            translate([0,0,rib_centerZ])
            for (angle=[0:60:180-1]) for (tilt=[-rib_angle,0,+rib_angle])
                rotate([tilt,0,angle + 30*phase])
                    cube([500,rib_wide,500],center=true);

            // Horizontal ribs are thicker cubes
            for (z=[hopper_coneZ,hopper_coneZ-10,hopper_cylinder])
                translate([0,0,z]) 
                    for (a=[0]) rotate([a,0,0])
                    cube([500,500,rib_wide*2],center=true);
        }
   }
            
    // transition taper between ribs and pipe
    translate([0,0,hopper_bottom])
        cylinder(d1=hopper_exitOD,d2=hopper_exitOD+12,h=30,center=true);
}

// 3D overall shape of hopper, including mounting bolts and ribs
module hopper_exterior()
{
    wall=1.5;
    hopper_pipe_wrap_Z=hopper_bottom - toolplate_center[2] + toolplate_size[2]/2; // Z height of area wrapping around pipe
    difference() {
        union() {
            hopper_shape(wall,1.5*wall);
            intersection() { // heavy reinforcing rim around top perimeter
                cube([500,500,10],center=true);
                hopper_shape(hopper_top_rim);
            }
            
            hopper_ribs(wall);
            
            hull() { // merge the pipe and toolplate mounts, for strength
                // Pipe thread boss
                translate([0,0,hopper_bottom]) {
                    scale([1,1,-1])
                        cylinder(d=hopper_exitOD,h=hopper_pipe_wrap_Z);
                }
                
                // Toolplate mount
                mount_extra=[0,0,30]; // extra material above toolplate, to taper into cone
                translate(toolplate_center+mount_extra) cube(toolplate_size+2*mount_extra,center=true);
            }
            
            // top bolt bosses
            for_hopper_plate_bolts() scale([1,1,-1]) cylinder(d1=12,d2=10,h=10);
        }
        // top bolt tappable holes
        for_hopper_plate_bolts() {
            cylinder(d=M3_tapID,h=25,center=true); // tappable on top
            translate([0,0,-11]) cylinder(d=M3_insertOD,h=M3_insertZ); // space for 4mm dia x 5mm high insert underneath
        }
        // carve out interior of hopper
        hopper_shape(0.0);
        
        // Space for auger barrel to thread in
        hopper_pipe_space();
        
        // Space for toolplate itself
        toolplate_block();
        
        // Space for toolplate back belts
        difference() {
            translate(toolplate_back) 
                cuboid(toolplate_clearance,rounding=6);
            difference() {
                // put back material around pipe
                translate([0,0,hopper_bottom]) scale([1,1,-1])
                        cylinder(d=hopper_exitOD,h=100);
                // make sure there's clearance for toolplate carriage mount bolts
                translate(toolplate_back) 
                for (dx=[-1,+1]) for (dy=[-1,+1]) translate([dx*20/2, 0, dy*20/2]) rotate([90,0,0]) 
                    cylinder(d=M3_headOD*1.2,h=M3_headZ*1.2);
            }
        }
        
        // Tappable space for 1/4" mounting bolts to toolplate
        translate(toolplate_back)
        for (dx=[-1,+1]) for (dy=[-1,+1]) translate([dx*32/2, 0.1, dy*64/2]) rotate([90,0,0])
        {
            //cylinder(d=0.190*inch,h=25,center=true); // for manual tapping
            // For 1/4" - 20 tpi bolt, 1/2" long
            threaded_rod(l=0.5*inch, pitch=1/20*INCH, d=0.25*inch, anchor=BOTTOM);
        }
        
        // trim off top face clean
        translate([0,0,hopper_top+200]) cube([400,400,400],center=true);
    }
    
}

// hopper in printable orientation
module hopper_printable() {
    rotate([180,0,0]) hopper_exterior();
}


/* ---------------- Inducer -----------------
 Threads onto auger, and pushes material down into auger area
*/
inducer_Z_end=hopper_bearing; // top of inducer, threads on
inducer_Z_cylinder=hopper_bearing-25; // height where mounting cylinder starts, and auger hex head
inducer_Z_endspiral=hopper_bottom; // top of spiral area
inducer_Z_start=inducer_Z_endspiral; // bottom of inducer, tips

inducer_wall=3.5; // thickness of body of inducer

inducer_hopper_clearance=4; // distance between inducer and hopper (allow assembly, reduce grinding chance)

inducer_bladeW=10.3; // width + clearance for steel wiper blade of inducer (needs to be thick to resist torsion)
inducer_bladeH=2.5; // thickness of slot for steel strip
inducer_bladeR=hopper_coneR - inducer_hopper_clearance; // radius of main blade in XY plane
inducer_blade_mount=3; // plastic around the blade itself

inducer_mountD = hopper_bearing_stack_OD+1; // outside of mounting cylinder


inducer_Z_threadstop=-75; // Z height where auger helix threading stops

// Dimensions of auger hole in inducer:
auger_axle_OD=auger_shaft_OD+clearance; // across the shaft
auger_hex_OD=3/4*inch + clearance; // across the flats of the hex
auger_hex_Z=11/32*inch; // height of hex head on auger bolt



// The auger's welded-on top bolt needs a cross-drilled hole for retaining clip, at this distance from the top of the hex flats:
bolt_Z_space = (gearZ_auger - inducer_Z_cylinder) - auger_hex_Z + gear1_thickness + 3;
echo("Auger bolt top to clip hole: ",bolt_Z_space);


/*
  Model the helical thread of the auger for this many complete cycles.
  Starts at z=0, facing up.
*/
module auger_thread_helix(cycles=3) {
    linear_extrude(height=auger_thread_pitch*cycles,twist=-cycles*360,convexity=8)
    intersection() {
        circle(d=auger_thread_OD);
        hull() {
            circle(d=auger_thread_centerID);
            translate([pipe_ID/2,0,0]) circle(d=auger_thread_edgeOD);
        }
    }
}

// Subtracted space in the inducer for the auger thread 
module inducer_thread_space() {
    // no longer critical geometry: inducer now mounts to steel hex bolt welded to auger
}

// Swept volume of inducer
module inducer_profile_3D(enlarge=0,shift_exit=0) {
    top_taper=1; // increase in wall thickness on top surface
    hull() {
        // Must fit inside hopper
        hopper_bulge_exit(-inducer_hopper_clearance+enlarge,shift_exit);
        
        // Taper to auger on top
        translate([0,0,inducer_Z_end+top_taper*enlarge]) scale([1,1,-1]) 
            cylinder(d=hopper_bearing_stack_OD+2*inducer_wall+2*enlarge,h=1);
    }
}

// Top-down view of 2D slot for blade
module inducer_blade_top2D(enlarge = 0)
{
    square([(inducer_bladeW+2*enlarge),2*inducer_bladeR],center=true); // main arms
}
module inducer_blade_top3D(enlarge=0,raisebottom=0) 
{
    bottom = inducer_Z_start + raisebottom;
    translate([0,0,bottom])
        linear_extrude(height=inducer_Z_end - bottom,convexity=4) 
        offset(r=enlarge) {
            inducer_blade_top2D();
        }
}

// Inducer body top-down 2D profile
module inducer_body_top2D() 
{
    union() {
        hull() 
        {
            inducer_blade_top2D(enlarge = inducer_blade_mount); // main arms
            
            circle(d=inducer_mountD); // central bulge
        }
    }
}
// Inducer main body
module inducer_body() 
{
    intersection() {
        union() {
            
            // Add support arm on top of blade
            translate([0,0,inducer_Z_cylinder])
                linear_extrude(height=inducer_Z_end - inducer_Z_cylinder,convexity=4) {
                    inducer_body_top2D();
                }
             
        }
        
        difference() {
            // Trim to fit in the overall profile
            inducer_profile_3D(0); // interior of hopper
            
            // Cut recessed slot for actual stainless blade
            difference() {
                inducer_blade_top3D();
                inducer_profile_3D(-inducer_bladeH);
                
                translate([0,0,inducer_Z_cylinder])
                    cylinder(d=inducer_mountD,h=100,center=true);
            }
        }
    }
    
}

// Move to centers of each inducer blade mounting screw
module inducer_screw_centers() {
    for (side=[-1,+1]) scale([1,side,1])
        for (y=[0.1, 0.3])
            translate([0,(0.4+y)*hopper_coneR,inducer_Z_end-y*hopper_coneR])
                rotate([180-45,0,0])
                    children();
}

// Full inducer shape
module inducer() {
    difference() {
        union() {
            inducer_body(); // steel blade added later
        }
        
        // Screws to hold and align the blade strip steel
        inducer_screw_centers()
        {
            cylinder(d=M3_tapID,h=50);
            translate([0,0,10])
                cylinder(d=M3_insertOD,d2=M3_insertOD*2,h=25);
        }
                    
        
        // Space for auger mounting bolt (1/2" bolt welded to top of auger)
        cylinder(d=auger_axle_OD,h=200,center=true);
        translate([0,0,inducer_Z_cylinder-0.1])
            cylinder(d=auger_hex_OD/cos(30),$fn=6,h=auger_hex_Z);
        
        // Cut clearance gap around everything but the inner race of the bearing
        gap=2;
        translate([0,0,inducer_Z_end-gap]) 
        difference() {
            cylinder(d=hopper_bearing_stack_OD-1,h=gap+0.1);
            translate([0,0,-0.1]) cylinder(d=auger_axle_OD+2*gap,h=gap+0.2);
        }
        
        // Cutaway
        //translate([0,0,-200]) cube([200,200,200]);
    }
}

// Print from base up
module inducer_printable() {
    inducer();
}

// Sketch for stainless steel blade
module inducer_blade() {
    color([0.4,0.4,0.5])
    difference() {
        intersection() {
            inducer_profile_3D(-0.01); // interior of hopper
            inducer_blade_top3D();
        }
        intersection() {
            inducer_profile_3D(-inducer_bladeH); // interior of blade
            inducer_blade_top3D(1,inducer_bladeH);
        }

        // Eliminate the top surface
        translate([0,0,inducer_Z_end]) cylinder(d=inducer_mountD+2,h=25,center=true);
        
        inducer_thread_space();
    }
}

// 2D (printable) cross section of blade
module inducer_blade_section() {
    projection(cut=true) rotate([0,90,0]) {
        inducer_blade();
        inducer_screw_centers() cylinder(d=1,h=10);
    }
}

/* ------------------ Pipe Wall Texture ----------------
 A large auger tends to just spin the material around a smooth pipe.
 These glue-on sections are designed to keep material from spinning, but let it slide down.
*/
pipewall_OD = pipe_ID; // fits inside pipe
pipewall_ID = auger_thread_OD + 1; // hole for auger
pipewall_Z = hopper_bottom - hopper_nozzle_coupler + (2+7/16)*inch/2 - 5;

module pipewall_2D() 
{
    grooveD = pipewall_ID + 0.5*(pipewall_OD-pipewall_ID);
    circumference = 3.141592 * grooveD;
    grooveN = 24;
    grooveW = 0.5 * circumference / grooveN;
    
    round = 0.5;
    offset(r=-round) offset(r=+round)    
    difference() {
        circle(d=pipewall_OD);
        
        circle(d=pipewall_ID); 
        
        da = 360/grooveN;
        for (angle=[da/2:da:360-1]) rotate([0,0,angle])
            square([grooveD,grooveW],center=true);
        
    }
}


module pipewall_sections()
{
    tilt = 60; // tilt back, to reduce overhangs

    // for (dx=[0:5:19]) translate([dx,0,0]) // line up 4 quadrant copies
    rotate([90,0,0]) // print flat, so layer lines go down the pipe
    rotate([0,0,-tilt])
    difference() {
        union() {
            linear_extrude(height=pipewall_Z,convexity=8) pipewall_2D();
            
            // supports to keep the print upright
            for (support=[0.01,0.3,0.7,0.99]) translate([0,0,support*pipewall_Z])
            difference()
            {
                sup=8+pipewall_OD;
                rotate([0,0,tilt])
                cube([sup,pipewall_OD*sin(tilt),1.5],center=true); // main upright
                
                cylinder(d=pipewall_OD+0.1,h=5,center=true); // avoid center
                
                // bevel to let the support be detached
                bevel=2;
                contact=0.3;
                for (flip=[-1,+1]) scale([1,1,flip]) 
                    cylinder(d1=pipewall_OD-2*contact,d2=pipewall_OD+2*bevel,h=bevel);
                
                // trim off top
                rotate([0,0,tilt])
                translate([0,0.25*pipewall_OD+100,0]) cube([200,200,200],center=true);
            }
        }
        
        // bevel entrance & exit
        for (end=[0,1])
        translate([0,0,end?pipewall_Z+0.01:-0.01]) scale([1,1,end?-1:1]) 
            cylinder(d1=pipewall_OD, d2=pipewall_ID, h = pipewall_OD - pipewall_ID);
        
        
        // Trim off sections other than the one being printed
        trim = pipewall_OD;
        sz = [2*trim,2*trim,3*pipewall_Z];
        for (flip=[0,1]) rotate([0,0,flip*90]) translate([pipewall_OD/2,0,0])
            rotate([0,0,tilt]) translate((flip?+1:-1)*[0.9*trim,trim]) cube(sz,center=true); 
        
        // Trim off bottom (left untrimmed at high tilt)
        translate([0,-trim-5,0]) cube(sz,center=true); 
    }
    
}



/* ---------------- Nozzle ------------------- 
  Extrudes material out the central exit hole.
  Threads onto end of auger barrel.
*/
nozzle_diameter=15; // 20; // diameter of exit hole of nozzle
nozzle_wall=2.0; // thickness of plastic around nozzle
nozzle_flats=8; // number of flat sides
nozzle_flatZ=8; // Z thickness of flats
nozzle_OD=nozzle_pipe_OD+3; // diameter of outside of nozzle (across flats)

nozzle_Z=20; // height of nozzle, not including threads
nozzle_thread_Z=15; // height of nozzle threaded portion
nozzle_exit_Z=3; // straight area at nozzle exit

// Threaded area so nozzle can thread into pipe.  Facing up, ends at origin.
module nozzle_inside_threads(bevelbottom=true)
{
    translate([0,0,4.2-pipe_thread_Z])
    npt_threaded_rod(size=nozzle_pipe_size, $slop=2*clearance, bevel2=bevelbottom, internal=false, orient=BOTTOM, anchor=TOP);
}

// Clear area so material can flow through pipe
module nozzle_inside_flow()
{
    d=nozzle_pipe_ID+1.0; 
    translate([0,0,-2.5-pipe_thread_Z])
        cylinder(d=d,h=1);
}


// Outside of nozzle around threads
module nozzle_outside_threads(enlarge=0) {
    halfangle = 360/nozzle_flats/2;
    //translate([0,0,-pipe_thread_Z])
    rotate([0,0,halfangle])
    cylinder(d=(nozzle_OD + 2*enlarge)/cos(halfangle),
        h=nozzle_flatZ,
        $fn=nozzle_flats // beveled for grip / tool tightening
        );
}

// Exit point of nozzle
module nozzle_exit(enlarge=0) {
    h= enlarge==0 ? 0.1 : nozzle_exit_Z;
    translate([0,0,nozzle_Z - nozzle_exit_Z])
        cylinder(d=nozzle_diameter + 2*enlarge, h=h);
}

// Interior area of nozzle where material can flow
module nozzle_flow(enlarge=0) {
    hull() {
        nozzle_inside_flow();
        nozzle_exit(enlarge*0.5);
    }
}

// Outdented text giving nozzle diameter
module nozzle_text() {
    for (angle=[0:90:360-1]) rotate([0,0,angle])
        translate([nozzle_OD/2+nozzle_wall,0,nozzle_flatZ/2])
            rotate([0,90,0]) rotate([0,0,-90])
                linear_extrude(height=2.5,center=true,convexity=6)
                    text(str(nozzle_diameter),halign="center",valign="center",size=nozzle_flatZ-1);
}

// Overall finished nozzle, with male threads
module nozzle(wall=nozzle_wall) {
    difference() {
        union() {
            hull() {
                nozzle_outside_threads(wall);
                nozzle_exit(wall*0.5);
            }
            cylinder(d=nozzle_diameter+2*wall,h=nozzle_Z); // final exit surface
            nozzle_text();
            
            
            nozzle_inside_threads(); // threadable area
        }
        
        cylinder(d=nozzle_diameter,h=nozzle_Z+1); // thru hole and exit
        
        nozzle_flow(0.0); // inside of flow area
        
        
        // Trim off bottom so it doesn't need to be threaded as long
        translate([0,0,-nozzle_thread_Z-50]) cube([100,100,100],center=true); 
        
        if (0) // cutaway section
            //rotate([0,0,360/8/2]) 
            translate([0,0,-50]) cube([100,100,100]); 
    }
}


// Demo all parts as assembled together and working
module extruder_demo() {
    #hopper_exterior();
    
    hopper_mount_plate_3D();
    translate([0,0,2]) geartrain_assembled();
    
    inducer();
    inducer_blade();
    
    translate([0,0,hopper_nozzle_Z]) rotate([180,0,0]) nozzle();
    
    #toolplate_block();
}

// Demo cutaway
module demo_cutaway() {
    difference() { 
        union() { 
            hopper_exterior(); 
            inducer(); 
        } 
        rotate([0,0,10]) 
        translate([200,200,0]) cube([400,400,800],center=true); // cutaway
    }
    inducer_blade();
}

//extruder_demo(); // Entire assembly
//demo_cutaway();
//geartrain_assembled();
//hopper_shape(); // interior, for volume estimation


// 3D printable parts:
//hopper_printable();
//inducer_printable();
gears_printable();
//geartrain_frame_printable();
//geartrain_cover_printable();
//geartrain_stepper_printable();
//nozzle();


//pipewall_sections(); // keeps material from spinning inside pipe (optional)

// Fabrication tools
//inducer_blade_section(); // 2D outline of blade, for bending stainless
//auger_weld_support();  // centers a 1/2" bolt to line up with auger



