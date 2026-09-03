ArrayList<Shape> freeShapes;
ArrayList<Hub> hubs;
ArrayList<Particle> particles;

Object draggedEntity = null; // Puede ser un Shape o un Hub
float globalGlow = 0.0f;     // Brillo del fondo por los mandalas en equilibrio

int colTriangle;
int colSquare;
int colCircleActive;

void setup() {
  size(900, 700);
  smooth(8);
  rectMode(CENTER);
  
  freeShapes = new ArrayList<Shape>();
  hubs = new ArrayList<Hub>();
  particles = new ArrayList<Particle>();
  
  colTriangle = color(255, 183, 178);     // Rosa pastel
  colSquare = color(199, 206, 234);       // Azul pastel
  colCircleActive = color(175, 228, 222); // Cian/Verde pastel (El Núcleo)
  
  // Instanciar figuras sueltas
  for (int i = 0; i < 10; i++) {
    freeShapes.add(new Shape(0, random(100, width-100), random(100, height-100)));
    freeShapes.add(new Shape(1, random(100, width-100), random(100, height-100)));
  }
}

void draw() {
  int bgBase = color(5, 4, 9);
  int bgResonant = color(22, 15, 38);
  
  float targetGlow = 0;
  for (Hub h : hubs) if (h.isBalanced) targetGlow += 0.5f;
  globalGlow = lerp(globalGlow, min(1.0f, targetGlow), 0.05f);
  
  background(lerpColor(bgBase, bgResonant, globalGlow));
  
  // 1. Dibujar y actualizar los Núcleos (Mandalas)
  for (int i = hubs.size() - 1; i >= 0; i--) {
    Hub h = hubs.get(i);
    h.update();
    h.display();
    
    if (h.members.size() < 2) {
      for (Shape s : h.members) {
        s.pos = s.orbitPos.copy();
        freeShapes.add(s);
      }
      createExplosion(h.pos.x, h.pos.y, colCircleActive, 30);
      hubs.remove(i);
    }
  }
  
  // 2. Dibujar figuras sueltas
  for (Shape s : freeShapes) {
    s.updatePhysics();
    s.display();
  }
  
  // 3. Línea predictiva al acercar a un núcleo
  if (draggedEntity instanceof Shape) {
    Shape s = (Shape) draggedEntity;
    for (Hub h : hubs) {
      if (dist(s.pos.x, s.pos.y, h.pos.x, h.pos.y) < h.radius + 40) {
        stroke(255, 150);
        strokeWeight(2);
        line(s.pos.x, s.pos.y, h.pos.x, h.pos.y);
      }
    }
  }
  
  // Partículas
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.display();
    if (p.alpha <= 0) particles.remove(i);
  }
}

// ==========================================
// INTERACCIONES (Mouse)
// ==========================================
void mousePressed() {
  float minDist = 35.0f;
  
  for (Hub h : hubs) {
    if (dist(mouseX, mouseY, h.pos.x, h.pos.y) < 40) {
      draggedEntity = h;
      return;
    }
  }
  
  for (Hub h : hubs) {
    for (int i = 0; i < h.members.size(); i++) {
      Shape s = h.members.get(i);
      if (dist(mouseX, mouseY, s.orbitPos.x, s.orbitPos.y) < minDist) {
        h.members.remove(i);
        s.pos = s.orbitPos.copy();
        freeShapes.add(s);
        draggedEntity = s;
        createExplosion(s.pos.x, s.pos.y, 255, 10);
        return;
      }
    }
  }
  
  for (Shape s : freeShapes) {
    if (dist(mouseX, mouseY, s.pos.x, s.pos.y) < minDist) {
      minDist = dist(mouseX, mouseY, s.pos.x, s.pos.y);
      draggedEntity = s;
    }
  }
}

