/*
3D printed hopper for a concrete / mortar / clay extruder


Updated version:

Uses half (9 inches) of a welded 2 inch diameter steel earth auger to push concrete down:
    https://www.amazon.com/gp/product/B09MFB84WR/

This is welded onto a 1/2" steel bolt.  The bolt's hex head drives the inducer stir bar.  The top of the bolt drilled so a pull pin can clip it to the top of the drive gear.

The lower half of the auger is surrounded by a 2 inch schedule 40 PVC pipe.  Nominal size, actual OD is 60.4mm.

The nozzle threads onto 1 inch pipe threads, which are adapted down from the 2" PVC as follows:
    - 2" PVC coupler
    - 2" male slip x 1.25" female slip PVC reducing bushing
    - 1.0" male slip x 1.0" male pipe thread PVC adapter
Notice the last jump from 1.25" to 1.0" isn't officially supported, but shrinks the overall nozzle length.

PVC cement does seem to successfully join PVC plastic pipe and PETG prints (Weld-On 700 tested with Overture black PETG).

Design by Dr. Orion Lawlor, lawlor@alaska.edu, 2024-07 (Public Domain)
*/
include <BOSL2/std.scad> /* https://github.com/BelfrySCAD/BOSL2/ */
include <BOSL2/gears.scad> /* for drive gears */
include <BOSL2/threading.scad> /* for pipe thread on auger barrel */

$fs=0.1; $fa=5;

inch=25.4; // file units are mm

// Auger barrel parameters
clearance=0.2; //<- space around printed parts so they can be assembled

// Pipe size at nozzle
nozzle_pipe_size = 1; // inch nominal pipe thread for nozzle
nozzle_pipe_OD = 1.32 * inch+0.5;
nozzle_pipe_ID = 1*inch + 2;

// Pipe size around auger
pipe_OD = 60.6+2*clearance; // outside diameter of pipe, with a little clearance
pipe_coupler_OD = 69.4 + 2*clearance; // diameter of pipe coupler
pipe_ID = 2*inch + 1; // inside diameter of pipe (for flow paths)

pipe_thread_Z=24; // height of end of threaded zone


// Auger itself
auger_thread_pitch=40; // mm between full turns
auger_thread_centerID=9; // central screw (plus some clearance)
auger_thread_edgeOD=25; // edge cross section thickness (plus some clearance)
auger_thread_OD=46; // outside diameter of auger (plus a bit of clearance)

auger_hex_flats=0; // 11.1; // across the flats of hex shaft on auger (0 if round)
//auger_hex_len=30; // length of auger's hex flats
auger_shaft_OD = 1/2*inch + 0.2; // diameter of auger shaft
auger_pin_OD = 3; // diameter of hole for retaining pin
auger_pin_len = 50; // space around auger pin


// Stepper mount dimensions

// NEMA 17
stepper_boltOD=3.5; // bolt hole size
stepper_boltXY=31.0/2; // distance in XY between holes
stepper_frameXY=42.5; // overall outside size of box
stepper_holeOD=22.5; // central hole
stepper_shaftOD=5.1; // shaft where drive gear sits
stepper_height = 55; // Z height of stepper hole



// Tap plastic for M3 screw at this diameter
M3_tapID = 2.3;
M3_shaftOD = 3.1;
M3_thru = 3.6;
M3_headOD = 6.1;
M3_headZ = 3.2;

M3_insertOD=3.8; // space for heat-insert bit
M3_insertZ=6;

/* --------------- Geartrain ------------------
 Input side: connects to the D shaft of a NEMA 17 stepper motor.
 Output side: connects to the hex shaft of the auger itself
*/

gear_module=1.25; // large teeth for robustness and easy printing
gear_teeth_stepper=8; // few teeth on stepper side
gear_teeth_auger=gear_teeth_stepper*10; // torque amplification factor
gear_thickness=10;
gear_clearance=0.2;

gearZ_floor = 2.5; // base plate on top of hopper print
gearZ_auger = gearZ_floor + 1.5; // washer spaces auger gear over floor
gearZ_stepper = gearZ_auger + gear_thickness + 15; // face of stepper lets shaft reach drive gear

