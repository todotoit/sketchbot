/*
 *** Sketchbot Workshop by todo.to.it ***
 *** This sketch converts an SVG drawing to GCode. 
 *** Version 0.3 - still somehow buggy
 *** Castrignano de' Greci, August 2013
 *** Written by TODO.TO.IT / Giorgio Olivero
 *** Processing version: 2.0.2 
 *** This software is released under a: 
 *** Creative Commons Attribution-NonCommercial-ShareAlike 3.0 CC BY-NC-SA
 *** http://creativecommons.org/licenses/by-nc-sa/3.0/
 */

// Paper sheet dimensions (in mm in real life)
int pW = 700;
int pH = 700;

// let's increase them for a bigger preview in Processing
int scaleRatio = 2;
float sr = scaleRatio;
int ppW = pW*scaleRatio;
int ppH = pH*scaleRatio;

// Defines an output file
PrintWriter output;
boolean GCodeExported = false;

// Definess pen UP and DOWN positions
float penUp = 90.0;
float penDown = 0.0;
boolean isPenDown = false; // used in order not to repeat unnecessarily the penDown command

// Define Feed rate (stepper motors speed)
float motorFeedSlow = 185.0; // used while drawing
float motorFeedFast = 1880.0; // used while moving between paths

import geomerative.*;
import toxi.geom.*;
import toxi.geom.mesh.*;
import toxi.processing.*;
import toxi.math.waves.*;
import toxi.util.*;
import toxi.math.noise.*;
//import controlP5.*;

// arraylist to save lines cordinates
ToxiclibsSupport gfx;
ArrayList<Line2D> pixelLines = new ArrayList<Line2D>();
ArrayList<Line2D> paperLines = new ArrayList<Line2D>();

// Geomerative (SVG) stuff
RShape grp;
RShape newGrp;
float pointSeparation = 1.0;
RPoint[] pointsSVG;
RPoint[][] pointPaths;


void setup() {

  gfx = new ToxiclibsSupport(this); 
  RG.init(this);
  grp = RG.loadShape("70x70GRID.svg"); // ==> THIS IS THE SVG FILENAME, PUT IT IN THE 'data' folder
  RG.setPolygonizer( RG.UNIFORMLENGTH );
  RG.setPolygonizerLength( pointSeparation );
  newGrp = RG.polygonize( grp );
  newGrp.scale(scaleRatio);
  pointsSVG = newGrp.getPoints();
  pointPaths = newGrp.getPointsInPaths();
  println(pointPaths);
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
  output = createWriter(outputFolder + thismoment + outputFile + ".ngc"); // filename ofr the GCode File
  GCodeInit();

  // saves the source SVG paths to Line2D instances
  for (int i = 0; i<pointPaths.length; i++) {
    if (pointPaths[i] != null) {
      // repeat for each path in the source SVG
      for (int j = 1; j<pointPaths[i].length; j++) {
        Line2D linePixel = new Line2D(new Vec2D(pointPaths[i][j-1].x, pointPaths[i][j-1].y), new Vec2D(pointPaths[i][j].x, pointPaths[i][j].y));
        pixelLines.add(linePixel);
      }
    }
  }
}



void draw() {

  background(255);
  RG.ignoreStyles();
  noFill();
  stroke(0, 90);
  //newGrp.draw(); // draws the original SVG

  for (int i=0; i<pixelLines.size(); i++) {
    Line2D l = pixelLines.get(i);
    gfx.line(l);
  }
}

