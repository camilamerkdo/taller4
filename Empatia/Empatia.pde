/*
 * OBRA DE ARTE GENERATIVO: "La Ruptura de la Línea" (Corrección de Reinicio y Huérfanos)
 * Código 100% compatible y corregido para Processing de escritorio (Java) y Android.
 *
 * Correcciones de esta versión:
 * - Efecto Acordeón: En el reinicio, los seguidores se comprimen hacia el líder.
 * - Limpieza absoluta: Se eliminan los círculos "fantasmas grises" al completar el repliegue.
 */

import java.util.ArrayList;

ArrayList<Circle> circles;
ArrayList<Branch> branches;
float flowSpeed = 2.0f; // Velocidad lineal constante unificada
int spawnRate = 12;
int spawnCounter = 0; 

// Control del cuadrado interactivo
PVector squarePos;
boolean squareActive = false;
float hueVal = 0; 
float shakeIntensity = 0;
PVector prevMouse;

PVector startPoint;
PVector endPoint;

// Estados
int appState = 0; 
float colorResetFactor = 1.0f;

// Gestión de Colores Robustos "Nunca se repiten"
ArrayList<Integer> pastelHuesPool; 
int currentHueIndex = 0;
int lastHueUsed = -1; 

void setup() {
  size(800, 600);
  smooth(8);
  colorMode(HSB, 360, 100, 100);
  
  circles = new ArrayList<Circle>();
  branches = new ArrayList<Branch>();
  
  startPoint = new PVector(50, 50);
  endPoint = new PVector(width - 50, height - 50);
  squarePos = new PVector(0, 0);
  prevMouse = new PVector(0, 0);
  
  int numHues = 36; 
  int hueStep = 360 / numHues;
  pastelHuesPool = new ArrayList<Integer>();
  for (int i = 0; i < numHues; i++) pastelHuesPool.add(i * hueStep);
  java.util.Collections.shuffle(pastelHuesPool); 
}

