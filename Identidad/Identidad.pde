// ==========================================
// IDENTIDAD: Reafirmación (Cambio Directo y Área Suave)
// ==========================================

ArrayList<ExternalShape> externalShapes;
ArrayList<Particle> particles;
ExternalShape draggedShape = null;

// Lógica de Identidad
int currentIdentity = 0;     // 0 = Triángulo, 1 = Cuadrado, 2 = Círculo
boolean isMasked = false;    
int maskTimer = 0;           // Temporizador de 5 segundos
int maskDuration = 5000;     

// Sistema de inmunidad para evitar el bug de re-transformación
int cooldownTimer = 0;       
int cooldownDuration = 1500; // 1.5 segundos de inmunidad tras estallar

float pulseScale = 1.0f;     // Escala para el latido

// Colores
int colTriangle;
int colSquare;
int colCircle;

// Centro de la pantalla
float cx, cy;
float R = 75.0f; 
float influenceRadius = 180.0f;

void setup() {
  size(900, 700);
  smooth(8);
  rectMode(CENTER);
  
  cx = width / 2;
  cy = height / 2;
  
  colTriangle = color(255, 183, 178); 
  colSquare = color(199, 206, 234);   
  colCircle = color(175, 228, 222);   
  
  externalShapes = new ArrayList<ExternalShape>();
  particles = new ArrayList<Particle>();
  
  // Crear 12 cuadrados y 12 círculos flotando fuera
  for (int i = 0; i < 12; i++) {
    externalShapes.add(new ExternalShape(1, random(20, width-20), random(20, 100)));
    externalShapes.add(new ExternalShape(2, random(20, width-20), random(height-100, height-20)));
  }
}

void draw() {
  int bgBase = color(5, 4, 9);
  int bgMasked = color(20, 25, 40); 
  
  background(lerpColor(bgBase, bgMasked, isMasked ? 1.0f : 0.0f));
  
  // 1. DIBUJAR ZONA DE INFLUENCIA (Relleno suave)
  noStroke();
  int zoneColor = isMasked ? color(255, 150, 150) : color(255, 255, 255);
  fill(zoneColor, 25); // Un fill con mucha transparencia (suave)
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
  
  // 3. LÓGICA DE CAMBIO DIRECTO Y REAFIRMACIÓN
  if (!isMasked) {
    // Solo puede cambiar si no está en tiempo de inmunidad
    if (millis() - cooldownTimer > cooldownDuration) {
      if (countSq >= 4) {
        currentIdentity = 1; // Se vuelve Cuadrado
        isMasked = true;
        maskTimer = millis();
        pulseScale = 1.4f; 
        createExplosion(cx, cy, colSquare, 40);
      } 
      else if (countCir >= 4) {
        currentIdentity = 2; // Se vuelve Círculo
        isMasked = true;
        maskTimer = millis();
        pulseScale = 1.4f;
        createExplosion(cx, cy, colCircle, 40);
      }
    }
  } 
  else {
    // Si tiene identidad falsa, cuenta 5 segundos
    if (millis() - maskTimer >= maskDuration) {
      // ¡REAFIRMACIÓN! Vuelve a ser triángulo
      currentIdentity = 0; 
      isMasked = false;
      pulseScale = 1.8f; 
      
      // Activar inmunidad para evitar bugs
      cooldownTimer = millis(); 
      
      createExplosion(cx, cy, colTriangle, 80);
      
      // Expulsar violentamente a las figuras
      for (ExternalShape s : externalShapes) {
        float d = dist(s.pos.x, s.pos.y, cx, cy);
        if (d < influenceRadius + 50) {
          PVector push = PVector.sub(s.pos, new PVector(cx, cy));
          if (push.mag() == 0) push = PVector.random2D(); // Por si está justo en el centro
          push.normalize();
          push.mult(28.0f); // Fuerza de expulsión masiva
          s.vel.add(push);
        }
      }
    }
  }
  
  // Suavizar el latido (vuelve a escala 1.0)
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
  
  // Detalle Poético: El "corazón" interno triangular
  float innerPulse = 1.0f + 0.15f * sin(frameCount * 0.1f);
  scale(0.25f * innerPulse);
  fill(255, 200);
  beginShape();
  vertex(0, -R); 
  vertex(R * 0.866f, R * 0.5f);
  vertex(-R * 0.866f, R * 0.5f);
  endShape(CLOSE);
  
  popMatrix();
  
  
  // 6. ACTUALIZAR Y DIBUJAR FIGURAS EXTERNAS
  for (ExternalShape s : externalShapes) {
    s.update();
    s.display();
  }
  
}

// ==========================================
// INTERACCIONES MOUSE
// ==========================================
void mousePressed() {
  float minDist = 30.0f;
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

void createExplosion(float x, float y, int c, int count) {
  for (int i = 0; i < count; i++) particles.add(new Particle(x, y, c));
}

// ==========================================
// CLASES COMPLEMENTARIAS
// ==========================================
class ExternalShape {
  PVector pos, vel;
  int type; 
  float size = 25.0f;
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
      vel.mult(0.92f); // Fricción
      
      // Flotación aleatoria suave
      if (vel.mag() < 0.5f) vel.add(PVector.random2D().mult(0.2f));
      
      // Rebote en bordes de la pantalla
      if (pos.x < 20) { pos.x = 20; vel.x *= -1; }
      if (pos.x > width - 20) { pos.x = width - 20; vel.x *= -1; }
      if (pos.y < 20) { pos.y = 20; vel.y *= -1; }
      if (pos.y > height - 20) { pos.y = height - 20; vel.y *= -1; }
      
      // ESCUDO INVISIBLE: Prevenir que entren solas flotando
      float d = dist(pos.x, pos.y, cx, cy);
      // Si la figura está justo afuera de la línea, la empuja hacia afuera
      if (d > influenceRadius && d < influenceRadius + 25) {
        PVector repel = PVector.sub(pos, new PVector(cx, cy));
        repel.normalize();
        vel.add(repel.mult(1.5f)); // Fuerza de rebote del escudo
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
    fill(c, 210);
    
    if (type == 1) rect(0, 0, size, size);
    else ellipse(0, 0, size * 1.15f, size * 1.15f);
    
    popMatrix();
  }
}

class Particle {
  float x, y;
  PVector vel;
  float size, alpha;
  int col;
  
  Particle(float nx, float ny, int c) {
    x = nx; y = ny;
    // Expansión radial
    vel = PVector.random2D().mult(random(3.0f, 10.0f)); 
    size = random(4.0f, 10.0f);
    alpha = 255; col = c;
  }
  
  void update() {
    x += vel.x; y += vel.y;
    vel.mult(0.85f); // Fricción en el aire para que la explosión se frene suavemente
    alpha -= 5.0f; // Desvanecimiento
  }
  
  void display() {
    noStroke();
    fill(col, alpha);
    ellipse(x, y, size, size);
  }
}
