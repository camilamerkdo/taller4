
ArrayList<TriangleShape> triangles;
SquareShape mainSquare;

boolean empathyUnlocked = false; 
boolean isIntegrated = false;    
float transitionProgress = 0.0f; 
float globalGlow = 0.0f;

float integrationLevel = 0.0f;

int colTriangle;
int colSquare;
int colCircleActive;

float gridCX = 450;
float gridCY = 310; 
float zoneW = 504;  
float zoneH = 420;  
float cellSize = 42.0f;

void setup() {
  size(900, 700);
  smooth(8);
  rectMode(CENTER);
  
  triangles = new ArrayList<TriangleShape>();
  
  colTriangle = color(255, 183, 178);     
  colSquare = color(199, 206, 234);       
  colCircleActive = color(175, 228, 222); 
  
  int initCols = 10;
  int initRows = 8;
  
  float startX = gridCX - ((initCols - 1) * cellSize) / 2.0f;
  float startY = gridCY - ((initRows - 1) * cellSize) / 2.0f; 
  
  for (int row = 0; row < initRows; row++) {
    for (int col = 0; col < initCols; col++) {
      float ix = startX + col * cellSize;
      float iy = startY + row * cellSize;
      triangles.add(new TriangleShape(ix, iy, cellSize));
    }
  }
  
  float squareSize = 84.0f; 
  mainSquare = new SquareShape(gridCX, 620, squareSize);
}

void draw() {
  int bgBase = color(5, 4, 9);
  int bgResonant = color(22, 15, 38);
  
  globalGlow = lerp(globalGlow, isIntegrated ? 1.0f : 0.0f, 0.05f);
  background(lerpColor(bgBase, bgResonant, globalGlow));
  
  drawIntegrationZone();
  
  boolean squareInZone = isInZone(mainSquare.pos.x, mainSquare.pos.y);
  
  if (mainSquare.isDragging && !empathyUnlocked) {
    if (squareInZone) {
      integrationLevel = lerp(integrationLevel, 1.0f, 0.04f);
    } else {
      integrationLevel = lerp(integrationLevel, 0.0f, 0.05f);
    }
  } else if (!mainSquare.isDragging && !empathyUnlocked) {
    integrationLevel = lerp(integrationLevel, 0.0f, 0.05f);
  }
  
  if (empathyUnlocked && transitionProgress < 1.0f) {
    transitionProgress += 1.0f / 150.0f; 
    if (transitionProgress > 1.0f) transitionProgress = 1.0f;
  }
  
  for (TriangleShape t : triangles) {
    t.update();
    t.display();
  }
  
  mainSquare.update();
  mainSquare.display();
}

void drawIntegrationZone() {
  pushMatrix();
  translate(gridCX, gridCY);
  
  noFill();
  stroke(255, 30);
  strokeWeight(2);
  rect(0, 0, zoneW, zoneH); 
  
  stroke(255, 10);
  strokeWeight(1);
  for(float x = -zoneW/2; x <= zoneW/2; x += cellSize) {
    line(x, -zoneH/2, x, zoneH/2);
  }
  for(float y = -zoneH/2; y <= zoneH/2; y += cellSize) {
    line(-zoneW/2, y, zoneW/2, y);
  }
  
  popMatrix();
}

boolean isInZone(float x, float y) {
  return (abs(x - gridCX) < zoneW/2) && (abs(y - gridCY) < zoneH/2);
}

float easeInOutCubic(float x) {
  return x < 0.5f ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2.0f;
}

class CellCand {
  int c, r; float weight;
  CellCand(int c, int r, float w) { this.c = c; this.r = r; this.weight = w; }
}

void addCand(int c, int r, float snapX, float snapY, ArrayList<CellCand> candidates, boolean[][] visited) {
  if(c >= 0 && c < 12 && r >= 0 && r < 10 && !visited[c][r]) {
    float cellX = (gridCX - zoneW/2) + c * cellSize + cellSize/2;
    float cellY = (gridCY - zoneH/2) + r * cellSize + cellSize/2;
    float d = dist(cellX, cellY, snapX, snapY);
    float w = (d * 1.5f) - (r * 20.0f) + random(0, 50); 
    candidates.add(new CellCand(c, r, w));
    visited[c][r] = true;
  }
}