void draw() {
  background(#0B0A10); 
  
  // 1. Generar círculos continuamente
  if (frameCount % spawnRate == 0) {
    int activePathCount = branches.size() + 1; 
    int pathChoice = spawnCounter % activePathCount;
    spawnCounter++;
    
    Circle c = new Circle();
    if (pathChoice > 0 && appState != 2) {
      c.isRebel = true;
      c.activeBranch = branches.get(pathChoice - 1);
    }
    circles.add(c);
  }
  
  // 2. Actualizar y dibujar círculos ACTIVOS PRIMERO 
  for (int i = circles.size() - 1; i >= 0; i--) {
    Circle c = circles.get(i);
    c.update();
    c.display();
    if (c.dead) {
      circles.remove(i);
    }
  }
  
  // 3. Dibujar ramificaciones DESPUÉS (El cuadrado jefe se dibuja ENCIMA)
  for (int i = 0; i < branches.size(); i++) {
    Branch b = branches.get(i);
    b.update();
    b.display();
  }
  
  // 4. Dibujar e interactuar con el Cuadrado Cabecilla si está activo
  if (squareActive) {
    updateAndDrawSquare();
  }
  
  // 5. Transición elástica de repliegue de reinicio
  handleResetTransition();
}

void updateAndDrawSquare() {
  squarePos.x = lerp(squarePos.x, mouseX, 0.15f);
  squarePos.y = lerp(squarePos.y, mouseY, 0.15f);
  
  float d = dist(mouseX, mouseY, prevMouse.x, prevMouse.y);
  shakeIntensity = lerp(shakeIntensity, d, 0.1f);
  prevMouse.set(mouseX, mouseY);
  
  if (shakeIntensity > 5.0f) {
    hueVal = (hueVal + shakeIntensity * 0.4f) % 360;
  }
  
  int activeColor = color(hueVal, 40, 95);
  
  noFill();
  stroke(hueVal, 40, 95, 40);
  strokeWeight(2 + shakeIntensity * 0.2f);
  rectMode(CENTER);
  rect(squarePos.x, squarePos.y, 24 + shakeIntensity * 0.5f, 24 + shakeIntensity * 0.5f);
  
  fill(activeColor);
  noStroke();
  rect(squarePos.x, squarePos.y, 16, 16);
}

void handleResetTransition() {
  if (appState == 2) {
    colorResetFactor = lerp(colorResetFactor, 0.0f, 0.02f);
    
    boolean clean = true;
    for (int i = 0; i < branches.size(); i++) {
      Branch b = branches.get(i);
      b.currentClick.x = lerp(b.currentClick.x, endPoint.x, 0.04f);
      b.currentClick.y = lerp(b.currentClick.y, endPoint.y, 0.04f);
      b.currentExit.x = lerp(b.currentExit.x, endPoint.x, 0.04f);
      b.currentExit.y = lerp(b.currentExit.y, endPoint.y, 0.04f);
      
      if (dist(b.currentClick.x, b.currentClick.y, endPoint.x, endPoint.y) > 10.0f) {
        clean = false;
      }
    }
    
    // CORRECCIÓN: Cuando la limpieza se completa, matamos a TODOS los rebeldes
    if (clean && colorResetFactor < 0.01f) {
      branches.clear();
      
      for (int i = circles.size() - 1; i >= 0; i--) {
        if (circles.get(i).isRebel) {
          circles.get(i).dead = true;
        }
      }
      
      appState = 0;
      colorResetFactor = 1.0f;
    }
  }
}

void mousePressed() {
  handleTouch(mouseX, mouseY);
}

void handleTouch(float tx, float ty) {
  if (appState == 0) {
    if (branches.size() >= 5) {
      appState = 2; 
      return;
    }
    
    squareActive = true;
    int border = (int) random(4);
    if (border == 0) squarePos.set(random(width), -20);
    else if (border == 1) squarePos.set(random(width), height + 20);
    else if (border == 2) squarePos.set(-20, random(height));
    else squarePos.set(width + 20, random(height));
    
    prevMouse.set(tx, ty);
    appState = 1;
  } 
  else if (appState == 1) {
    squareActive = false;
    
    PVector ap = PVector.sub(squarePos, startPoint);
    PVector ab = PVector.sub(endPoint, startPoint);
    ab.normalize();
    float d = ap.dot(ab);
    d = constrain(d, 50, PVector.dist(startPoint, endPoint) - 100);
    PVector breakPt = PVector.add(startPoint, PVector.mult(ab, d));
    
    PVector dirSalidaAbs = PVector.sub(squarePos, breakPt);
    dirSalidaAbs.normalize();
    PVector exitPt = PVector.add(squarePos, PVector.mult(dirSalidaAbs, 1000));
    
    int finalHue = pastelHuesPool.get(currentHueIndex);
    lastHueUsed = finalHue; 

    int finalColor = color(finalHue, 40, 95);
    
    currentHueIndex++;
    if (currentHueIndex >= pastelHuesPool.size()) { 
      java.util.Collections.shuffle(pastelHuesPool);
      while (pastelHuesPool.get(0) == lastHueUsed) java.util.Collections.shuffle(pastelHuesPool);
      currentHueIndex = 0;
    }
    
    branches.add(new Branch(breakPt, squarePos.copy(), exitPt, dirSalidaAbs, finalColor));
    appState = 0;
  }
}

class Branch {
  PVector breakPoint;
  PVector clickedPoint; 
  PVector exitPoint;    
  PVector dirSalidaNorm; 
  int col;
  
  PVector currentClick;
  PVector currentExit;
  boolean moving;
  float squareT;
  
  ArrayList<Circle> followers; 
  float separationDist = 38.0f; 
  
  Branch(PVector bPt, PVector cPt, PVector ePt, PVector dirSNorm, int col) {
    this.breakPoint = bPt;
    this.clickedPoint = cPt;
    this.exitPoint = ePt;
    this.dirSalidaNorm = dirSNorm.copy(); 
    this.col = col;
    this.currentClick = cPt.copy();
    this.currentExit = ePt.copy();
    this.moving = false;
    this.squareT = 0.0f;
    
    this.followers = new ArrayList<Circle>();
  }
  
  void addFollower(Circle c) {
    if (!c.inChain) {
      followers.add(c);
      c.inChain = true; 
    }
  }
  
  void update() {
    if (moving) {
      if (appState != 2) {
        float d = dist(clickedPoint.x, clickedPoint.y, exitPoint.x, exitPoint.y);
        if (d > 1.0f) {
          squareT += flowSpeed / d; 
          if (squareT > 1.0f) squareT = 1.0f;
        }
        currentClick.x = lerp(clickedPoint.x, exitPoint.x, squareT);
        currentClick.y = lerp(clickedPoint.y, exitPoint.y, squareT);
      }
      
      // CORRECCIÓN: Actualizar seguidores siempre. 
      // En reseteo (appState == 2), reducimos la separación multiplicando por colorResetFactor
      // Esto crea un efecto elástico donde los círculos se comprimen hacia el líder.
      float currentSep = (appState == 2) ? separationDist * colorResetFactor : separationDist;
      
      for (int i = 0; i < followers.size(); i++) {
        Circle c = followers.get(i);
        PVector offset = PVector.mult(dirSalidaNorm, (i + 1) * currentSep);
        c.pos = PVector.sub(currentClick, offset);
      }
    }
  }
  
  void display() {
    rectMode(CENTER);
    fill(col, 30);
    noStroke();
    rect(currentClick.x, currentClick.y, 24, 24);
    
    fill(col);
    rect(currentClick.x, currentClick.y, 16, 16);
  }
}

class Circle {
  float segmentT = 0.0f;
  int pathStep = 0;
  PVector pos;
  int baseColor;
  boolean dead = false;
  
  boolean isRebel = false;
  Branch activeBranch = null;
  
  boolean inChain = false; 
  
  Circle() {
    this.pos = new PVector();
    this.baseColor = color(0, 0, 45); 
  }
  
  PVector getWaypoint(int step) {
    if (isRebel && activeBranch != null) {
      if (step == 0) return startPoint;
      if (step == 1) return activeBranch.breakPoint;
      if (step == 2) return activeBranch.clickedPoint;
      return activeBranch.exitPoint; 
    } else {
      if (step == 0) return startPoint;
      return endPoint;
    }
  }
  
  int getMaxSteps() {
    return isRebel ? 4 : 2;
  }
  
  void update() {
    if (inChain) return;

    PVector pA = getWaypoint(pathStep);
    PVector pB = getWaypoint(pathStep + 1);
    
    float d = PVector.dist(pA, pB);
    if (d > 0.5f) {
      segmentT += flowSpeed / d; 
    } else {
      segmentT = 1.1f;
    }
    
    if (segmentT >= 1.0f) {
      segmentT = 0.0f;
      
      if (isRebel && activeBranch != null) {
        if (pathStep == 1) { 
          activeBranch.moving = true; 
        }
        if (pathStep == 2) { 
          activeBranch.addFollower(this); 
          return; 
        }
      }
      
      pathStep++;
    }
    
    if (pathStep >= getMaxSteps() - 1) {
      dead = true;
      return;
    }
    
    pA = getWaypoint(pathStep);
    pB = getWaypoint(pathStep + 1);
    pos = PVector.lerp(pA, pB, segmentT);
  }
  
  void display() {
    int finalColor;
    if (isRebel && activeBranch != null) {
      if (appState == 2) {
        finalColor = lerpColor(baseColor, activeBranch.col, colorResetFactor);
      } else {
        finalColor = activeBranch.col;
      }
    } else {
      finalColor = baseColor;
    }
    
    if (isRebel) {
      fill(finalColor, 25);
      noStroke();
      ellipse(pos.x, pos.y, 30, 30);
    }
    
    fill(finalColor);
    stroke(0, 0, 100, 15);
    strokeWeight(1);
    ellipse(pos.x, pos.y, 16, 16);
  }
}