// location of stepper relative to auger top
stepper_center = [0,gear_clearance + gear_dist(mod=gear_module, teeth1=gear_teeth_stepper, teeth2=gear_teeth_auger), gearZ_stepper];
stepper_rotate = [180,0,-55];

// Gear on stepper's output shaft.  Origin is base of gear
module gear_stepper() {
    boss_OD=14;
    boss_Z=18; // full length of stepper's shaft, minus mount plate thickness
    boss_tapD=M3_tapID; // tapped for M3 setscrew
    
    shaft_ID=5;
    difference() {
        union() {
            spur_gear(teeth=gear_teeth_stepper, mod=gear_module, thickness=gear_thickness, anchor=BOTTOM);
            translate([0,0,gear_thickness-0.01]) cylinder(d=boss_OD,h=boss_Z-gear_thickness);
        }
        
        difference() {
            cylinder(d=stepper_shaftOD,h=100,center=true); // stepper's 5mm shaft (thru)
            // printable flat on stepper shaft (often prevents fitting)
            //flat_x = stepper_shaftOD/2 - 0.5; // nominal start of flat from center
            //translate([flat_x+100,0,3+100]) cube([200,200,200],center=true);
        }
        
        // sideways M3 grub screws
        grubZ = gear_thickness + 0.5*(boss_Z - gear_thickness);
        for (angle=[0,90]) rotate([0,0,angle])
        translate([0,0,grubZ])
            rotate([0,90,0])
                cylinder(d=boss_tapD,h=10);
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

// Gear on auger shaft.  Origin is center of gear.
module gear_auger() {
    difference() {
        union() {
            difference() {
                spur_gear(teeth=gear_teeth_auger, mod=gear_module, thickness=gear_thickness, anchor=BOTTOM);
                
                // lighten holes
                rI = auger_shaft_OD/2 + 3;
                rO = pitch_radius(teeth=gear_teeth_auger, mod=gear_module) - 4;
                round=6;
                rib=6;
                translate([0,0,-0.01])
                linear_extrude(height=gear_thickness+0.02,convexity=4) 
                    offset(r=+round) offset(r=-round)
                    difference() {
                        circle(r=rO);
                        circle(r=rI);
                        for (ribAngle=[0:60:180]) rotate([0,0,ribAngle])
                            square([200,rib],center=true);
                    }
            }
            
            // This ridge supports a pull pin through the auger shaft
            ridge_thick=10;
            ridge_Z = gear_thickness + 6;
            translate([0,ridge_thick/2,ridge_Z/2])
            difference() {
                cube([auger_pin_len,ridge_thick,ridge_Z],center=true);
                for (screw=[-1,+1]) translate([screw*auger_pin_len*0.4,0,0])
                    cylinder(d=M3_tapID,h=ridge_Z+1,center=true);
            }
        }
        
        // pull pin through auger shaft
        translate([0,0,gear_thickness + auger_pin_OD/2])
            rotate([0,90,0])
            hull() {
                for (extract=[0,1]) translate([-extract*10,0,0])
                    cylinder(d=auger_pin_OD,h=auger_pin_len+1,center=true);
            }
        
        auger_mount_hole();
        
    }
}


hopper_bearing_stack_OD = 32; // diameter of the auger bearing part

// Cylinder underneath gear plate, spaces the auger thrust bearing
module auger_bearing_stack() {
    h=hopper_top - hopper_bearing;
    bearingOD=1.125*inch+0.2;
    bearingZ=8;
    difference() {
        // outer body
        cylinder(d=hopper_bearing_stack_OD,h=h);
        
        // space for bearing
        translate([0,0,h-bearingZ])
            cylinder(d=bearingOD,h=bearingZ+1);
        
        // thru shaft
        translate([0,0,-0.1])
        cylinder(d1=0.5*inch, d2=16,h=h);
    }
}

// Covers up front of main drive gear, to keep concrete out of the gear teeth
module geartrain_cover() {
    wall = 1.7;
    floor = wall; // thickness of top and bottom plates
    rib_thick=wall;
    
    clearR = 2.0; // clearance for gear teeth
    lo = gearZ_floor - floor; // bottom of bottom floor
    hi = gearZ_auger + gear_thickness + 2*clearR; // bottom of top floor
    
    bigR = clearR + outer_radius(teeth=gear_teeth_auger, mod=gear_module);
    
    difference() {
        union() {
            // Outside:
            h=hi-lo + 2*floor;
            translate([0,0,lo]) cylinder(r=bigR+wall,h=h);
            
            // Reinforcing ribs
            for (ribYI=[0,0.4,1]) 
            intersection() {
                ribY = ribYI * (-0.6666*bigR);
                // taper down from cylinder to base plate
                hull() {
                    front_extra = (ribYI==1)?12:0; // lip in front, to stop spilling material during loading
                    translate([0,0,lo]) cylinder(r=bigR+wall,h=h+front_extra);
                    translate([-hopper_coneR,ribY,0])
                        cube([2*hopper_coneR,rib_thick,gearZ_floor]);
                }
                // slab along rib slice
                translate([-hopper_coneR,ribY,0])
                    cube([2*hopper_coneR,rib_thick,100]);

            }
        }
        
        // Inside:
        translate([0,0,lo+floor])
            cylinder(r=bigR,h=hi-lo);
        
        // Space for auger drive clip, and gear insertion
        hull() for (d=[[0,0], [50,100],[-50,0]]) translate(d)
            cylinder(d=60,h=100,center=true);
        
    }
}

// Stepper motor bolts onto this
module geartrain_stepper_mount() 
{
    translate(stepper_center) rotate(stepper_rotate) {

        // Plate with actual mounting bolt holes
        linear_extrude(height=3,convexity=6) 
        difference() {
            square([stepper_frameXY,stepper_frameXY],center=true);
            circle(d=stepper_holeOD);
            for_stepper_bolt_centers_local() circle(d=M3_thru);
        }
        
        // Extra block to hold stepper down
        block=3;
        round=5;
        translate([-stepper_frameXY/2-block,-stepper_frameXY/2-block,0])
        difference()
        { // origin is at back corner of stepper mount now
            long = 80+stepper_frameXY+block;
            z = stepper_center[2];
            linear_extrude(height=z,convexity=4)
            offset(r=-round) offset(r=+round)
            {
                // Hardmount long wall
                square([long,block]);
             
                // Short back wall to allow drive gear to be inserted
                square([block,12+block]);
                
                // Short front wall to clear drive gear
                translate([block+stepper_frameXY,0]) square([block,5+block]);
            }
            
            // hole for stepper wiring zip tie
            translate([long*0.91,0,z*0.4]) rotate([90,0,0]) cylinder(d=10,h=20,center=true);
        }
    }
}


// Frame holds all the gear parts together.  Bolts down onto hopper.
module geartrain_frame() 
{
    difference() {
        union() {
            linear_extrude(height=gearZ_floor,convexity=4)
            difference() {
                hopper_mount_plate_2D();
                
                round=5; // rounding applied to stepper access cut (for strength)
                translate(stepper_center) rotate(stepper_rotate) 
                    offset(r=+round) offset(r=-round)
                    difference() {
                        square([stepper_frameXY,stepper_frameXY],center=true);
                        
                        // Put back one corner, to run a spacer after gear is in
                        rotate([0,0,60]) translate([0,12+50,0]) square([100,100],center=true);
                    }
            }
            
            geartrain_cover();
            
            geartrain_stepper_mount();
        }
    }
    
}


// Demo of how geartrain looks when assembled
module geartrain_assembled() 
{
    geartrain_frame();

    translate([0,0,gearZ_auger]) gear_auger();
    
    rotate([180,0,0]) auger_bearing_stack();
    
    //circle(d=25.4);
    color([1,0,1]) {
        translate([stepper_center[0], stepper_center[1], gearZ_auger]) 
            gear_stepper();
        
        translate(stepper_center) rotate(stepper_rotate) 
            square([42,42],center=true); // NEMA 17 outside
    }
    
    //# geartrain_cover();
}

// Printable parts in geartrain, ready for printing
module geartrain_printable() {
    d=stepper_center[1]*1.1; // distance between parts
    gear_auger();
    translate([0,d,0]) gear_stepper();
    //translate([d,0,0]) auger_clamp(); // no longer needed
    //translate([0.8*d,0.8*d,0]) auger_bearing_stack(); // printed separately
}


module geartrain_frame_printable() {
    difference() {
        translate([0,0,stepper_frameXY/2+3])
        rotate([-90,0,0]) // stand upright for printing
        rotate([0,0,-stepper_rotate[2]])
            translate(-stepper_center)
                geartrain_frame();
        
        // Trim bottom flat for printing (loses one mounting hole, still have 3 which is plenty)
        translate([0,0,-200]) cube([400,400,400],center=true);
    }
}

/* ---------------- Hopper-top Mount Plate ----------
 Mounts the auger gear and stepper motor to the top of the hopper.
*/
module for_stepper_bolt_centers_local() 
{
    for (dx=[-1,+1]) for (dy=[-1,+1]) translate([dx*stepper_boltXY, dy*stepper_boltXY]) 
        children();
}

module for_stepper_bolt_centers()
{
    translate(stepper_center) rotate(stepper_rotate) {
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
                for_stepper_bolt_centers() circle(d=16);
                offset(r=hopper_top_rim) intersection() {
                    hopper_top_plate_2D();
                    square([200,85],center=true);
                }
            }
        }
        
        for_hopper_plate_bolts() circle(d=M3_thru);
        circle(d=auger_shaft_OD); // hole for auger shaft to pass through
        
        for_stepper_bolt_centers() circle(d=M3_thru);
        translate(stepper_center) rotate(stepper_rotate) circle(d=stepper_holeOD);
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
        cylinder(d=auger_shaft_OD,h=100,center=true);
    }
}


