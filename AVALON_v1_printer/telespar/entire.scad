/*
 Entire printer model: frame and brackets

*/

fullview=0; // 0: fast;  1: complete

entire=1; // sets flag to suppress geometry in includes
include <interfaces.scad>;
$fs=0.5; $fa=5; // coarser render

include <Zroller.scad>;
include <carrierX.scad>;

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
module make_spar(length=68*inch)
{
    translate([-sparOD/2,-0.5*inch,-sparOD/2]) color(sparRGB) 
        cube([sparOD,1*inch+length,sparOD]);
}





// Total travel on each axis (must be integer inches for spar holes to line up)
travelX = 72*inch;
travelY = 72*inch;
travelZ = 72*inch;

frontY = 4*inch; // extra spar off front (open side)
backY = 4*inch; // extra spar off back (crossbar side)

leftX = 8*inch; // stepper side
rightX = 4*inch; // return side

// Total chain path (sprocket to sprocket) on each axis (must be integer inches)
chainX = travelX + (leftX+rightX);
chainY = travelY + (frontY+backY);
chainZ = travelZ + 4*inch;

// Rotation to orient steppers on each axis
//  Flip to put chain on the correct side of the spar (in chain coords)
//  Start to move the spar to the correct location
rotateZ = [90,0,0];  flipZ=[1,1,1];  startZ = [-travelX/2,-travelY/2,0]+[-3*inch,0,0];
rotateY = [0,-90,0];  flipY=[1,1,-1];  startY = [-travelX/2,-travelY/2,0]+[0,-backY,0];
rotateX = [0,90,-90]; flipX=[1,1,-1];  startX = [-travelX/2,0,0]+[-leftX,0,sparOD+sparC];

// Symmetry around X axis
module mirrorX() {
    children();
    scale([-1,1,1]) children();
}
// Symmetry around Y axis
module mirrorY() {
    children();
    scale([1,-1,1]) children();
}


// Z axis uprights
module sparsZ() {
    // Main Z upright spars
    mirrorX() mirrorY() 
        translate(startZ) rotate(rotateZ) {
            scale(flipZ) {
                make_spar(chainZ);
                chain_drive(chainZ);
            }
        }
}

// Y axis spars
module sparsY() {
    // Main Y roller spars
    mirrorX() 
        translate(startY) rotate(rotateY) {
            scale(flipY) {
                make_spar(chainY);
                chain_drive(chainY);
            }
            
            // V rollers on each end of Y, to index on Z uprights
            for (end=[0,1]) translate([0,(end?chainY-frontY:+backY),0])
            rotate([90,0,0]) rotate([0,end?-90:+90,0])
            {
                Zroller_holder();
                ZrollerC() Zroller3D();
            }
        }
   
    // Back X crossbar keeps Ys spaced correctly, and can have diagonals for squareness
    overhang=8*inch;
    translate(startY+[-overhang,-3*inch+backY,+sparOD]) rotate([0,0,-90]) make_spar(travelX+2*overhang);
}

// X axis spar(s)
module sparsX() {
    translate(startX) rotate(rotateX) {
        scale(flipX) {
            make_spar(chainX);
            chain_drive(chainX);
        }
        
        for (end=[0,1]) translate([0,(end?chainX-rightX-sparOD/2:+leftX+sparOD/2),0])
            scale([1,end?-1:+1,1])
            rotate([90,0,0])
            rotate([0,0,90])
            translate([0,0,-carrierXZ/2])
                carrierX(); // +Z is down the spar
    }
}


//make_spar();
//chain_drive();

// Current XYZ gcode location that the print head has moved to
position=[20*inch,40*inch,30*inch];


sparsZ();
translate([0,0,position[2]]) sparsY();
translate([0,-travelY/2+position[1],position[2]]) sparsX();



