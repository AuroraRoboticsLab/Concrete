/*
  Tiling mold for making mortar test cylinders.
  Scalable to an arbitrary number of tests, by stacking
  copies of this mold.  
  
  Stack these molds along two 3mm (1/8 inch) diameter bamboo skewers.
  
  Dr. Orion Lawlor, lawlor@alaska.edu, 2024-02-05 (Public Domain)
*/
//$fs=0.1; $fa=2; // smooth and slow
$fs=0.2; $fa=5; // balanced
//$fs=0.3; $fa=15; // coarse and fast

R=7.5; // 15x30mm, 1/10 scale ASTM C39 cylinder
H=4*R; // height of cylinder

wall=1.65; // plastic around sides of cylinder

spacing=2*R+wall;
offset=[cos(60)*spacing,sin(60)*spacing];

copies=3;

skewer=3.4; // 3mm (1/8 inch) alignment rods, plus a little space
skewL=2*R; // length of skewer rod wrap
skewW=2; // plastic around alignment rods
skewX=spacing/2+skewer+1; // X centerline of skewer
skewZ=skewer/2+skewW; // Z centerline of skewer
skewA=60; // angle of skewers


module honeyline() {
    for (i=[0:copies-1])
        translate([i*spacing,0])
            children();
}
module honeygrid() {
    children();
    translate(offset) children();
}

module honeycircles(enlarge=0) {
    honeygrid() honeyline() circle(r=R+enlarge);
}

// Outside of mold shape
module mold2D() {
    round=3;
    difference() {
        offset(r=-round) offset(r=+round)
            honeycircles(wall);
    }
}

module skewer_starts() {
    translate(offset*0.5)
    for (side=[0,1])
            translate([side?(copies-1)*spacing+skewX:-skewX,0,skewZ])
            rotate([0,0,side?+60:-120])
                rotate([0,90,0])
                    scale([-1,1,1])
                        children();
}

module full_mold() {
    difference() {
        // Start with cylinder outsides and skewers
        union() {
            linear_extrude(height=H,convexity=6) mold2D();
            
            // Wraps around skewer, bevels over to main body
            skewer_starts() {
                hull() {
                    cylinder(d=skewer+2*skewW,h=skewL,center=true);
                    translate([-skewZ,10,-skewL/2]) cube([H/2,2,skewL]);
                }
            }
        }
        
        // Carve skewer holes
        skewer_starts() {
            cylinder(d=skewer,h=4*skewL,center=true);
        }
        
        // Carve sample holes
        translate([0,0,-1])
        linear_extrude(height=H+2,convexity=6) honeycircles();
        
        // Trim sides to allow stacking
        big=300;
        translate([0,-big,0]) cube(2*[big,big,big],center=true);
        translate([0,offset[1]+big,0]) cube(2*[big,big,big],center=true);
        
    }
}

full_mold();

