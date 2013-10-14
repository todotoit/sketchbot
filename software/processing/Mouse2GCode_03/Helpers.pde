
float fromPixelToPaperValue(float pixelValue, float sr_) {
  // normalize the pixel X,Y coordinates to the real paper sheet dimensions expressed in mm
  float paperValue = (pixelValue/sr_); 
  ;
  return paperValue;
}

void convertPixelLinesToPaperLines() {

  for (int i=0; i<pixelLines.size(); i++) {
    // converts the coordinates from pixel to paper values, adjusting for a different origin
    Line2D currentLine = pixelLines.get(i);
    float paperX1 = fromPixelToPaperValue(currentLine.a.x, sr)-pW/sr;
    float paperY1 = fromPixelToPaperValue(currentLine.a.y, sr)-pH/sr;  
    float paperX2  = fromPixelToPaperValue(currentLine.b.x, sr)-pW/sr;
    float paperY2  = fromPixelToPaperValue(currentLine.b.y, sr)-pH/sr;
    Line2D linePaper = new Line2D(new Vec2D(paperX1, paperY1), new Vec2D(paperX2, paperY2));
    paperLines.add(linePaper);
  }

  if (showMirror == true) {
    // prepares for the GCode file also the mirrored lines
    for (int i=0; i<pixelLinesMirror.size(); i++) {
      Line2D currentLine = pixelLinesMirror.get(i);
      float paperX1 = fromPixelToPaperValue(currentLine.a.x, sr)-pW/sr;
      float paperY1 = fromPixelToPaperValue(currentLine.a.y, sr)-pH/sr;  
      float paperX2  = fromPixelToPaperValue(currentLine.b.x, sr)-pW/sr;
      float paperY2  = fromPixelToPaperValue(currentLine.b.y, sr)-pH/sr;
      Line2D linePaper = new Line2D(new Vec2D(paperX1, paperY1), new Vec2D(paperX2, paperY2));
      paperLines.add(linePaper);
    }
  }
}

void keyPressed() {

  if (key == 'm' || key == 'M') {
    showMirror = !showMirror;
  }

  if (key == 'c' || key == 'c') {
    // clear the line buffers, basically erases the canvas
    pixelLines.clear();
    pixelLinesMirror.clear();
  }
  
  if (key == 'z' || key == 'Z') {
    // clear the line buffers, basically erases the canvas
    pixelLines.remove(pixelLines.size() - 1);
        pixelLinesMirror.remove(pixelLinesMirror.size() - 1);

  }

  if (key == 'E' || key == 'e') {

    if ( GCodeExported == false) {
      // export GCODE file
      convertPixelLinesToPaperLines();
      for (int i=0; i<paperLines.size(); i++) {
        // iterate through the saved lines coordinates and write them to the GCode file
        Line2D currentLine = paperLines.get(i);
        if (i == 0) {
          // move from the home/origin to the first point with penUP
          output.println("G0" + " " + "Z" + penUp);
          output.println("G0" + " " + "F" + motorFeedFast);
          output.println("G0" + " " + "X" + currentLine.a.x + " " + "Y" + -(currentLine.a.y));          
          // this is the first line that gets drawn
          output.println("G1" + " " + "Z" + penDown);
          output.println("G0" + " " + "F" + motorFeedSlow);
          isPenDown = true;
          output.println("G1" + " " + "X" + currentLine.a.x + " " + "Y" + -(currentLine.a.y));
          output.println("G1" + " " + "X" + currentLine.b.x + " " + "Y" + -(currentLine.b.y));
          //println(l.a.x + " " +l.a.y);
        }
        else {
          Line2D previousLine = paperLines.get(i-1);
          if (currentLine.a.x == previousLine.b.x && currentLine.a.y == previousLine.b.y) {
            // the two lines share a vertex, so the pen head is not lifetd
            if (isPenDown != true) {
              output.println("G1" + " " + "Z" + penDown);
              isPenDown = true;
            }
            output.println("G1" + " " + "X" + currentLine.a.x + " " + "Y" + -(currentLine.a.y));
            output.println("G1" + " " + "X" + currentLine.b.x + " " + "Y" + -(currentLine.b.y));
            //println("Line " + i + " and line " + (i-1) + " share a vertex");
          }
          else {
            // the two lines DO NOT share a vertex, so the pen head IS RAISED
            // the pen head is quickly moved to the next vertex
            output.println("G0" + " " + "Z" + penUp);
            output.println("G0" + " " + "F" + motorFeedFast);
            output.println("G1" + " " + "X" + currentLine.a.x + " " + "Y" + -(currentLine.a.y));

            // the line is drawn
            output.println("G0" + " " + "Z" + penDown); 
            output.println("G0" + " " + "F" + motorFeedSlow);
            output.println("G1" + " " + "X" + currentLine.a.x + " " + "Y" + -(currentLine.a.y));
            output.println("G1" + " " + "X" + currentLine.b.x + " " + "Y" + -(currentLine.b.y));
          }
        }
      }
      GCodeEnd();
      GCodeExported = true;
    }
    else {
      println("ALREADY EXPORTED TO GCODE...");
    }
  }
}

