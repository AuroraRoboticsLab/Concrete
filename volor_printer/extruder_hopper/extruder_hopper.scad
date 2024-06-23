/*
3D printed hopper for a concrete / mortar / clay extruder

Uses a large Spyder 1 inch diameter drill bit as an auger.
Mixes and pressurizes inside a 1 inch (nominal ID) steel pipe,
so the nozzles need to thread onto 1 inch FPT pipe threads.

Auger screw is a 1 inch diameter by 18 inch long wood drill bit, ship auger style, with 11mm across the flats.  (Marketed as 7/16" ball groove shank.)  The tip is ground off to avoid interference with the nozzle.
    https://www.lowes.com/pd/Spyder-Spy-1-in-x-18-in-Auger-Bit/1003203046
    
(A possible replacement is Dewalt Ship Auger, 1 Inch x 17 Inch (DW1687).
    https://www.amazon.com/DEWALT-DW1687-1-Inch-17-Inch-Auger/dp/B00004RGZI/
)   

The auger shaft fits a 1/2" ID cartridge bearing, R8-2RS
    https://www.amazon.com/Sackorange-R8-2RS-Premium-Sealed-Bearing/dp/B07DCQLCS3/


Auger barrel is a 6" long chunk of 1" nominal ID black iron steel pipe:
https://www.lowes.com/pd/Mueller-Proline-6-in-L-x-1-in-x-1-in-dia-Black-Steel-Nipple-Fitting/3396596




*/
include <BOSL2/std.scad> /* https://github.com/BelfrySCAD/BOSL2/ */
include <BOSL2/gears.scad> /* for drive gears */
include <BOSL2/threading.scad> /* for pipe thread on auger barrel */

$fs=0.1; $fa=5;

inch=25.4;

// Auger barrel parameters
clearance=0.1;
pipe_size = 1; // 1 inch (nominal) pipe thread for auger barrel.
pipe_OD = 1.32 * inch; // outside diameter of pipe, with a little clearance
pipe_ID = 1*inch + 2; // inside diameter of pipe

pipe_thread_Z=24; // height of end of threaded zone

// Threaded area so nozzle can thread onto pipe.  Facing up, ends at origin.
module pipe_inside_threads(bevelbottom=true)
{
    translate([0,0,-2.3-pipe_thread_Z])
    npt_threaded_rod(size=pipe_size, $slop=clearance, bevel2=bevelbottom, internal=true, orient=BOTTOM, anchor=TOP);
}

// Clear area so material can flow through pipe
module pipe_inside_flow()
{
    d=pipe_ID;
    taper=2;
    translate([0,0,-taper])
        cylinder(d1=d, d2=d-taper,h=taper);
}



// Tap plastic for M3 screw at this diameter
M3_tapID = 2.3;
M3_shaftOD = 3.1;
M3_headOD = 6.1;
M3_headZ = 3.2;

/* --------------- Geartrain ------------------
 Input side: connects to the D shaft of a NEMA 17 stepper motor.
 Output side: connects to the hex shaft of the auger itself
*/

gear_module=1.25; // large teeth for robustness and easy printing
gear_teeth_stepper=13; // few teeth on stepper side
gear_teeth_auger=gear_teeth_stepper*5; // torque amplification factor
gear_helical=20; // helix angle (degrees)
gear_thickness=10;
gear_clearance=0.2;

auger_hex_flats=11.1; // across the flats of hex shaft on auger
auger_hex_len=30; // length of auger's hex flats

// NEMA 17 stepper mount dimensions
stepper_boltOD=3.5;
stepper_boltXY=31.0/2;
stepper_holeOD=22.5; // central hole
stepper_shaftOD=5.1; // shaft

// location of stepper relative to auger top
stepper_center = [0,gear_clearance + gear_dist(mod=gear_module, helical=gear_helical, teeth1=gear_teeth_stepper, teeth2=gear_teeth_auger),0];
stepper_rotate = [0,0,45];

// Gear on stepper's output shaft
module gear_stepper() {
    boss_OD=14;
    boss_Z=18; // full length of stepper's shaft, minus mount plate thickness
    boss_tapD=M3_tapID; // tapped for M3 setscrew
    
