/*
 Entire AVALON v1 printer model: frame and brackets

 Heavily inspired by Dylan Frick's overall design in Fusion.
 Built by Orion Lawlor 2025-10 (Public Domain).
*/

fullview=2; // 0: fast, skip pulleys;  1: complete; 2: bumps along spars; 3: holes along spars

entire=1; // sets flag to suppress geometry in includes
include <interfaces.scad>;
$fs=0.5; $fa=5; // coarser render

include <Xroller.scad>;
include <Yroller.scad>;
include <Zroller_big.scad>;
include <chain_retain.scad>;

include <AuroraSCAD/axes3D.scad>;
include <AuroraSCAD/bevel.scad>;
include <AuroraSCAD/sprocket.scad>;


bracketZ=3/16*inch; // thickness of bolt-on brackets
bracketRGB=[0.4,0.4,0.4]; // dark steel plasma cut brackets

// Stepper bracket, Z up, on spar at stepper centerline
module bracket_stepper() {
    color(bracketRGB) linear_extrude(height=bracketZ) rotate([0,0,180]) import("bracket_stepper.svg");
}
// Chain return idler bracket, Z up, on spar at stepper centerline
module bracket_idler() {
    color(bracketRGB) linear_extrude(height=bracketZ) rotate([0,0,180]) import("bracket_idler.svg");
}

// NEMA 34 stepper and (approximate) shaft
stepperSZ = [86,86,98];
stepperRGB = [0.2,0.2,0.2]; // black stepper case
shaftRGB=[0.8,0.8,0.9]; // bright stepper shaft steel
shaftOD = 5/8*inch;

// Centerline of chain circuit, relative to spar mounting bolt
chainC = [-75,0,0.5*inch];
chainRGB=0.9*stepperRGB; // dark steel

// Chain sprocket size and tooth count
chain_size=40; chain_teeth=17;
sprocketR = get_pitch_radius_mm(chain_size,chain_teeth);


// Chain sprocket, 17 teeth
module chain_sprocket() {
    OD = 2.0*get_outside_radius_mm(chain_size,chain_teeth);
    Z = get_thickness_mm(chain_size);
    bevel=Z*0.3;
    
    difference() {
        intersection() {
            bevelcylinder(d=OD,h=Z,bevel=bevel);
            sprocket(chain_size,chain_teeth);
        }
        cylinder(d=5/8*inch,h=50,center=true); // thru bore
    }
}

// Entire drive chain setup, origin at center of stepper spar, chain running up the +Y axis, with specified length 
module chain_drive(length=68*inch)
{
    translate([0,0,+sparOD/2]) // move to top surface
    {
        bracket_stepper();
        translate([chainC[0],0,-stepperSZ[2]/2]) color(stepperRGB) cube(stepperSZ,center=true);
        
        translate([0,length,0]) bracket_idler();
        
        if (fullview>0) for (shaft=[0,length]) 
        {
            translate([chainC[0],shaft,0])
                color(shaftRGB) cylinder(d=shaftOD,h=chainC[2]+15);
            translate(chainC+[0,shaft,-get_thickness_mm(chain_size)/2])
                color(stepperRGB) chain_sprocket();
        }
        
        // Vague illustration of chain path
        chainT=0.3*inch; // chain thickness (X)
        chainZ=0.5*inch; // chain thickness (Z)
        for (side=[-1,+1]) translate(chainC+[side*sprocketR-chainT/2,0,-chainZ/2])
            color(chainRGB) cube([chainT,length,chainZ]);
    }
}

sparRGB=[0.7,0.7,0.75]; // light blue-gray zinc coating

// Make telespar of this length, facing in +Y direction.  
// First hole is at origin
// Holes are at 1 inch spacing, so includes extra half inch on each end.
module make_spar(name="Demo",length=68*inch)
{
    echo("Spar ",name," length ",length/inch+1," inches");
    
    translate([-sparOD/2,-0.5*inch,-sparOD/2]) color(sparRGB) 
        cube([sparOD,1*inch+length,sparOD]);
    if (fullview==2) {
        for (face=[0,90]) rotate([0,face,0])
        for (hole=[0:1*inch:length]) translate([0,hole,0])
            color([0,0,0]) cube([sparOD+1,10,10],center=true);
    }
}





// Total nominal travel on each axis (must be integer inches for spar holes to line up)
travelX = 72*inch;
travelY = 72*inch;
travelZ = 72*inch;

leftX = 8*inch; // added chain on stepper side (extra long to keep stepper clear of Z axis)
rightX = 6*inch; // added chain on idler side
leftXE = 0*inch; 
rightXE = 0*inch; // extra spar on right side past idler

frontY = 5*inch; // added chain on front (open side)
frontYE = 2*inch;
backY = 5*inch; // added chain on back (crossbar side)
backYE = 3*inch; // extra spar on back side
backYC = -3*inch; // center of back crossbar relative to stepper

bottomZE = 4*inch; // bottom extra spar length
topZ = 4*inch;
topZE = 5*inch; // top extra spar length (to bolt stuff on)

// Total chain path (sprocket to sprocket) on each axis (must be integer inches)
chainX = travelX + (leftX+rightX);
chainY = travelY + (frontY+backY);
chainZ = travelZ + topZ;

module print_chain_len(name,length) {
    echo("Motion stage ",name," chain straight ",length/inch," total ",(2*length/inch+chain_teeth*0.5)," inches");
}
print_chain_len("X",chainX);
print_chain_len("Y",chainY);
print_chain_len("Z",chainZ);

