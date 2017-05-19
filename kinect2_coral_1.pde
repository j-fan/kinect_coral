/*
 * particle generated tree algorithm modified from <https://www.openprocessing.org/sketch/144159>
 * fast blur algorithm from Mario Klingemann <http://incubator.quasimondo.com>
 */
import blobDetection.*;
import KinectPV2.*;
import processing.video.*;
import oscP5.*;  
import netP5.*;

KinectPV2 kinect;
Movie movie;
PImage img;
PImage frame;
PGraphics preview;
PGraphics coralLayer;
PGraphics movieLayer;
BlobDetection blobDetect;
ArrayList<Coral> reef;
ArrayList<BlobTrack> blobDetails;
color[] palette;
int numColours = 5;
int minDepth = 300;
int maxDepth = 1500;
int delay=0;
float diameter = 600.0;
boolean fadeout = false;
int fadeTime = 0;
OscP5 oscP5;
NetAddress myRemoteLocation;



void setup() {
  size(1024, 1024);
  //graphics startup //
  background(255);
  coralLayer = createGraphics(width, height);
  ellipseMode(CENTER);
  smooth();
  generate();
  createPalette();

  // kinect start up //
  /*
  kinect = new KinectPV2(this);
   kinect.enableDepthImg(true);
   kinect.init();
   
   // blob detection start up //
   img = new PImage(width/10, height/10);
   preview = createGraphics(width, height);
   blobDetails = new ArrayList<BlobTrack>();
   blobDetect = new BlobDetection(width/10, height/10);
   blobDetect.setThreshold(0.2f);
   */

  //movie startup //
  movie = new Movie(this, "coral.mp4");
  movie.loop();
  movieLayer = createGraphics(width, height);
  create_frame(); //makes a soft frame to darken edges

  //start up OSC //
  oscP5 = new OscP5(this, 12000);   //listening on
  myRemoteLocation = new NetAddress("127.0.0.1", 57120);  //speaking t
}

void draw() {
  //copy kinect depth map and do blob detection on it
  /*rawDepthToImg();
   fastblur(img, 3);
   blobDetect.computeBlobs(img.pixels);
   
   //do blob tracking
   updateBlobDetails();
   blobAging();
   
   //store computer vision image
   preview.beginDraw();
   preview.image(img, 0, 0, width, height);
   identifyBlob();
   drawBlobsAndEdges(true, true);
   preview.endDraw();
   */

  coralLayer.beginDraw();
  //draw corals
  if (!fadeout) {
    addCoral();
    ageCoral();
    showCoral();
  }
  //draw the circle
  coralLayer.stroke(255);
  coralLayer.strokeWeight(2);
  coralLayer.noFill();
  coralLayer.ellipse(width/2, height/2, diameter, diameter);
  coralLayer.endDraw();

  //render the movie

  renderMovie();

  //render the coral Layer
  image(coralLayer, 0, 0, width, height);

  //trigger fade to clear canvas every so often
  fade();

  //send OSC to maxmsp
  sendOSC();

  //render the kinect CV preview
  //image(preview, 0, 0, width/4, height/4);
}