void calculateEmpathyPositions(float snapX, float snapY) {
  ArrayList<CellCand> candidates = new ArrayList<CellCand>();
  ArrayList<PVector> selectedCells = new ArrayList<PVector>();
  boolean[][] visited = new boolean[12][10];
  
  int sqCol = round((snapX - cellSize - (gridCX - zoneW/2)) / cellSize);
  int sqRow = round((snapY - cellSize - (gridCY - zoneH/2)) / cellSize);
  
  for(int c = sqCol; c <= sqCol+1; c++) {
    for(int r = sqRow; r <= sqRow+1; r++) {
      if(c >= 0 && c < 12 && r >= 0 && r < 10) visited[c][r] = true;
    }
  }
  
  for(int c = sqCol-1; c <= sqCol+2; c++) {
    for(int r = sqRow-1; r <= sqRow+2; r++) {
      if(c == sqCol-1 || c == sqCol+2 || r == sqRow-1 || r == sqRow+2) {
        addCand(c, r, snapX, snapY, candidates, visited);
      }
    }
  }
  
  while(selectedCells.size() < 20 && candidates.size() > 0) {
    int best = 0;
    for(int i = 1; i < candidates.size(); i++) {
      if(candidates.get(i).weight < candidates.get(best).weight) best = i;
    }
    CellCand chosen = candidates.remove(best);
    
    float cellX = (gridCX - zoneW/2) + chosen.c * cellSize + cellSize/2;
    float cellY = (gridCY - zoneH/2) + chosen.r * cellSize + cellSize/2;
    selectedCells.add(new PVector(cellX, cellY));
    
    addCand(chosen.c - 1, chosen.r, snapX, snapY, candidates, visited);
    addCand(chosen.c + 1, chosen.r, snapX, snapY, candidates, visited);
    addCand(chosen.c, chosen.r - 1, snapX, snapY, candidates, visited);
    addCand(chosen.c, chosen.r + 1, snapX, snapY, candidates, visited);
  }
  
  int idx = 0;
  // Margen extra entre bloques de celdas vecinas para evitar cruces
  float cellBlockSize = cellSize * 0.82f; 
  float distToCentroid = cellBlockSize / 3.0f; 
  
  for(PVector cell : selectedCells) {
    if(idx >= triangles.size()) break;
    
    triangles.get(idx).empathyPos.set(cell.x, cell.y - distToCentroid);
    triangles.get(idx).empathyAngle = PI; idx++;
    triangles.get(idx).empathyPos.set(cell.x + distToCentroid, cell.y);
    triangles.get(idx).empathyAngle = -HALF_PI; idx++;
    triangles.get(idx).empathyPos.set(cell.x, cell.y + distToCentroid);
    triangles.get(idx).empathyAngle = 0.0f; idx++;
    triangles.get(idx).empathyPos.set(cell.x - distToCentroid, cell.y);
    triangles.get(idx).empathyAngle = HALF_PI; idx++;
  }
}

void mousePressed() {
  if (dist(mouseX, mouseY, mainSquare.pos.x, mainSquare.pos.y) < mainSquare.size / 2) {
    mainSquare.isDragging = true;
    empathyUnlocked = false; 
    isIntegrated = false;
  }
}

void mouseReleased() {
  if (mainSquare.isDragging) {
    mainSquare.isDragging = false;
    
    if (isInZone(mainSquare.pos.x, mainSquare.pos.y)) {
      float snapX = round((mainSquare.pos.x - gridCX) / cellSize) * cellSize + gridCX;
      float snapY = round((mainSquare.pos.y - gridCY) / cellSize) * cellSize + gridCY;
      
      snapX = constrain(snapX, gridCX - zoneW/2 + cellSize, gridCX + zoneW/2 - cellSize);
      snapY = constrain(snapY, gridCY - zoneH/2 + cellSize, gridCY + zoneH/2 - cellSize);
      
      mainSquare.targetPos.set(snapX, snapY);
      
      calculateEmpathyPositions(snapX, snapY);
      
      transitionProgress = 0.0f;
      empathyUnlocked = true;
      isIntegrated = true;
      
      for (TriangleShape t : triangles) {
        t.startTransitionPos = t.pos.copy();
        t.startTransitionAngle = t.angle;
      }
    } else {
      mainSquare.targetPos.set(gridCX, 620);
      isIntegrated = false;
    }
  }
}

