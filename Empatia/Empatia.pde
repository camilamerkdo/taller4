ArrayList<TriangleShape> triangles;
SquareShape mainSquare;

boolean empathyUnlocked = false; 
boolean isIntegrated = false;    
float transitionProgress = 0.0f; 
float globalGlow = 0.0f;

// Colores
int colTriangle;
int colSquare;
int colCircleActive;

// Centro de la pantalla y de la trama
float gridCX = 450;
float gridCY = 350;

// Variables de detección de movimiento (Shake)
float shakeIntensity = 0;

void setup() {
  size(900, 700);
  smooth(8);
  rectMode(CENTER);
  
  triangles = new ArrayList<TriangleShape>();
  
  colTriangle = color(255, 183, 178);     // Rosa pastel sólido
  colSquare = color(199, 206, 234);       // Azul pastel sólido
  colCircleActive = color(175, 228, 222); // Cian pastel
  
  // Parámetros de la grilla de grupos ampliada para cubrir toda la pantalla
  float S = 32.0f;       
  float margin = 2.0f;   
  float step = 44.0f;    
  
  ArrayList<PVector> targetPositions = new ArrayList<PVector>();
  ArrayList<Float> targetAngles = new ArrayList<Float>();
  
  // 1. Calcular las posiciones finales cubriendo toda la pantalla (16 col x 12 filas de grupos)
  int groupCols = 16;
  int groupRows = 12;
  
  for (int r = 0; r < groupRows; r++) {
    for (int c = 0; c < groupCols; c++) {
      // Dejar un hueco central ligeramente más holgado (2x2 de grupos) para que el cuadrado respire
      if ((c >= 7 && c <= 8) && (r >= 5 && r <= 6)) continue; 
      
      float gx = gridCX + (c - (groupCols - 1) / 2.0f) * step;
      float gy = gridCY + (r - (groupRows - 1) / 2.0f) * step;
      
      float distToCentroid = (S / 3.0f) + margin;
      
      targetPositions.add(new PVector(gx, gy - distToCentroid));
      targetAngles.add(PI); 
      targetPositions.add(new PVector(gx + distToCentroid, gy));
      targetAngles.add(-HALF_PI);
      targetPositions.add(new PVector(gx, gy + distToCentroid));
      targetAngles.add(0.0f); 
      targetPositions.add(new PVector(gx - distToCentroid, gy));
      targetAngles.add(HALF_PI); 
    }
  }
  
  // 2. Crear los triángulos en la trama densa inicial con mayor separación
  int initCols = 32;
  
  float spacingX = 34.0f; 
  float spacingY = 36.0f; 
  
  float startX = gridCX - ((initCols - 1) * spacingX) / 2.0f;
  float startY = 30.0f; 
  
  for (int i = 0; i < targetPositions.size(); i++) {
    int row = i / initCols;
    int col = i % initCols;
    
    float ix = startX + col * spacingX + (row % 2) * (spacingX / 2.0f);
    float iy = startY + row * spacingY;
    
    triangles.add(new TriangleShape(ix, iy, targetPositions.get(i), targetAngles.get(i), S));
  }
  
  // 3. Posición y tamaño del cuadrado abajo (Reducido a 72.0f para un margen estético perfecto)
  float squareSize = 72.0f; 
  mainSquare = new SquareShape(gridCX, 655, squareSize);
}

void draw() {
  int bgBase = color(5, 4, 9);
  int bgResonant = color(22, 15, 38);
  
  globalGlow = lerp(globalGlow, isIntegrated ? 1.0f : 0.0f, 0.05f);
  background(lerpColor(bgBase, bgResonant, globalGlow));
  
  // ==========================================
  // LÓGICA DE TRANSICIÓN (9 SEGUNDOS TOTALES)
  // ==========================================
  if (empathyUnlocked && transitionProgress < 1.0f) {
    transitionProgress += 1.0f / 540.0f; 
    if (transitionProgress > 1.0f) transitionProgress = 1.0f;
  }
  
  // Detección de agitación SOLO si el cuadrado está agarrado
  if (mainSquare.isDragging && !empathyUnlocked) {
    float mouseVel = dist(mouseX, mouseY, pmouseX, pmouseY);
    shakeIntensity = lerp(shakeIntensity, mouseVel, 0.2f);
    
    if (shakeIntensity > 40) {
      empathyUnlocked = true;
    }
  } else if (!mainSquare.isDragging) {
    shakeIntensity = 0; 
  }
  
  
  // Actualizar y dibujar
  for (TriangleShape t : triangles) {
    t.update();
    t.display();
  }
  
  mainSquare.update();
  mainSquare.display();
}