void createPalette() {
  palette = new color[]{ color(#d408be), color(#d46168), color(#f1523a), 
    color(#f68800), color(#f4d64b)};
}

color chooseColour() {
  return palette[(int)random(0, palette.length-1)];
}

void sendOSC() {
  OscMessage newMessage = new OscMessage("number of blobs in circle");
  //newMessage.add(blobDetails.size());
  oscP5.send(newMessage, myRemoteLocation);
}

void renderMovie() {
  movieLayer.beginDraw();
  movieLayer.tint(255, 100);
  movieLayer.image(movie, -width/2, 0, width*2, height);
  //filter(GRAY);
  movieLayer.fill(color(#001d62), 20);
  movieLayer.noStroke();
  movieLayer.rect(0, 0, width, height); 
  movieLayer.blend(frame, 0, 0, width, height, 0, 0, width, height, HARD_LIGHT);
  movieLayer.endDraw();
  image(movieLayer, 0, 0, width, height);
}

void movieEvent(Movie m) {
  m.read();
}

void fade() {
  int maxTime = 100;
  if (frameCount%500==0) {
    println("FADEOUT START");
    fadeout = true;
    reef = new ArrayList<Coral>();
  } 
  if (fadeTime >maxTime) {
    fadeout = false;
    fadeTime = 0;
  }
  if (fadeout) {
    fadeTime++;

    if (fadeTime==maxTime/2) {
      coralLayer.clear();
    }

    float alpha = 0.0;
    if (fadeTime> (maxTime/2)) {
      alpha =  255.0 - (((float)fadeTime - ((float)maxTime/2)) / ((float)maxTime/2) * 255.0);
    } else {
      alpha = (float)fadeTime / ((float)maxTime/2) * 255.0;
    }
    fill(0, alpha);
    rect(0, 0, width, height);
  }
}


void generate() {
  reef = new ArrayList<Coral>();
  /*for (int i =0; i<1; i++) {
   reef.add(new Coral(random(width),random(height)));
   }*/
}
void addCoral() {
  delay++;
  if (delay==1) {
    delay = 0;
    /*for (int i=0;i<blobDetails.size();i++){
     BlobTrack bt = blobDetails.get(i);
     //add new coral only if it's on the circle
     float distance = dist(bt.x,bt.y,width/2,height/2); 
     float radius = diameter/2;
     if(abs(distance-radius)<40){
     reef.add(new Coral(bt.x,bt.y,chooseColour()));
     }
     }*/
    float randX = random(width);
    float randY = random(height);
    float distance = dist(randX, randY, width/2, height/2); 
    float radius = diameter/2;
    if (abs(distance-radius)<40) {
      reef.add(new Coral(randX, randY, chooseColour()));
    }
  }
}

void ageCoral() {
  ArrayList<Coral> dead = new ArrayList<Coral>();
  for (Coral c : reef) {
    if (c.life==0) {
      dead.add(c);
    }
  }
  for (Coral c : dead) {
    reef.remove(c);
  }
}

void showCoral() {
  noStroke();
  for (Coral coral : reef) {
    coral.show();
  }
}
void rawDepthToImg() {
  int [] rawData = kinect.getRawDepthData();

  for (int i = 0; i < KinectPV2.WIDTHDepth; i++) {
    for (int j = 0; j < KinectPV2.HEIGHTDepth; j++) {
      int index = i + j * KinectPV2.WIDTHDepth;
      int depth = rawData[index];
      color c;
      if (depth<minDepth || depth>maxDepth) {
        c = color(0);
      } else {
        c = color(map(depth, 0, 4500, 255, 0));
      }
      int canvasX = (int)map(i, 0, KinectPV2.WIDTHDepth, 0, img.width);
      int canvasY = (int)map(j, 0, KinectPV2.HEIGHTDepth, 0, img.height);
      int canvasIndex = canvasX + canvasY * img.width;
      img.pixels[canvasIndex] = c;
    }
  }
  img.updatePixels();
}
void drawBlobsAndEdges(boolean drawBlobs, boolean drawEdges)
{
  preview.noFill();
  preview.colorMode(RGB, 255);
  Blob b;
  EdgeVertex eA, eB;
  for (int n=0; n<blobDetect.getBlobNb(); n++) {
    b=blobDetect.getBlob(n);
    if (b!=null) {
      // Edges
      if (drawEdges) {
        preview.strokeWeight(3);
        preview.stroke(0, 255, 0);
        for (int m=0; m<b.getEdgeNb(); m++) {
          eA = b.getEdgeVertexA(m);
          eB = b.getEdgeVertexB(m);
          if (eA !=null && eB !=null) {
            preview.stroke(0, 0, 255);
            preview.line(
              eA.x*width, eA.y*height, 
              eB.x*width, eB.y*height
              );
          }
        }
      }

      // Blobs
      if (drawBlobs) {
        preview.strokeWeight(3);
        preview.stroke(255, 0, 0);
        preview.rect(
          b.xMin*width, b.yMin*height, 
          b.w*width, b.h*height
          );
      }
    }
  }
}
void fastblur(PImage img, int radius)
{
  if (radius<1) {
    return;
  }
  int w=img.width;
  int h=img.height;
  int wm=w-1;
  int hm=h-1;
  int wh=w*h;
  int div=radius+radius+1;
  int r[]=new int[wh];
  int g[]=new int[wh];
  int b[]=new int[wh];
  int rsum, gsum, bsum, x, y, i, p, p1, p2, yp, yi, yw;
  int vmin[] = new int[max(w, h)];
  int vmax[] = new int[max(w, h)];
  int[] pix=img.pixels;
  int dv[]=new int[256*div];
  for (i=0; i<256*div; i++) {
    dv[i]=(i/div);
  }

  yw=yi=0;

  for (y=0; y<h; y++) {
    rsum=gsum=bsum=0;
    for (i=-radius; i<=radius; i++) {
      p=pix[yi+min(wm, max(i, 0))];
      rsum+=(p & 0xff0000)>>16;
      gsum+=(p & 0x00ff00)>>8;
      bsum+= p & 0x0000ff;
    }
    for (x=0; x<w; x++) {

      r[yi]=dv[rsum];
      g[yi]=dv[gsum];
      b[yi]=dv[bsum];

      if (y==0) {
        vmin[x]=min(x+radius+1, wm);
        vmax[x]=max(x-radius, 0);
      }
      p1=pix[yw+vmin[x]];
      p2=pix[yw+vmax[x]];

      rsum+=((p1 & 0xff0000)-(p2 & 0xff0000))>>16;
      gsum+=((p1 & 0x00ff00)-(p2 & 0x00ff00))>>8;
      bsum+= (p1 & 0x0000ff)-(p2 & 0x0000ff);
      yi++;
    }
    yw+=w;
  }

  for (x=0; x<w; x++) {
    rsum=gsum=bsum=0;
    yp=-radius*w;
    for (i=-radius; i<=radius; i++) {
      yi=max(0, yp)+x;
      rsum+=r[yi];
      gsum+=g[yi];
      bsum+=b[yi];
      yp+=w;
    }
    yi=x;
    for (y=0; y<h; y++) {
      pix[yi]=0xff000000 | (dv[rsum]<<16) | (dv[gsum]<<8) | dv[bsum];
      if (x==0) {
        vmin[y]=min(y+radius+1, hm)*w;
        vmax[y]=max(y-radius, 0)*w;
      }
      p1=x+vmin[y];
      p2=x+vmax[y];

      rsum+=r[p1]-r[p2];
      gsum+=g[p1]-g[p2];
      bsum+=b[p1]-b[p2];

      yi+=w;
    }
  }
}
void showIR() {
  //obtain the depth frame, 8 bit gray scale format
  image(kinect.getDepthImage(), 0, 0);

  //obtain the depth frame as strips of 256 gray scale values
  image(kinect.getDepth256Image(), 512, 0);

  //infrared data
  image(kinect.getInfraredImage(), 0, 424);
  image(kinect.getInfraredLongExposureImage(), 512, 424);
}

void create_frame() {
  frame = createImage(width, height, ARGB);
  float max = dist(0, 0, frame.width/2, frame.height/2);
  for (int x = 0; x<frame.width; x++) {
    for (int y = 0; y<frame.height; y++) {
      float distance = dist(x, y, frame.width/2, frame.height/2);
      distance = map(distance, 0, max, 0, 100);
      int index = x + width * y;
      frame.pixels[index] = color(0, 0, 0, distance);
    }
  }
}