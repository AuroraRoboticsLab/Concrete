/*
 Spacer tube to hold two bearings apart on the roller bolt.
 
 A typical stackup on a 3/8" bolt:
    - 3D printed part
    - washer
    - roller bearing
    - this spacer
    - roller bearing
    - washer
    - 3D printed part
 
*/
include <interfaces.scad>;

tubeZ = sparOD - 2*bearingZ;
tubeID = sparbolt+0.5;
tubeOD = bearingOD - 1.0;

for (copy=[0,1]) translate([copy*20,0,0])
difference() {
    cylinder(d=tubeOD,h=tubeZ);
    cylinder(d=tubeID,h=3*tubeZ,center=true);
}