class TriangleShape {
  PVector pos, initPos, empathyPos;
  float angle, initAngle, empathyAngle;
  float size;
  
  PVector scatterDir;
  float transitionDelay;
  PVector startTransitionPos;
  float startTransitionAngle;
  float randomBreatheOffset; 
  
  TriangleShape(float ix, float iy, float S) {
    this.pos = new PVector(ix, iy);
    this.initPos = new PVector(ix, iy);
    this.empathyPos = new PVector(ix, iy);
    
    this.angle = 0.0f; this.initAngle = 0.0f; this.empathyAngle = 0.0f;
    this.size = S * 0.82f; // Tamaño del triángulo reducido proporcionalmente al margen
    
    this.scatterDir = PVector.random2D();
    this.transitionDelay = random(0.0f, 0.4f);
    this.randomBreatheOffset = random(TWO_PI);
    
    this.startTransitionPos = this.pos.copy();
    this.startTransitionAngle = this.angle;
  }
  
  void update() {
    if (!empathyUnlocked) {
      PVector targetState = initPos.copy();
      float targetAngle = initAngle;
      
      if (integrationLevel > 0) {
        float scatterDist = easeInOutCubic(integrationLevel) * 160.0f;
        float breathe = sin(frameCount * 0.03f + randomBreatheOffset) * 15.0f * integrationLevel;
        targetState.add(PVector.mult(scatterDir, scatterDist + breathe));
        targetAngle = initAngle + (scatterDir.x * PI * integrationLevel);
      }
      
      float d = PVector.dist(mainSquare.pos, targetState);
      float repelRadius = 160.0f; 
      
      if (d < repelRadius) {
        PVector dir = PVector.sub(targetState, mainSquare.pos);
        dir.normalize();
        float t = 1.0f - (d / repelRadius);
        float strength = easeInOutCubic(t) * 100.0f; 
        targetState.add(dir.mult(strength));
      }
      
      pos.x = lerp(pos.x, targetState.x, 0.06f);
      pos.y = lerp(pos.y, targetState.y, 0.06f);
      angle = lerp(angle, targetAngle, 0.08f);
      
    } else {
      float myT = 0;
      if (transitionProgress > transitionDelay) {
        myT = map(transitionProgress, transitionDelay, min(1.0f, transitionDelay + 0.5f), 0.0f, 1.0f);
        myT = constrain(myT, 0.0f, 1.0f);
      }
      
      float t = easeInOutCubic(myT);
      
      pos.x = lerp(startTransitionPos.x, empathyPos.x, t);
      pos.y = lerp(startTransitionPos.y, empathyPos.y, t);
      
      float diff = empathyAngle - startTransitionAngle;
      while (diff < -PI) diff += TWO_PI;
      while (diff > PI) diff -= TWO_PI;
      angle = startTransitionAngle + diff * t;
    }
  }
  
  void display() {
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(angle);
    noStroke(); fill(colTriangle);
    beginShape();
    vertex(-size/2, size/6.0f); vertex(size/2, size/6.0f); vertex(0, -size/3.0f);
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
    if (isDragging) { pos.x = mouseX; pos.y = mouseY; } 
    else { pos.x = lerp(pos.x, targetPos.x, 0.1f); pos.y = lerp(pos.y, targetPos.y, 0.1f); }
  }
  
  void display() {
    pushMatrix(); translate(pos.x, pos.y);
    noStroke(); fill(colSquare); rect(0, 0, size, size);
    popMatrix();
  }
}
