/*

  Miniature-scale concrete mix test jig.
  Target is 10 grams (dry weight) per cylinder, about 5 cc.

  With R=7.5 this makes 15x30mm cylinders. 
  
  At layer=3 the silicone volume required is about 40cc,
  seems to need at least 47 grams of silicone-cure AB pourable.
  
  Dr. Orion Lawlor, lawlor@alaska.edu, 2024-01 (Public Domain)
*/
//$fs=0.1; $fa=2; // smooth and slow
$fs=0.2; $fa=5; // balanced
//$fs=0.3; $fa=15; // coarse and fast

R=7.5; // 5.3cc, 15x30mm nice round numbers

wall=2; // plastic around sides of cylinder
floor=2.0;  // plastic below / above cylinder
clearance=0.3; // space around test cylinder

difference() {
    intersection() {
        cylinder(r=R+wall,h=floor+wall);

        // Round off the bottom surface
        //translate([0,0,4*R-flat]) sphere(r=4*R);
    }
    
    // Test cylinder fits inside here
    translate([0,0,floor])
        cylinder(r=R+clearance,h=4*R);
    
    // Cutaway
    //cube([100,100,100]);
}