/* ---------------- Hopper ---------------------
  Stores material for extrusion.  Can be loaded manually, or via a fill tube.
*/
hopper_top = 0; // level with geartrain plate
// drive bearing here
hopper_bearing = -25; // Z height of bottom of hopper support bearing
// inducer mounts here
hopper_cylinder= -30; // Z height of top of cylindrical region
// main storage cylinder here
hopper_cone= -110; // Z height of cone closing taper
// rounded cone tapering down to pipe here
hopper_bottom = -180; // top of extrusion auger barrel at bottom of hopper, start of mount plate
// top of PVC pipe, with taper coupler
hopper_taper_coupler = hopper_bottom-25; // taper coupler ends here
// just PVC pipe here
hopper_nozzle_coupler = hopper_taper_coupler-25;  // start of coupler going down and out to nozzle
// coupler heads to nozzle from here
hopper_nozzle_Z=hopper_nozzle_coupler-125; // exit area where nozzle threads on



hopper_coneR=75; // radius of central core of hopper
hopper_augerXY=[2*hopper_coneR,100]; // top plate around auger

hopper_feed_center=[0,-60,0]; // center of feed area square (sticks out for manual feeding)

hopper_round=20; // corner rounding

hopper_top_rim=5; // thickness of top rim

hopper_exitOD=pipe_coupler_OD+2*3;


