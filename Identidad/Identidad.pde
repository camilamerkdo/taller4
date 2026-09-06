// ==========================================
// IDENTIDAD: Reafirmación (Mayoría >= 3, Brillo al Reafirmar, Sin Texto)
// ==========================================

ArrayList<ExternalShape> externalShapes;
ExternalShape draggedShape = null;

int currentIdentity = 0;     // 0 = Triángulo, 1 = Cuadrado, 2 = Círculo
boolean isMasked = false;    
int maskTimer = 0;           
int maskDuration = 5000;     

int cooldownTimer = 0;       
int cooldownDuration = 1500; 

float pulseScale = 1.0f;     
float reaffirmGlow = 0.0f;   // Brillo que destella al reafirmarse

int colTriangle;
int colSquare;
int colCircle;

float cx, cy;
float R = 75.0f; 
float influenceRadius = 180.0f;

void setup() {
  size(900, 700);
  smooth(8);
  rectMode(CENTER);
  
  cx = width / 2;
  cy = height / 2;
  
  colTriangle = color(4, 139, 133);   // Teal Oscuro / Esmeralda
  colSquare = color(0, 245, 212);     // Menta Brillante / Cian Vivo
  colCircle = color(72, 202, 228);    // Cian Suave
  
  externalShapes = new ArrayList<ExternalShape>();
  
  for (int i = 0; i < 3; i++) {
    externalShapes.add(new ExternalShape(1, random(100, width-100), random(50, 150)));
    externalShapes.add(new ExternalShape(2, random(100, width-100), random(height-150, height-50)));
  }
}

void draw() {
  reaffirmGlow = lerp(reaffirmGlow, 0.0f, 0.04f); // El brillo del fondo se desvanece suavemente
  
  int bgBase = color(4, 15, 22);
  int bgReaffirm = color(15, 60, 70); 
  
  background(lerpColor(bgBase, bgReaffirm, reaffirmGlow));
  
  // 1. DIBUJAR ZONA DE INFLUENCIA
  stroke(0, 255, 255);
  strokeWeight(0.2);
  noFill(); 
  ellipse(cx, cy, influenceRadius * 2, influenceRadius * 2);

  
  // 2. ANALIZAR LA PRESIÓN EXTERNA
  int countSq = 0;
  int countCir = 0;
  
  for (ExternalShape s : externalShapes) {
    if (dist(s.pos.x, s.pos.y, cx, cy) < influenceRadius) {
      if (s.type == 1) countSq++;
      else if (s.type == 2) countCir++;
    }
  }
  
  int totalInside = countSq + countCir;
  
  // 3. LÓGICA DE CAMBIO POR MAYORÍA (Requiere al menos más de 2 figuras, es decir, >= 3)
  if (!isMasked) {
    if (millis() - cooldownTimer > cooldownDuration) {
      if (totalInside >= 3) {
        if (countSq > countCir) {
          currentIdentity = 1; 
          isMasked = true;
          maskTimer = millis();
          pulseScale = 1.4f; 
        } 
        else if (countCir > countSq) {
          currentIdentity = 2; 
          isMasked = true;
          maskTimer = millis();
          pulseScale = 1.4f;
        }
      }
    }
  } 
  else {
    if (millis() - maskTimer >= maskDuration) {
      // ¡REAFIRMACIÓN! Vuelve a ser triángulo
      currentIdentity = 0; 
      isMasked = false;
      pulseScale = 1.8f; 
      reaffirmGlow = 1.0f; // El fondo brilla únicamente cuando el triángulo se reafirma
      
      cooldownTimer = millis(); 
      
      for (ExternalShape s : externalShapes) {
        float d = dist(s.pos.x, s.pos.y, cx, cy);
        if (d < influenceRadius + 50) {
          PVector push = PVector.sub(s.pos, new PVector(cx, cy));
          if (push.mag() == 0) push = PVector.random2D(); 
          push.normalize();
          push.mult(28.0f); 
          s.vel.add(push);
        }
      }
    }
  }
  
  pulseScale = lerp(pulseScale, 1.0f, 0.1f);
  
  // 4. DIBUJAR LA IDENTIDAD CENTRAL
  pushMatrix();
  translate(cx, cy);
  scale(pulseScale);
  
  int currentColor = (currentIdentity == 1) ? colSquare : (currentIdentity == 2) ? colCircle : colTriangle;
  
  noStroke();
  fill(currentColor);
  
  if (currentIdentity == 0) {
    beginShape();
    vertex(0, -R);
    vertex(R * 0.866f, R * 0.5f);
    vertex(-R * 0.866f, R * 0.5f);
    endShape(CLOSE);
  } 
  else if (currentIdentity == 1) {
    rect(0, 0, R * 1.7f, R * 1.7f);
  } 
  else if (currentIdentity == 2) {
    ellipse(0, 0, R * 1.9f, R * 1.9f);
  }
  
  float innerPulse = 1.0f + 0.15f * sin(frameCount * 0.1f);
  scale(0.25f * innerPulse);
  fill(255, 200);
  beginShape();
  vertex(0, -R); 
  vertex(R * 0.866f, R * 0.5f);
  vertex(-R * 0.866f, R * 0.5f);
  endShape(CLOSE);
  
  popMatrix();
  
  // 5. ACTUALIZAR Y DIBUJAR FIGURAS EXTERNAS
  for (ExternalShape s : externalShapes) {
    s.update();
    s.display();
  }
}