    shaft_ID=5;
    difference() {
        union() {
            spur_gear(teeth=gear_teeth_stepper, mod=gear_module, thickness=gear_thickness, helical=-gear_helical, herringbone=true,anchor=BOTTOM);
            cylinder(d=boss_OD,h=boss_Z);
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

// Make space for auger's hex flats
module auger_hex_hole() 
{
    // hex hole
    cylinder($fn=6, d=auger_hex_flats/cos(30), h=100,center=true);

}

// Gear on auger shaft
module gear_auger() {
    difference() {
        union() {
            spur_gear(teeth=gear_teeth_auger, mod=gear_module, thickness=gear_thickness, helical=gear_helical, herringbone=true,anchor=BOTTOM);
            
            // Ridge to cleanly support auger gear?  (or just use washer?)
            //translate([0,0,-1])
            //    cylinder(d=22,h=gear_thickness);
        }
        
        auger_hex_hole();
        
        // clearance ring around stepper mounting bolt heads
        rotate_extrude() {
            h=2.5; // height of stepper heads
            D=12; // diameter of clearance circle across heads
            R=stepper_center[1]-sqrt(2)*stepper_boltXY; //<- FIXME what if stepper isn't at 45 deg?
            translate([R,h-0.5*D]) circle(d=D);
        }
        
        // lighten holes
        rI = auger_hex_flats/2 + 3;
        rO = pitch_radius(teeth=gear_teeth_auger, mod=gear_module) - 3;
        round=6;
        rib=6;
        linear_extrude(height=100,center=true,convexity=4) 
            offset(r=+round) offset(r=-round)
            difference() {
                circle(r=rO);
                circle(r=rI);
                for (ribAngle=[0:60:180]) rotate([0,0,ribAngle])
                    square([200,rib],center=true);
            }
    }
}

// Clamps onto auger's hex flats, to hold auger vertically
module auger_clamp() {
    h=auger_hex_len - gear_thickness - 2;
    d=22;
    difference() {
        cylinder(d=d,h=h);
        
        auger_hex_hole();
        
        slotW=1.0; // thickness of clamping slot
        translate([0,-slotW/2,-1]) cube([50,slotW,50]); // clamping slot
        
        translate([d/2-3,0,h/2]) rotate([-90,0,0])
        {
            cylinder(d=M3_tapID,h=100,center=true); // thru tap
            cylinder(d=M3_shaftOD,h=100); // shaft on one side
            translate([0,0,4]) cylinder(d=M3_headOD,h=100); // head space
        }
    }
}

// Underneath gear plate, spaces the auger thrust bearing
module auger_bearing_stack() {
    h=45;
    bearingOD=1.125*inch+0.2;
    bearingZ=8;
    difference() {
        // outer body
        cylinder(d=32,h=h);
        
        // space for bearing
        translate([0,0,h-bearingZ])
            cylinder(d=bearingOD,h=bearingZ+1);
        
        // thru shaft
        translate([0,0,-0.1])
        cylinder(d1=0.5*inch, d2=16,h=h);
    }
}

// Cover to keep loaded material out of the extruder gear
module geartrain_cover_2D(clearR = 1.0) {
    lilR = min(stepper_holeOD, clearR + outer_radius(teeth=gear_teeth_stepper, mod=gear_module, helical=gear_helical));
    
    bigR = clearR + outer_radius(teeth=gear_teeth_auger, mod=gear_module, helical=gear_helical);
    hull() {
        circle(r=bigR);
        translate(stepper_center) circle(r=lilR);
    }
}

module geartrain_cover() {
    wall = 1.7;
    height = 14; // clearance over bottom of gear plate (stack-up for washer, old taller drive gear, etc)
    floor = 1.5;
    p=hopper_plate_bolts[1]; // mount bolt center
    
    // walls
    linear_extrude(height = height+floor)
    difference() {
        union() {
            offset(r=+wall) geartrain_cover_2D();
            // supports around mounting bolts
            mirror_hopper_plate_bolts(p) offset(r=+1) circle(d=M3_shaftOD);
        }
        geartrain_cover_2D();
        mirror_hopper_plate_bolts(p) circle(d=M3_shaftOD);
    }
    
    // top 'floor'
    translate([0,0,height])
    linear_extrude(height = floor)
    difference() {
        offset(r=+wall) geartrain_cover_2D();
        circle(d=25); // auger clamp
        translate(stepper_center) circle(d=stepper_holeOD); // <- needs to clear grub screw heads
    }
    
    // bottom 'floor' with mount bolts
    linear_extrude(height = floor)
    difference() {
        hull() {
            offset(r=+wall) geartrain_cover_2D();
            mirror_hopper_plate_bolts(p) circle(d=8);
        }
        geartrain_cover_2D();
        mirror_hopper_plate_bolts(p) circle(d=M3_shaftOD);
    }
    
}


// Demo of how geartrain looks when assembled
module geartrain_assembled() 
{
    gear_auger();
    translate([0,0,gear_thickness+1]) auger_clamp();
    
    rotate([180,0,0]) auger_bearing_stack();
    
    //circle(d=25.4);

    translate(stepper_center) color([1,0,1]) {
        gear_stepper();
        rotate(stepper_rotate) square([42,42],center=true); // NEMA 17 outside
    }
    
    # geartrain_cover();
}

// Printable parts in geartrain, ready for printing
module geartrain_printable() {
    d=stepper_center[1]*1.1; // distance between parts
    //translate([0,0,gear_thickness]) rotate([180,0,0]) gear_auger();
    translate([0,d,0]) gear_stepper();
    //translate([d,0,0]) auger_clamp();
    //translate([0.8*d,0.8*d,0]) auger_bearing_stack();
}

module geartrain_cover_printable() {
    rotate([180,0,0]) geartrain_cover();
}


/* ---------------- Hopper ---------------------
  Stores material for extrusion.  Can be loaded manually, or via a fill tube.
*/
hopper_bottom = -225; // top of extrusion auger barrel at bottom of hopper
hopper_cone= -100; // Z height of cone area
hopper_top = 0; // level with geartrain plate

hopper_coneR=64; // radius of central core of hopper
hopper_augerXY=[2*hopper_coneR,50]; // top plate around auger

hopper_feed_center=[0,-40,0]; // center of feed area square

hopper_round=20; // corner rounding

hopper_exitOD=pipe_OD+2*3;


// translation to tool mounting plate center
toolplate_center=[0,15,hopper_bottom-34]; // center point of our mount
toolplate_size=[45,12,80]; // plastic that bolts to the actual toolplate
toolplate_back = toolplate_center + [0,toolplate_size[1]/2,0]; // back face

toolplate_clearance=[60,14,32]; // space for belts and mounting bolts


// positive X plate mounting bolt centers (negative X is mirror image)
hopper_boltout=4;
hopper_plate_bolts=[
    [hopper_coneR+hopper_boltout,-hopper_augerXY[1]/2,0], // sides
    [hopper_coneR-hopper_round,+hopper_augerXY[1]/2+3+hopper_boltout,0] // back
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

// 3D interior volume of hopper exit and central bulge
module hopper_bulge_exit(enlarge=0, enlarge_exit=0)
{
    hull() {
        // Exit point
        pe=pipe_ID/2 + enlarge + enlarge_exit;
        translate([0,0,hopper_bottom+0.01*enlarge]) cylinder(r=pe,h=0.1);
        
        // Central bulge to hold material
        re=hopper_coneR + enlarge;
        translate([0,0,hopper_cone]) sphere(r=re);
    }
}


// 3D interior volume of hopper
module hopper_shape(enlarge=0, enlarge_exit=0)
{
    difference() {
        hull() {
            hopper_bulge_exit(enlarge, enlarge_exit);
            
            // Top plate
            translate([0,0,hopper_top])
            linear_extrude(height=0.1-0.01*enlarge,convexity=2)
                offset(r=enlarge)
                    hopper_top_plate_2D();
        }
        // space for stepper on top
        translate(stepper_center) rotate(stepper_rotate) {
            xy=44+2*5 - 2*enlarge;
            z=100 - 2*enlarge;
            cuboid([xy,xy,z], rounding=10 - enlarge);
        }
    }
}

hopper_top_rim=4;

// 3D overall shape of hopper, including mounting bolts and ribs
module hopper_exterior()
{
    wall=1.5;
    difference() {
        union() {
            hopper_shape(wall);
            intersection() { // heavy reinforcing rim around top perimeter
                cube([500,500,10],center=true);
                hopper_shape(hopper_top_rim);
            }
            
            // increasing reinforcing ribs as we approach exit (& support point)
            rib_height=3;
            intersection() {
                hopper_shape(wall*1.5,rib_height);
                //hopper_bulge_exit(wall*1.5,6);
                translate([0,0,hopper_bottom+25])
                for (angle=[0:60:180-1]) for (tilt=[-40,0,+40])
                    rotate([tilt,0,angle])
                        cube([500,3,500],center=true);
            }
                    
            // transition taper between ribs and pipe
            translate([0,0,hopper_bottom-1])
                cylinder(d1=hopper_exitOD,d2=hopper_exitOD+wall,h=5);
            
            hull() { // merge the pipe and toolplate mounts, for strength
                // Pipe thread boss
                translate([0,0,hopper_bottom]) {
                    scale([1,1,-1])
                        cylinder(d=hopper_exitOD,h=3*pipe_thread_Z);
                }
                
                // Toolplate mount
                mount_extra=[0,0,15];
                translate(toolplate_center+mount_extra) cube(toolplate_size+2*mount_extra,center=true);
            }
            
            // top bolt bosses
            for_hopper_plate_bolts() scale([1,1,-1]) cylinder(d1=10,d2=6,h=12);
        }
        // top bolt tappable holes (should these be heat set inserts?)
        for_hopper_plate_bolts() cylinder(d=M3_tapID,h=25,center=true);
        
        // carve out interior of hopper
        hopper_shape(0.0);
        
        // Space for auger barrel to thread in
        translate([0,0,hopper_bottom]) {
            pipe_inside_threads(false);
            cylinder(d=pipe_ID,h=50,center=true); // thru hole
            translate([0,0,-pipe_thread_Z]) scale([1,1,-1])
                cylinder(d=pipe_OD,h=100); // pipe extends down from here
        }
        
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

/* ---------------- Hopper Mount Plate ----------
 Mounts the auger gear and stepper motor to the top of the hopper.
*/

module for_stepper_bolt_centers()
{
    translate(stepper_center) rotate(stepper_rotate) {
        for (dx=[-1,+1]) for (dy=[-1,+1]) translate([dx*stepper_boltXY, dy*stepper_boltXY]) 
            children();
    }
}

module hopper_mount_plate_2D() 
{
    difference() {
        union() {
            hull() {
                for_hopper_plate_bolts() circle(d=10);
                for_stepper_bolt_centers() circle(d=10);
            }
            offset(r=hopper_top_rim) intersection() {
                hopper_top_plate_2D();
                square([200,85],center=true);
            }
        }
        
        M3_thru=3.5; // space for M3 to thread through, plus clearance
        for_hopper_plate_bolts() circle(d=M3_thru);
        circle(d=13); // hole for auger shaft to pass through
        
        for_stepper_bolt_centers() circle(d=M3_thru);
        translate(stepper_center) rotate(stepper_rotate) circle(d=stepper_holeOD);
    }
}

module hopper_mount_plate_3D() {
    linear_extrude(height=2,convexity=6) hopper_mount_plate_2D();
}

/* ---------------- Inducer -----------------
 Threads onto auger, and pushes material down into auger area
*/
auger_thread_pitch=45; // mm between full turns
auger_thread_centerID=9; // central screw (plus some clearance)
auger_thread_edgeOD=25; // edge cross section thickness (plus some clearance)
auger_thread_OD=1*inch + 1; // outside size of auger (plus some clearance)

inducer_Z_end=-60; // top of inducer, threads on
inducer_Z_cylinder=-90; // height where mounting cylinder starts
inducer_Z_start=-210; // bottom of inducer, tips

inducer_wall=2.5; // thickness of body of inducer
inducer_ID = pipe_ID+2*inducer_wall;

inducer_hopper_clearance=3; // distance between inducer and hopper (allow assembly, reduce grinding)

inducer_Z_threadstop=-75; // Z height where auger helix threading stops
inducer_twistrate=0.4; // inducer's twist rate relative to auger


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
    cycles=4;
    translate([0,0,inducer_Z_threadstop])
    {
        // Main helix
        translate([0,0,-(cycles-1)*auger_thread_pitch]) 
            auger_thread_helix(cycles);

        // Clearance for flat end of thread grind
        d=auger_thread_OD;
        if (1) difference() {
            intersection() {
                cylinder(d=d,h=auger_thread_pitch);
                // flat end of threaded area:
                translate([0,-auger_thread_centerID/2,0]) 
                    cube([d,d,auger_thread_pitch]);
            }
            
            // don't block the continuing spiral
            linear_extrude(height=auger_thread_pitch,twist=-360,convexity=2)
            intersection() {
                square([d,d]);
                circle(d=d+1);
            } 
        }
    }
}

// Spiral shape of inducer
module inducer_spiral() {
    
    // Solid mounting cylinder on top
    translate([0,0,inducer_Z_cylinder])
        cylinder(d=inducer_ID,h=inducer_Z_end-inducer_Z_cylinder);
    // taper transition cylinder
    taper=inducer_ID/2;
    translate([0,0,inducer_Z_cylinder-taper])
        cylinder(d1=inducer_ID/2,d2=inducer_ID,h=taper);
    
    // "Wings" spiraling down
    z=inducer_Z_end-inducer_Z_start;
    augertwist=z/auger_thread_pitch*360; // twists in auger
    
    
    translate([0,0,inducer_Z_end]) scale([1,1,-1])
    linear_extrude(height=z,
        twist=inducer_twistrate*augertwist,
        convexity=4) 
    difference() 
    {
        startangle=0; // times the auger and inducer threads
        
        for (angle=[0]) rotate([0,0,startangle+angle])
        intersection() {
            // circular sweep edges to scrape and push material down,
            //   and be stiffer than straight edges
            r=hopper_coneR*0.6;
            translate([hopper_coneR*0.15,r*0.53]) 
            difference() {
                circle(r=r);
                circle(r=r-1.5*inducer_wall);
            }
            
            // limit to bottom right half
            limit=inducer_ID+hopper_coneR*1.2;
            translate([-inducer_ID/4+4,-limit+inducer_ID]) 
                square([limit,limit]);
        }
        
        // central hole for auger
        circle(d=auger_thread_OD);
    }
}

// Swept volume of inducer
module inducer_profile_3D() {
    hull() {
        hopper_bulge_exit(-inducer_hopper_clearance);
        translate([0,0,inducer_Z_end]) scale([1,1,-1]) 
            cylinder(d=pipe_ID+2*inducer_wall,h=1);
    }
}

// Full inducer shape
module inducer() {
    difference() {
        intersection() {
            inducer_spiral();
            inducer_profile_3D();
        }
        inducer_thread_space();
        
        // Holes to manage excess material
        //  Are these a good idea, or would it be better to use separate inducer gearing?
        for (holeZi=[0:2]) {
            holeZ=25+25*holeZi;
            translate([0,0,inducer_Z_end-holeZ])
                rotate([0,0,-360*inducer_twistrate*holeZ/auger_thread_pitch])
                {
                    inR = inducer_ID*0.5;
                    outR = hopper_coneR-inducer_hopper_clearance-inR;
                    translate([inR + (outR - inR)*(0.6-0.05*holeZi),0,0])
                        rotate([60,0,0])
                            cylinder(d=18-holeZi,h=50,center=true);
                }
        }
        
        // M3 grubscrew to hold inducer to auger
        translate([0,-inducer_ID/2,inducer_Z_end]) rotate([-90-45,0,0])
            cylinder(d=M3_tapID,h=inducer_ID*0.7);
    }
}

// Print from base up
module inducer_printable() {
    rotate([180,0,0]) inducer();
}


/* ---------------- Nozzle ------------------- 
  Extrudes material out the central exit hole.
  Threads onto end of auger barrel.
*/
nozzle_diameter=15; // diameter of exit hole of nozzle
nozzle_wall=2.5; // thickness of plastic around nozzle

nozzle_Z=25; // height of nozzle, not including threads
nozzle_exit_Z=4; // straight area at nozzle exit

// Outside of nozzle around threads
module nozzle_outside_threads(enlarge=0) {
    translate([0,0,-pipe_thread_Z])
    cylinder(d=pipe_OD + 2*enlarge,
        h=pipe_thread_Z,
        $fn=8 // beveled for grip / tool tightening
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
        pipe_inside_flow();
        nozzle_exit(enlarge*0.5);
    }
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
        }
        
        cylinder(d=nozzle_diameter,h=nozzle_Z+1); // thru hole and exit
        
        nozzle_flow(0.0); // inside of flow area
        
        pipe_inside_threads(); // threadable area
        
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
    translate([0,0,hopper_bottom-6*inch]) rotate([180,0,0]) nozzle();
}


//extruder_demo();
//inducer();


//hopper_printable();
//hopper_mount_plate_2D();
//inducer_printable();
geartrain_printable();
//geartrain_cover_printable();
//nozzle();