// Rotation to orient steppers on each axis
//  Flip to put chain on the correct side of the spar (in chain coords)
//  Start to move the spar to the correct location
rotateZ = [90,0,0];  flipZ=[1,1,1];  startZ = [-travelX/2,-travelY/2,0]+[-3*inch,0,0];
rotateY = [0,-90,0];  flipY=[1,1,1];  startY = [-travelX/2,-travelY/2,0]+[0,-backY,0];
rotateX = [0,90,-90]; flipX=[1,1,-1];  startX = [-travelX/2,0,0]+[-leftX+0.5*inch,0,sparOD+sparC];


/* Create a spar and chain drive with this length (center of stepper to center of idler).
   Origin is at the stepper, spar extends along +Y axis. */
module motion_stage(name, length, preStepper=0, postIdler=0) {
    stepperStart = preStepper + 1*inch; // extra spar under stepper
    translate([0,-stepperStart,0]) make_spar(name, length+stepperStart+postIdler);

    chain_drive(length);
}

// Flip Y axis on this 3D point
function flipY(p) = [p[0],-p[1],p[2]];

// Z axis uprights
module sparsZ() {
    // Main Z upright spars
    mirrorX() mirrorY() 
        translate(startZ) rotate(rotateZ) {
            scale(flipZ) motion_stage("Z",chainZ, bottomZE, topZE);
        }
    
    // Base and top X crossbars 
    overhangX=24*inch;
    for (z=[-5*inch,chainZ+3*inch]) translate([0,0,z])
    mirrorY()
    translate(startZ+[-overhangX,-sparOD,0]) rotate([0,0,-90]) make_spar("ZcrossX",travelX+2*overhangX);
    
    // Base and top Y crossbars 
    overhangY=24*inch;
    bot = -3*inch;
    top = chainZ+5*inch;
    for (xside=[-1,+1]) scale([xside,1,1])
    for (z=(xside<0)?[top]:[bot,top]) translate([0,0,z])
        translate(startZ+[-sparOD,-overhangY,0]) make_spar("ZcrossY",travelY+2*overhangY);
}

// Y axis spars
module sparsY() {
    // Main Y roller spars
    mirrorX() 
        translate(startY) rotate(rotateY) {
            scale(flipY) motion_stage("Y",chainY,backYE,frontYE);
            
            for (end=[0,1]) translate([0,(end?chainY-frontY:+backY),0])
            {
                // V rollers on each end of Y, to index on Z uprights
                rotate([90,0,0]) rotate([0,end?-90:+90,0])
                {
                    Zroller_holder();
                    ZrollerC() Zroller3D();
                }
                rotate([0,90,0]) scale([-1,end?+1:-1,1]) translate([0,1*inch,0])
                    Zchain_holder();
            }
        }
   
    // The Y crossbar keeps Y spars spaced correctly,
    //  it's a spot for diagonals to hold squareness,
    //  also a good place for electronics boxes
    overhang=2*inch;
    //mirrorY() //<- crossbar kinda gets in the way of tool wiring and connections (like cleaning bucket)
    translate(startY+[-overhang,backYC,-sparOD]) rotate([0,0,-90]) make_spar("Ycross",travelX+2*overhang);
}

// X axis spar(s)
module sparsX() {
    translate(startX) rotate(rotateX) {
        scale(flipX) motion_stage("X",chainX,leftXE,rightXE);
        
        for (end=[0,1]) 
            translate([0,(end?+leftX:chainX-rightX)-0.5*inch,0])
            scale([1,end?-1:+1,1])
            rotate([0,90,0]) 
            translate([0,0,sparOD+sparC]) // mostly makes up for startX
            {
                Yroller_demo(0);
            }
    }
}

// Tool rack spars
module sparsT() {
    toolZDX = 12*inch; // inset from Z upright to tool uprights
    startT = flipY(startZ)+[toolZDX,0,0];

    // Upright tool rack spars on +Y face
    mirrorX()
        translate(startT) rotate(rotateZ) {
            stepperStart=bottomZE+1*inch;
            translate([0,-stepperStart,0]) make_spar("toolZ",chainZ+stepperStart+topZE);
        }
    
    // Set of Z crossbars at various heights (to taste)
    for (z=[16*inch, 32*inch, 48*inch, 64*inch]) 
        translate(startT + [0,-sparOD,z]) rotate(rotateX) {
            make_spar("toolX",chainX-2*toolZDX-8*inch);
        }
}

// Text labels to illustrate parts of the printer
module text_labels() {
    sz=100;
    textRGB=[0,0,0];
    color(textRGB) {
        linear_extrude(height=1) {
            translate([-travelX/2,-travelY/2,0]) 
                text("+X -> ",size=sz);
            translate([-travelX/2,-travelY/2+200,0]) rotate([0,0,90])
                text("+Y -> ",size=sz);
            
            translate([travelX/2+300,0,0]) rotate([0,0,90]) 
                text("Forklift Access",size=sz,halign="center",valign="center");
            translate([0,0,0]) rotate([0,0,90]) 
                text("Printbed",size=sz,halign="center",valign="center");
        }
        
        translate([0,travelY/2,travelZ/2]) rotate([90,0,0]) 
            linear_extrude(height=1) 
                text("Tool Rack",size=sz,halign="center",valign="center");
    }
}

// Draw the entire printer frame, with printhead at this position.
// (XYZ gcode location)
module demo_entire(position=[20*inch,40*inch,30*inch])
{
    H = [-travelX/2, -travelY/2, 0] + position;
    sparsZ();
    translate([0,0,H[2]]) sparsY();
    translate([0,H[1],H[2]]) sparsX();
    translate(H + [0,0,sparOD+sparC]) Xroller_demo(spar=0);

    sparsT();
}

//make_spar();
//chain_drive();
//sparsZ();

demo_entire();

text_labels();