// translation to tool mounting plate center
toolplate_center=[0,38,hopper_bottom-40]; // center point of our mount
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
hopper_boltout=4;
hopper_plate_bolts=[
    [hopper_coneR+hopper_boltout,-25,0], // -hopper_augerXY[1]/2,0], // sides (bolted)
    [hopper_coneR-hopper_round,+hopper_augerXY[1]/2+3+hopper_boltout,0] // back (on studs)
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
        fe=2*hopper_coneR;
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
    translate([0,0,hopper_cone+shift_bottom]) {
        h=hopper_cylinder - hopper_cone+enlarge;
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
        pe=pipe_coupler_OD/2 + enlarge + enlarge_exit;
        translate([0,0,hopper_bottom+0.01*enlarge]) cylinder(r=pe,h=0.1);
        
        // Cone taper to central bulge to hold material
        re=hopper_coneR + enlarge;
        translate([0,0,hopper_cone]) scale([1,1,0.75]) sphere(r=re);
        
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
                hopper_cylinder(enlarge, 0);
                
                // Top feed plate
                translate([0,0,hopper_top])
                linear_extrude(height=0.1-0.01*enlarge,convexity=2)
                    offset(r=enlarge)
                        hopper_top_plate_2D();
            }
        }
        // Carve space for stepper gear head to not interfere with hopper
        translate(stepper_center) rotate(stepper_rotate) {
            enlargelimit=2; // keep enlarged rim from hitting gear
            enlargelimited = enlarge>enlargelimit?enlargelimit:enlarge;
            
            cyl(r=15 - enlargelimited, h=25 - 2*enlargelimited, rounding=5, anchor=CENTER);
        /*
        // NEMA 17 hanging down:
            xy=44+2*5 - 2*enlarge;
            z=2*stepper_height - 2*enlarge;
            cuboid([xy,xy,z], rounding=10 - enlarge);
        */
        }
    }
}