// ==========================================
// INTERACCIONES MOUSE
// ==========================================
void mousePressed() {
  float minDist = 35.0f;
  for (ExternalShape s : externalShapes) {
    if (dist(mouseX, mouseY, s.pos.x, s.pos.y) < minDist) {
      minDist = dist(mouseX, mouseY, s.pos.x, s.pos.y);
      draggedShape = s;
    }
  }
  if (draggedShape != null) draggedShape.isDragging = true;
}

void mouseReleased() {
  if (draggedShape != null) {
    draggedShape.isDragging = false;
    draggedShape = null;
  }
}

// ==========================================
// CLASES COMPLEMENTARIAS
// ==========================================
class ExternalShape {
  PVector pos, vel;
  int type; 
  float size = 28.0f;
  float angle = 0;
  boolean isDragging = false;
  
  ExternalShape(int t, float x, float y) {
    this.type = t;
    this.pos = new PVector(x, y);
    this.vel = PVector.random2D().mult(random(0.5f, 1.5f));
  }
  
  void update() {
    if (isDragging) {
      pos.x = mouseX;
      pos.y = mouseY;
      vel.set(0, 0);
    } else {
      pos.add(vel);
      vel.mult(0.92f); 
      
      if (vel.mag() < 0.5f) vel.add(PVector.random2D().mult(0.2f));
      
      if (pos.x < 30) { pos.x = 30; vel.x *= -1; }
      if (pos.x > width - 30) { pos.x = width - 30; vel.x *= -1; }
      if (pos.y < 30) { pos.y = 30; vel.y *= -1; }
      if (pos.y > height - 30) { pos.y = height - 30; vel.y *= -1; }
      
      float d = dist(pos.x, pos.y, cx, cy);
      if (d > influenceRadius && d < influenceRadius + 25) {
        PVector repel = PVector.sub(pos, new PVector(cx, cy));
        repel.normalize();
        vel.add(repel.mult(1.5f)); 
      }
    }
    
    angle += (type == 1) ? 0.02f : 0.01f;
  }
  
  void display() {
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(angle);
    
    int c = (type == 1) ? colSquare : colCircle;
    
    noStroke();
    fill(c);
    
    if (type == 1) rect(0, 0, size, size);
    else ellipse(0, 0, size * 1.15f, size * 1.15f);
    
    popMatrix();
  }
}
