/*
 * Blob tracking object
 */
class BlobTrack{
   float x;
   float y;
   float density;
   int isSameDist = 100;
   int life;
   BlobTrack(float x,float y){
       this.x = x;
       this.y =y;
       this.density = 0;
       life =2;
   }
   //Do some blob tracking
   boolean isSame(BlobTrack b){
     return (abs(b.x-x) < isSameDist && abs(b.y-y) < isSameDist);
   }
}

void updateBlobDetails() {
  for (int n=0; n<blobDetect.getBlobNb(); n++) {
    Blob b=blobDetect.getBlob(n);
    int curX = floor(b.xMin*width + b.w*width / 2);
    int curY = floor(b.yMin*height + b.h*height / 2);
    addNewBlobDetails(curX, curY);
  }
}

/*
 * perform blob recognition & tracking
 */
void addNewBlobDetails(float newX, float newY) {
  BlobTrack newB = new BlobTrack(newX, newY);
  ArrayList<BlobTrack> similar = new ArrayList<BlobTrack>();
  boolean replaced = false;
  int i=0;
  int replaceI = 0;
  for (i =0; i <blobDetails.size(); i++) {
    BlobTrack bo = blobDetails.get(i);
    bo.density = 0;
    if (bo.isSame(newB)) {
      replaced = true;
      replaceI = i;
      similar.add(bo);
    }
  }
  if (replaced == true) {
    blobDetails.add(replaceI, newB);
    for(i=1; i<similar.size();i++){
      blobDetails.remove(similar.get(i));
    }
  } else {
    blobDetails.add(newB);
  }
}
/*
 * Reduce the lifespan of blobs so that ones that don't exist anymore can be killed off
 */
void blobAging() {
  ArrayList<BlobTrack> toKill = new ArrayList<BlobTrack>();
  for (int i =0; i <blobDetails.size(); i++) {
    BlobTrack bo = blobDetails.get(i);
    bo.life --;
    if (bo.life <= 0) {
      toKill.add(bo);
    }
  }
  // kill off blobs that haven't been matched in a while
  for (BlobTrack dead : toKill) {
    blobDetails.remove(dead);
  }
}

void identifyBlob() {
  for (int i =0; i <blobDetails.size(); i++) {
    preview.textSize(56);
    BlobTrack bo = blobDetails.get(i);
    preview.fill(255, 0, 0);
    preview.text(i, bo.x, bo.y);
  }
}