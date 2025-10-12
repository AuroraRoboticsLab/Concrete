/*
 Spacer tube to hold two bearings apart on the roller bolt.
*/
include <interfaces.scad>;

tubeZ = sparOD - 2*bearingZ;
tubeID = sparbolt+0.5;
tubeOD = bearingOD - 1.0;

difference() {
    cylinder(d=tubeOD,h=tubeZ);
    cylinder(d=tubeID,h=3*tubeZ,center=true);
}

