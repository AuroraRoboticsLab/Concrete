/*
 Spacer tube to hold two bearings apart on the roller bolt.
*/
include <interfaces.scad>;

bearingID=3/8*inch+0.4; // space for bolt
bearingOD=9/16*inch+0.25; // cavity for bearing (with clearance)
bearingZ=3/8*inch+0.5; // height of bearing


tubeZ = sparOD - 2*bearingZ;
tubeID = sparbolt+0.5;
tubeOD = bearingOD - 1.0;

difference() {
    cylinder(d=tubeOD,h=tubeZ);
    cylinder(d=tubeID,h=3*tubeZ,center=true);
}