float easeInOutCubic(float x) {
  return x < 0.5f ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2.0f;
}

// ==========================================
// INTERACCIONES
// ==========================================
void mousePressed() {
  if (dist(mouseX, mouseY, mainSquare.pos.x, mainSquare.pos.y) < mainSquare.size / 2) {
    mainSquare.isDragging = true;
  }
}

void mouseReleased() {
  if (mainSquare.isDragging) {
    mainSquare.isDragging = false;
    
    // Si intenta soltarlo cerca del centro de la trama
    if (dist(mainSquare.pos.x, mainSquare.pos.y, gridCX, gridCY) < 180) {
      if (empathyUnlocked && transitionProgress > 0.95f) {
        if (dist(mainSquare.pos.x, mainSquare.pos.y, gridCX, gridCY) < 80) {
          mainSquare.targetPos.set(gridCX, gridCY);
          isIntegrated = true;
        } else {
          mainSquare.targetPos.set(gridCX, 655); 
        }
      } else {
        // RECHAZO: La trama aún es un bloque rígido
        mainSquare.targetPos.set(gridCX, 655);
      }
    } else {
      mainSquare.targetPos.set(gridCX, 655);
    }
  }
}

// ==========================================
// CLASES
// ==========================================
class TriangleShape {
  PVector pos;
  PVector initPos, empathyPos;
  float angle;
  float initAngle, empathyAngle;
  float size;
  
  TriangleShape(float ix, float iy, PVector ePos, float eAng, float S) {
    this.pos = new PVector(ix, iy);
    this.initPos = new PVector(ix, iy);
    this.empathyPos = ePos;
    
    this.angle = 0.0f; 
    this.initAngle = 0.0f;
    this.empathyAngle = eAng;
    this.size = S;
  }
  
  void update() {
    if (!empathyUnlocked) {
      PVector targetState = initPos.copy();
      float d = PVector.dist(mainSquare.pos, initPos);
      float repelRadius = 200.0f; 
      
      if (d < repelRadius) {
        PVector dir = PVector.sub(initPos, mainSquare.pos);
        dir.normalize();
        float strength = map(d, 0, repelRadius, 45.0f, 0.0f); 
        targetState.add(dir.mult(strength));
        targetState.x += random(-3.0f, 3.0f);
        targetState.y += random(-3.0f, 3.0f);
      }
      
      pos.x = lerp(pos.x, targetState.x, 0.15f);
      pos.y = lerp(pos.y, targetState.y, 0.15f);
      angle = initAngle;
      
    } else {
      float t = easeInOutCubic(transitionProgress);
      
      pos.x = lerp(initPos.x, empathyPos.x, t);
      pos.y = lerp(initPos.y, empathyPos.y, t);
      
      float diff = empathyAngle - initAngle;
      while (diff < -PI) diff += TWO_PI;
      while (diff > PI) diff -= TWO_PI;
      angle = initAngle + diff * t;
    }
  }
  
  void display() {
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(angle);
    
    noStroke();
    fill(colTriangle);
    
    beginShape();
    vertex(-size/2, size/6.0f);
    vertex(size/2, size/6.0f);
    vertex(0, -size/3.0f);
    endShape(CLOSE);
    
    popMatrix();
  }
}

class SquareShape {
  PVector pos, targetPos;
  float size;
  boolean isDragging = false;
  
  SquareShape(float x, float y, float s) {
    this.pos = new PVector(x, y);
    this.targetPos = new PVector(x, y);
    this.size = s;
  }
  
  void update() {
    if (isDragging) {
      pos.x = mouseX;
      pos.y = mouseY;
    } else {
      pos.x = lerp(pos.x, targetPos.x, 0.1f);
      pos.y = lerp(pos.y, targetPos.y, 0.1f);
    }
  }
  
  void display() {
    pushMatrix();
    translate(pos.x, pos.y);
    
    noStroke();
    fill(colSquare);
    
    rect(0, 0, size, size);
    
    popMatrix();
  }
}