void mouseReleased() {
  if (draggedEntity != null) {
    if (draggedEntity instanceof Shape) {
      Shape draggedShape = (Shape) draggedEntity;
      boolean attached = false;
      
      for (Hub h : hubs) {
        if (dist(draggedShape.pos.x, draggedShape.pos.y, h.pos.x, h.pos.y) < h.radius + 40) {
          freeShapes.remove(draggedShape);
          h.members.add(draggedShape);
          createExplosion(draggedShape.pos.x, draggedShape.pos.y, draggedShape.baseColor, 15);
          attached = true;
          break;
        }
      }
      
      if (!attached) {
        for (Shape other : freeShapes) {
          if (other != draggedShape) {
            if (dist(draggedShape.pos.x, draggedShape.pos.y, other.pos.x, other.pos.y) < 60) {
              // CORREGIDO: Uso correcto de PVector.lerp con objetos PVector
              PVector mid = PVector.lerp(draggedShape.pos, other.pos, 0.5f);
              Hub newHub = new Hub(mid.x, mid.y);
              freeShapes.remove(draggedShape);
              freeShapes.remove(other);
              newHub.members.add(draggedShape);
              newHub.members.add(other);
              hubs.add(newHub);
              createExplosion(mid.x, mid.y, colCircleActive, 30);
              break;
            }
          }
        }
      }
    } else if (draggedEntity instanceof Hub) {
      Hub draggedHub = (Hub) draggedEntity;
      for (int i = hubs.size() - 1; i >= 0; i--) {
        Hub otherHub = hubs.get(i);
        if (otherHub != draggedHub && dist(draggedHub.pos.x, draggedHub.pos.y, otherHub.pos.x, otherHub.pos.y) < draggedHub.radius + otherHub.radius) {
          otherHub.members.addAll(draggedHub.members);
          hubs.remove(draggedHub);
          createExplosion(otherHub.pos.x, otherHub.pos.y, colCircleActive, 50);
          break;
        }
      }
    }
    draggedEntity = null;
  }
}

void createExplosion(float x, float y, int c, int count) {
  for (int i = 0; i < count; i++) {
    particles.add(new Particle(x, y, c));
  }
}

// ==========================================
// CLASES COMPLEMENTARIAS
// ==========================================

class Hub {
  PVector pos;
  ArrayList<Shape> members;
  
  float angle = 0;
  float radius = 50;
  float rotationSpeed = 0.015f;
  
  boolean isBalanced = false;
  float balancePulse = 0;
  
  Hub(float x, float y) {
    pos = new PVector(x, y);
    members = new ArrayList<Shape>();
  }
  
  void update() {
    if (draggedEntity == this) {
      pos.x = mouseX;
      pos.y = mouseY;
    } else {
      pos.y += sin(frameCount * 0.02f + pos.x) * 0.2f;
    }
    
    int countTri = 0;
    int countSq = 0;
    for (Shape s : members) {
      if (s.type == 0) countTri++;
      else countSq++;
    }
    
    float targetRadius = 50 + (members.size() * 12);
    radius = lerp(radius, targetRadius, 0.05f);
    
    isBalanced = (countTri == countSq && countTri > 0);
    
    if (isBalanced) {
      rotationSpeed = lerp(rotationSpeed, 0.008f, 0.05f);
      balancePulse = lerp(balancePulse, 1.0f, 0.05f);
      if (frameCount % 10 == 0) createExplosion(pos.x, pos.y, colCircleActive, 1);
    } else {
      float imbalance = (countTri - countSq) * 0.01f; 
      rotationSpeed = lerp(rotationSpeed, 0.015f + imbalance, 0.1f);
      balancePulse = lerp(balancePulse, 0.0f, 0.1f);
    }
    
    angle += rotationSpeed;
    
    for (int i = 0; i < members.size(); i++) {
      Shape s = members.get(i);
      float targetAngle = angle + (i * TWO_PI / members.size());
      
      float tx = pos.x + cos(targetAngle) * radius;
      float ty = pos.y + sin(targetAngle) * radius;
      
      if (s.orbitPos == null) s.orbitPos = new PVector(tx, ty);
      
      s.orbitPos.x = lerp(s.orbitPos.x, tx, 0.1f);
      s.orbitPos.y = lerp(s.orbitPos.y, ty, 0.1f);
      
      s.angle += (s.type == 0) ? 0.03f : 0.01f;
    }
  }
  