void GCodeInit() {
  // writes an header with the required setup instructions for the GCode output file
  output.println("( Made with Processing in August 2013, in Puglia far away from the seaside / Paper size: "  + pW + "x" + pH + "mm )");
  // basic configuration =>> G21 (millimiters) G90 (absolute mode) G64 (constant velocity mode) G40 (turn off radius compensation)
  output.println("G21" + " " + "G90" + " " + "G64" + " " + "G40");
  // output.println("( T0 : 0.8 )");
  // T0 => tool select
  // M6 ==> tool change
  // output.println("T0 M6");
  // G17 ==> select the XY plane
  output.println("G17");
  // M3 ==> start spindle clockwise
  // S1000 ==> spindle speed
  // output.println("M3 S1000");
  // F... set stepper motors speed
  // G0 X0.0 Y0.0 => send plotter head to 'home' position 
  // G0 is movement with penup while G1 is movement with pen down -> not so sure about this! #ancheno
  // G0 Z... ==> pen UP
  output.println("G0" + " " + "Z" + penUp);
  output.println("G0" + " " + "F" + motorFeedFast + " " + "X0.0" + " " +  "Y0.0"); 
  output.println(" ");

  // disegna i due assi X,Y
  /*
  output.println("G0" + " " + "Z" + penDown);
   output.println("G0 X-205 Y0");
   output.println("G0 X205 Y0");
   output.println("G0" + " " + "Z" + penUp);
   output.println("G0 X0 Y140");
   output.println("G0" + " " + "Z" + penDown);
   output.println("G0 X0 Y-140");
   output.println("G0" + " " + "Z" + penUp);
   output.println(" ");
   */
}

void GCodeEnd() {
  // writes a footer with the end instructions for the GCode output file
  output.println(" ");
  // G0 Z90.0
  // G0 X0 Y0 => go home
  // M5 => stop spindle
  // M30 => stop execution
  output.println("G0" + " " + "Z" + penUp);
  //output.println("G0 Z90.0");
  output.println("G0 X0 Y0");  
  output.println("M5");
  output.println("M30"); 
  // finalize the GCode text file and quits the current Processing Sketch
  output.flush();  // writes the remaining data to the file
  output.close();  // finishes the output file
  println("***************************");
  println("GCODE EXPORTED SUCCESSFULLY");
  println("***************************");
  //exit();  // quits the Processing sketch
}

String dateNow() {
  // creates a custom string with the full date to be used in the filename
  // this can be improved in the next version of the sketch
  int day = day();
  int mon = month();
  int yea = year();
  int hou = hour();
  int min = minute();
  int sec = second();
  return( "" + yea + mon + day+ "_" + hou + min + sec + "_");
}