// 3D space for PVC pipe to be glued in
module hopper_pipe_space()
{
    // taper coupler, machined with a taper on the feed side
    translate([0,0,hopper_taper_coupler])
        cylinder(d=pipe_coupler_OD,h=hopper_cone - hopper_taper_coupler);
    
    // through pipe in middle
    translate([0,0,hopper_nozzle_Z])
        cylinder(d=pipe_OD,h=hopper_cone - hopper_nozzle_Z);
    
    // nozzle coupler on bottom (cemented in afterwards)
    translate([0,0,hopper_nozzle_Z])
        cylinder(d=pipe_coupler_OD,h=hopper_nozzle_coupler - hopper_nozzle_Z);
    
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
    rib_angle = 45; // tilt angle of ribs relative to vertical
    for (phase=[0,1])
    intersection() {
        hopper_shape(wall+rib_top,phase?0:rib_bottom)
            // taper out ribs on bottom
            if (phase==0) translate([0,0,hopper_taper_coupler]) cylinder(d=hopper_exitOD,h=1);
        
        // Ribs are thin cubes
        translate([0,0,hopper_bottom])
        for (angle=[0:60:180-1]) for (tilt=[-rib_angle,0,+rib_angle])
            rotate([tilt,0,angle + 30*phase])
                cube([500,rib_wide,500],center=true);
    }
            
    // transition taper between ribs and pipe
    translate([0,0,hopper_bottom])
        cylinder(d1=hopper_exitOD,d2=hopper_exitOD+12,h=25,center=true);
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
                mount_extra=[0,0,15];
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
inducer_Z_endspiral=hopper_bottom + 5; // top of spiral area
inducer_Z_start=inducer_Z_endspiral; // bottom of inducer, tips

inducer_wall=3.5; // thickness of body of inducer

inducer_hopper_clearance=3; // distance between inducer and hopper (allow assembly, reduce grinding)

inducer_bladeW=10.3; // width + clearance for steel wiper blade of inducer (needs to be thick to resist torsion)
inducer_bladeH=2.5; // thickness of slot for steel strip
inducer_bladeR=hopper_coneR - inducer_hopper_clearance; // radius of main blade in XY plane
inducer_blade_mount=3; // plastic around the blade itself

inducer_mountD = hopper_bearing_stack_OD; // outside of mounting cylinder


inducer_Z_threadstop=-75; // Z height where auger helix threading stops

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
            cylinder(d=pipe_ID+2*inducer_wall+2*enlarge,h=1);
    }
}