  void display() {
    for (Shape s : members) {
      strokeWeight(isBalanced ? 3 : 1.5f);
      stroke(255, isBalanced ? 200 : 80);
      line(pos.x, pos.y, s.orbitPos.x, s.orbitPos.y);
    }
    
    if (isBalanced) {
      noFill();
      stroke(colCircleActive, 150 * (1.0f - (frameCount % 90)/90.0f));
      strokeWeight(2);
      float ringSize = radius * 2.5f * ((frameCount % 90)/90.0f);
      ellipse(pos.x, pos.y, ringSize, ringSize);
    }
    
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(-angle);
    
    float coreSize = 35 + (balancePulse * 15);
    fill(colCircleActive, 50 + 100 * balancePulse);
    stroke(colCircleActive, 200 + 55 * balancePulse);
    strokeWeight(3 + 2 * balancePulse);
    ellipse(0, 0, coreSize, coreSize);
    
    fill(255, 150 + 100 * balancePulse);
    noStroke();
    ellipse(0, 0, coreSize * 0.4f, coreSize * 0.4f);
    popMatrix();
    
    for (Shape s : members) {
      s.displayAt(s.orbitPos.x, s.orbitPos.y);
    }
  }
}

class Shape {
  int type; 
  PVector pos;
  PVector orbitPos; 
  PVector vel;
  float angle;
  int baseColor;
  
  Shape(int t, float x, float y) {
    this.type = t;
    this.pos = new PVector(x, y);
    this.vel = PVector.random2D().mult(random(0.3f, 0.8f));
    this.angle = random(TWO_PI);
    this.baseColor = (type == 0) ? colTriangle : colSquare;
  }
  
  void updatePhysics() {
    if (draggedEntity == this) {
      pos.x = mouseX;
      pos.y = mouseY;
      vel.set(0, 0);
    } else {
      pos.add(vel);
      if (pos.x < 30 || pos.x > width - 30) vel.x *= -1;
      if (pos.y < 30 || pos.y > height - 30) vel.y *= -1;
      pos.x = constrain(pos.x, 30, width - 30);
      pos.y = constrain(pos.y, 30, height - 30);
      angle += 0.01f;
    }
  }
  
  void display() {
    displayAt(pos.x, pos.y);
  }
  
  void displayAt(float dx, float dy) {
    pushMatrix();
    translate(dx, dy);
    rotate(angle);
    
    stroke(baseColor, 180);
    strokeWeight(2);
    
    if (orbitPos != null && orbitPos.x == dx) fill(baseColor, 40);
    else noFill();
    
    if (type == 0) {
      float r = 18.0f;
      beginShape();
      for (int i = 0; i < 3; i++) {
        float a = i * TWO_PI / 3.0f - HALF_PI;
        vertex(cos(a) * r, sin(a) * r);
      }
      endShape(CLOSE);
    } else if (type == 1) {
      rect(0, 0, 28, 28);
    }
    popMatrix();
  }
}

class Particle {
  float x, y, vx, vy, size, alpha;
  int col;
  
  Particle(float nx, float ny, int c) {
    x = nx; y = ny;
    vx = random(-3, 3); vy = random(-3, 3);
    size = random(3.0f, 7.0f);
    alpha = 255; col = c;
  }
  
  void update() {
    x += vx; y += vy;
    alpha -= 5.0f; 
  }
  
  void display() {
    noStroke();
    fill(col, alpha);
    ellipse(x, y, size, size);
  }
}
