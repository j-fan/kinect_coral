class Coral {
  pathfinder[] paths;
  int life=0;
  color coralColour;
  Coral(float rX,float rY, color c) {
    colorMode(RGB, 255);
    //fill(0,30);
    //rect(0, 0, width, height);
    int num = 15;
    paths = new pathfinder[num];
    float rootX = rX;
    float rootY = rY;
    for (int i=0; i<num; i++) {
      paths[i] = new pathfinder(rootX, rootY);
    }
    life = (int)random(2000,4000);
    colorMode(HSB, 255);
    coralColour = c;
  }
  void show() {
    coralLayer.colorMode(HSB, 255);
    if (life>0) {
      for (int i=0; i<paths.length; i++) {
        PVector loc = paths[i].location;
        float diam = paths[i].diameter;
        coralLayer.noStroke();
        coralLayer.fill(coralColour,40);
        coralLayer.ellipse(loc.x, loc.y, diam, diam);
        paths[i].update();
        float rng = random(10);
        if (rng<0.2) {
          paths = (pathfinder[]) append(paths, new pathfinder(paths[i]));
        }
        life --;
      }
    }
  }
}