// Top-down view of 2D slot for blade
module inducer_blade_top2D(enlarge = 0)
{
    square([(inducer_bladeW+2*enlarge),2*inducer_bladeR],center=true); // main arms
}
module inducer_blade_top3D() 
{
    bottom = inducer_Z_start;
    translate([0,0,inducer_Z_start])
        linear_extrude(height=inducer_Z_end - inducer_Z_start,convexity=4) {
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

inducer_mountscrew_center=[auger_thread_OD*0.5+inducer_bladeW,0,inducer_Z_end-20];
inducer_mountscrew_rotate=[0,-90,0];

// Full inducer shape
module inducer() {
    difference() {
        union() {
            inducer_body(); // steel blade added later
        }
        
        // Screws to hold and align the blade strip steel
        for (side=[-1,+1]) scale([1,side,1])
            for (y=[0, 0.3])
                translate([0,(0.5+y)*hopper_coneR,inducer_Z_end-0.3*y*hopper_coneR])
                    rotate([180-20,0,0])
                    {
                        cylinder(d=M3_tapID,h=50);
                        translate([0,0,10])
                            cylinder(d=M3_insertOD,d2=M3_insertOD*2,h=25);
                    }
                    
        auger_axle_OD=1/2*inch + 0.5; // across the shaft
        auger_hex_OD=3/4*inch + 0.5; // across the flats of the hex
        
        // Space for auger mounting bolt (1/2" bolt welded to top of auger)
        cylinder(d=auger_axle_OD,h=200,center=true);
        translate([0,0,inducer_Z_cylinder-0.1])
            cylinder(d=auger_hex_OD/cos(30),$fn=6,h=11/32*inch);
        
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
        union() {
            translate([0,0,inducer_Z_start]) cylinder(d=inducer_mountD,h=inducer_bladeH);
            intersection() {
                inducer_blade_top3D();
                difference() {
                    inducer_profile_3D(-0.01); // interior of hopper
                    inducer_profile_3D(-inducer_bladeH); // interior of hopper
                    translate([0,0,inducer_Z_end]) cylinder(d=inducer_mountD,h=25,center=true);
                }
            }
        }
        inducer_thread_space();
    }
}

// 2D (printable) cross section of blade
module inducer_blade_section() {
    projection(cut=true) rotate([0,90,0]) inducer_blade();
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
nozzle_diameter=10; // 15; // diameter of exit hole of nozzle
nozzle_wall=2.0; // thickness of plastic around nozzle
nozzle_flats=8; // number of flat sides
nozzle_OD=nozzle_pipe_OD; // diameter of outside of nozzle (across flats)

nozzle_Z=25; // height of nozzle, not including threads
nozzle_thread_Z=15; // height of nozzle threaded portion
nozzle_exit_Z=4; // straight area at nozzle exit

// Threaded area so nozzle can thread onto pipe.  Facing up, ends at origin.
module nozzle_inside_threads(bevelbottom=true)
{
    translate([0,0,-2.3-pipe_thread_Z])
    npt_threaded_rod(size=nozzle_pipe_size, $slop=clearance, bevel2=bevelbottom, internal=true, orient=BOTTOM, anchor=TOP);
}

// Clear area so material can flow through pipe
module nozzle_inside_flow()
{
    d=nozzle_pipe_ID;
    taper=2;
    translate([0,0,-taper])
        cylinder(d1=d, d2=d-taper,h=taper);
}


// Outside of nozzle around threads
module nozzle_outside_threads(enlarge=0) {
    halfangle = 360/nozzle_flats/2;
    translate([0,0,-pipe_thread_Z])
    rotate([0,0,halfangle])
    cylinder(d=(nozzle_OD + 2*enlarge)/cos(halfangle),
        h=pipe_thread_Z,
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
        translate([nozzle_OD/2+nozzle_wall,0,-nozzle_thread_Z/2])
            rotate([0,90,0]) rotate([0,0,-90])
                linear_extrude(height=2,center=true,convexity=6)
                    text(str(nozzle_diameter),halign="center",valign="center",size=8);
}

// Overall finished nozzle
module nozzle(wall=nozzle_wall) {
    difference() {
        union() {
            hull() {
                nozzle_outside_threads(wall);
                nozzle_flow(wall);
            }
            cylinder(d=nozzle_diameter+2*wall,h=nozzle_Z); // final exit surface
            nozzle_text();
        }
        
        cylinder(d=nozzle_diameter,h=nozzle_Z+1); // thru hole and exit
        
        nozzle_flow(0.0); // inside of flow area
        
        nozzle_inside_threads(); // threadable area
        
        // Trim off bottom so it doesn't need to be threaded as long
        translate([0,0,-nozzle_thread_Z-50]) cube([100,100,100],center=true); 
        
        if (0) // cutaway section
            rotate([0,0,360/8/2]) translate([0,0,-50]) cube([100,100,100]); 
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


//extruder_demo(); // Entire assembly
//#difference() { hopper_exterior(); translate([200,200,0]) cube([400,400,800],center=true); } // cutaway
//inducer();
//inducer_blade();
//geartrain_assembled();
//hopper_shape(); // interior, for volume estimation


// 3D printable parts:
//hopper_printable();
//hopper_mount_plate_2D();
//inducer_printable();
//inducer_blade_section();
//auger_bearing_stack();
//auger_weld_support();
//pipewall_sections();
//geartrain_printable();
geartrain_frame_printable();
//nozzle();








