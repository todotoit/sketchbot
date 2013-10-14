/*
 *** Sketchbot Workshop by todo.to.it ***
 *** This sketch converts a freehand drawing to GCode. 
 *** Version 0.3 - still somehow buggy
 *** Castrignano de' Greci, August 2013
 *** Written by TODO.TO.IT / Giorgio Olivero
 *** Processing version: 2.0.2 
 *** This software is released under a: 
 *** Creative Commons Attribution-NonCommercial-ShareAlike 3.0 CC BY-NC-SA
 *** http://creativecommons.org/licenses/by-nc-sa/3.0/
 */


// Paper sheet dimensions (in mm in real life)
int pW = 410;
int pH = 280;

// let's increase them for a bigger preview in Processing
int scaleRatio = 2;
float sr = scaleRatio;
int ppW = pW*scaleRatio;
int ppH = pH*scaleRatio;

// Defines an output file
PrintWriter output;
boolean GCodeExported = false;

// Define pen UP and DOWN positions
float penUp = 90.0;
float penDown = 0.0;
boolean isPenDown = false; // used in order not to repeat unnecessarily the penDown command

// Define Feed rate (stepper motors speed)
float motorFeedSlow = 140.0;
float motorFeedFast = 1200.0;

import toxi.geom.*;
import toxi.geom.mesh.*;
import toxi.processing.*;
import toxi.math.waves.*;
import toxi.util.*;
import toxi.math.noise.*;

// arraylist to save lines cordinates
ToxiclibsSupport gfx;
ArrayList<Line2D> pixelLines = new ArrayList<Line2D>();
ArrayList<Line2D> pixelLinesMirror = new ArrayList<Line2D>();
ArrayList<Line2D> paperLines = new ArrayList<Line2D>();
boolean showMirror = false; // used to display the mirrored lines
boolean flushedLines = false; // is the line buffers have been emptied

void setup() {
  gfx = new ToxiclibsSupport(this); 
  //cp5 = new ControlP5(this);
  frameRate(30);
  size(ppW, ppH);
  background(255); // white background
  noFill(); // shapes will have no fill
  stroke(0); // stroke color set as black
  smooth(4); // set anti-aliasing

  // sets the path and custom filename for the GCode export
  String outputFolder = "GCode_export/";
  String outputFile = "myGCode";
  String thismoment = dateNow();
  output = createWriter(outputFolder + thismoment + outputFile+".ngc"); // filename ofr the GCode File
  GCodeInit();
}


void draw() {

  background(240);

  if (mousePressed) {
    Line2D linePixel = new Line2D(new Vec2D(pmouseX, pmouseY), new Vec2D(mouseX, mouseY)); 
    Line2D linePixelMirror = new Line2D(new Vec2D(width-pmouseX, pmouseY), new Vec2D(width-mouseX, mouseY)); 
    pixelLines.add(linePixel); // processing canvas coordinates
    pixelLinesMirror.add(linePixelMirror); // processing canvas coordinates
  }

  stroke(0, 240);
  for (int i=0; i<pixelLines.size(); i++) {
    Line2D l = pixelLines.get(i);
    gfx.line(l);
  }

  if (showMirror == true) {
    stroke(0, 160);
    for (int j=0; j<pixelLinesMirror.size(); j++) {
      Line2D lm = pixelLinesMirror.get(j);
      gfx.line(lm);
    }
  }
}

