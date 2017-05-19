class pathfinder {
  PVector location;
  PVector velocity;
  float diameter;
  float incr = 0.001;
  float angle = 0.0;

  pathfinder(float xroot, float yroot) {
    location = new PVector(xroot, yroot);
    velocity = PVector.fromAngle(random(1)*2*PI);
    diameter = 5;
  }
  pathfinder(pathfinder parent) {
    location = parent.location.get();
    velocity = parent.velocity.get();//.add(PVector.fromAngle(random(-0.001, 0.001)*2*PI));
    float area = PI*sq(parent.diameter*0.75);
    float newDiam = sqrt(area/2/PI)*2;
    diameter = newDiam;
    parent.diameter = newDiam;
  }
  void update() {
    if (diameter>0.5) {
      location.add(velocity);
      PVector bump = new PVector(random(-1, 1), random(-1, 1));
      if (diameter>25) {
        bump = new PVector(random(-0.5, 0.5), random(-1, 0));
      }
      bump.mult(0.2);
      velocity.add(bump);
      velocity.normalize();

    }
  }
}