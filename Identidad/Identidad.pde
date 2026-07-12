/*
 * OBRA DE ARTE GENERATIVO: "La Ruptura de la Línea" (Versión Processing Pura - Corregida)
 * - 1er Click: Detiene la fila en el centro.
 * - Movimiento rápido del mouse sobre el cuadrado central (Shake): Activa colores pastel aleatorios.
 * - 2do Click: Define la trayectoria OPUESTA. Los cuadrados rebeldes se disparan con gradientes.
 * - Reinicio automático tras 9 segundos.
 */

ArrayList<Square> squares;
float flowSpeed = 0.003f;
int spawnRate = 14; 

// Puntos de control vectoriales
PVector startPoint;
PVector endPoint;
PVector breakPoint;
PVector targetPoint;
PVector newEndPoint;

// Estados del sistema: 
// 0: Conformidad, 1: Congelado/Esperando agitación, 2: Cargado/Esperando dirección, 3: Disparo opuesto, 4: Retorno
int appState = 0; 
int activeColor;
boolean spawnColored = false;
Square selectedSquare = null;
float breakT = 0.0f;

// Factores físicos de transición
float stopFactor = 0.0f;
float pathMorphFactor = 0.0f;
float colorResetFactor = 1.0f;

// Temporizadores y agitación
int timerStart = 0;
int timerDuration = 9000; // Duración aumentada a 9 segundos para mayor apreciación
float shakeProgress = 0;
float shakeTarget = 150;

// Partículas decorativas de impacto
ArrayList<Particle> particles;

// Colores pastel
int[] pastelColors;

void setup() {
  size(800, 600);
  smooth(8);
  rectMode(CENTER);
  
  squares = new ArrayList<Square>();
  particles = new ArrayList<Particle>();
  
  startPoint = new PVector(80, 80);
  endPoint = new PVector(width - 80, height - 80);
  breakPoint = new PVector(width / 2, height / 2);
  targetPoint = new PVector(0, 0);
  newEndPoint = new PVector(0, 0);
  
  activeColor = color(110, 115, 125);
  
  // Inicializar paleta pastel
  pastelColors = new int[] {
    color(255, 183, 178), color(255, 218, 193), color(226, 240, 203), 
    color(191, 252, 198), color(199, 206, 234), color(255, 154, 162), 
    color(232, 197, 229), color(175, 228, 222), color(252, 225, 212)
  };
}

void draw() {
  // Fondo sólido (Elimina por completo la acumulación de luz y las estelas de barrido)
  background(5, 4, 9);

  // Generación constante de figuras
  if (frameCount % spawnRate == 0) {
    squares.add(new Square());
  }

  // Dibujar sutil línea de flujo de fondo
  stroke(255, 255, 255, 6);
  strokeWeight(1);
  line(startPoint.x, startPoint.y, endPoint.x, endPoint.y);

  // Detección de agitación del mouse en el centro (Estados 1 y 2)
  if (appState == 1) {
    float d = dist(mouseX, mouseY, breakPoint.x, breakPoint.y);
    if (d < 50) {
      float speed = dist(mouseX, mouseY, pmouseX, pmouseY);
      if (speed > 10) {
        shakeProgress += speed * 0.15f;
        
        // Chispas de agitación cinética
        if (frameCount % 3 == 0) {
          activeColor = pastelColors[int(random(pastelColors.length))];
          createExplosion(breakPoint.x, breakPoint.y, activeColor, 2);
        }
        
        if (shakeProgress >= shakeTarget) {
          createExplosion(breakPoint.x, breakPoint.y, activeColor, 35);
          appState = 2; // Cargado y listo
        }
      }
    }
  }

  // Dibujar vector de trayectoria si está disparando (Estado 3)
  if (appState == 3) {
    stroke(activeColor, 30);
    strokeWeight(1);
    line(startPoint.x, startPoint.y, breakPoint.x, breakPoint.y);
    line(breakPoint.x, breakPoint.y, newEndPoint.x, newEndPoint.y);
  }

  // Actualizar y dibujar cuadrados
  for (int i = squares.size() - 1; i >= 0; i--) {
    Square s = squares.get(i);
    s.update();
    s.display();
    
    // Detección física de límites de pantalla para evitar el retorno forzado/snap back de figuras lejanas
    boolean outOfBounds = (s.pos.x < -50 || s.pos.x > width + 50 || s.pos.y < -50 || s.pos.y > height + 50);

    if (s.t >= 1.0f || outOfBounds) {
      squares.remove(i);
    }
  }

  // Actualizar y dIbujar chispas/partículas
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.display();
    if (p.alpha <= 0) {
      particles.remove(i);
    }
  }

  handleTransitions();
}

void handleTransitions() {
  if (appState == 1 || appState == 2) {
    stopFactor = lerp(stopFactor, 1.0f, 0.05f);
  }

  if (appState == 3) {
    pathMorphFactor = lerp(pathMorphFactor, 1.0f, 0.06f);
    
    // Temporizador de reinicio
    if (millis() - timerStart >= timerDuration) {
      appState = 4; // Retorno
      spawnColored = false;
    }
  } 
  else if (appState == 4) {
    pathMorphFactor = lerp(pathMorphFactor, 0.0f, 0.03f);
    stopFactor = lerp(stopFactor, 0.0f, 0.03f);
    colorResetFactor = lerp(colorResetFactor, 0.0f, 0.02f);

    if (pathMorphFactor < 0.01f && stopFactor < 0.01f && colorResetFactor < 0.01f) {
      resetSystem();
    }
  }
}

void mousePressed() {
  if (appState == 0) {
    if (squares.size() == 0) return;

    // Buscar el cuadrado más cercano al click
    float minDist = 999999;
    int closestIndex = -1;

    for (int i = 0; i < squares.size(); i++) {
      float d = dist(mouseX, mouseY, squares.get(i).pos.x, squares.get(i).pos.y);
      if (d < minDist && d < 45) {
        minDist = d;
        closestIndex = i;
      }
    }

    if (closestIndex != -1) {
      selectedSquare = squares.get(closestIndex);
      breakT = selectedSquare.t;
      activeColor = color(161, 161, 170); // Gris neutro antes de agitar

      // Detener y marcar la fila posterior
      for (int i = 0; i < squares.size(); i++) {
        if (squares.get(i).t <= breakT) {
          squares.get(i).isColored = true;
          squares.get(i).isFollower = true;
        }
      }

      spawnColored = true;
      appState = 1;
      stopFactor = 0.0f;
    }
  } 
  else if (appState == 2) {
    // Definir dirección contraria (Fuerza Opuesta)
    targetPoint.set(mouseX, mouseY);

    PVector dir = PVector.sub(targetPoint, breakPoint);
    dir.normalize();
    
    // INVERTIR VECTOR: Dirección totalmente opuesta
    dir.mult(-1.0f);

    float originalLength = startPoint.dist(endPoint);
    float remainingLength = originalLength * (1.0f - breakT);

    newEndPoint = PVector.add(breakPoint, PVector.mult(dir, remainingLength * 1.5f));

    createExplosion(breakPoint.x, breakPoint.y, activeColor, 40);

    appState = 3;
    timerStart = millis();
  }
}

void createExplosion(float x, float y, int c, int count) {
  for (int i = 0; i < count; i++) {
    particles.add(new Particle(x, y, c));
  }
}

void resetSystem() {
  squares.clear();
  particles.clear();
  appState = 0;
  spawnColored = false;
  stopFactor = 0.0f;
  pathMorphFactor = 0.0f;
  colorResetFactor = 1.0f;
  shakeProgress = 0;
  selectedSquare = null;
  activeColor = color(110, 115, 125);
}

// ==========================================
// CLASES COMPLEMENTARIAS
// ==========================================

class Square {
  float t;
  PVector pos;
  int baseColor;
  boolean isColored;
  boolean isFollower;
  float angle;
  float pulse;
  float size;

  Square() {
    this.t = 0.0f;
    this.pos = new PVector();
    this.baseColor = color(110, 115, 125);
    this.isColored = spawnColored;
    this.isFollower = false;
    this.angle = random(TWO_PI);
    this.pulse = random(TWO_PI);
    this.size = 14;

    if (this.isColored) {
      // 60% de probabilidad de ser rebelde y seguir el nuevo camino opuesto
      this.isFollower = random(1.0f) > 0.4f; 
    }
  }

  void update() {
    angle += 0.01f;
    pulse += 0.05f;

    // Los cuadrados solo se detienen en los estados de congelación y carga (1 y 2).
    // Al pasar al estado de disparo (3), avanzan libremente de nuevo.
    if (isColored && (appState == 1 || appState == 2)) {
      t += flowSpeed * (1.0f - stopFactor);
    } else {
      t += flowSpeed;
    }

    PVector posOrig = getOriginalPath(t);

    PVector posFrozen = new PVector();
    if (t < breakT) {
      float norm = breakT > 0 ? (t / breakT) : 0;
      posFrozen.set(
        lerp(startPoint.x, breakPoint.x, norm),
        lerp(startPoint.y, breakPoint.y, norm)
      );
      posFrozen.y += sin(t * TWO_PI * 2) * 8;
    } else {
      posFrozen.set(breakPoint.x, breakPoint.y);
    }

    PVector posAlt = getBrokenPath(t);

    PVector finalBase = new PVector();
    if (isColored) {
      finalBase.x = lerp(posOrig.x, posFrozen.x, stopFactor);
      finalBase.y = lerp(posOrig.y, posFrozen.y, stopFactor);
    } else {
      finalBase.set(posOrig.x, posOrig.y);
    }

    if (isFollower) {
      pos.x = lerp(finalBase.x, posAlt.x, pathMorphFactor);
      pos.y = lerp(finalBase.y, posAlt.y, pathMorphFactor);
    } else {
      pos.x = lerp(finalBase.x, posOrig.x, pathMorphFactor);
      pos.y = lerp(finalBase.y, posOrig.y, pathMorphFactor);
    }
  }

  void display() {
    int finalColor = baseColor;
    boolean hasGradient = false;
    
    if (isColored && isFollower) {
      hasGradient = true;
      if (appState == 4) {
        finalColor = lerpColor(baseColor, activeColor, colorResetFactor);
      } else {
        finalColor = activeColor;
      }
    }

    pushMatrix();
    translate(pos.x, pos.y);
    rotate(angle);

    if (hasGradient) {
      // Dibujar gradiente lineal interno de forma limpia y fluida
      noStroke();
      int cStart = finalColor;
      int cEnd = lerpColor(finalColor, color(255, 255, 255), 0.45f); // Brillo pastel progresivo
      
      for (int j = 0; j < size; j++) {
        float inter = (float) j / size;
        int col = lerpColor(cStart, cEnd, inter);
        stroke(col);
        line(-size/2, -size/2 + j, size/2, -size/2 + j);
      }
      
      // Contorno sutil del cuadrado para dar definición
      stroke(255, 45);
      strokeWeight(1.0f);
      noFill();
      rect(0, 0, size, size);
    } else {
      // Cuadrado base plano para mantener la estética uniforme
      fill(finalColor);
      stroke(255, 30);
      strokeWeight(1.5f);
      rect(0, 0, size, size);
    }
    
    popMatrix();
  }

  PVector getOriginalPath(float val) {
    float x = lerp(startPoint.x, endPoint.x, val);
    float y = lerp(startPoint.y, endPoint.y, val);
    y += sin(val * TWO_PI * 2) * 8;
    return new PVector(x, y);
  }

  PVector getBrokenPath(float val) {
    if (val < breakT) {
      float norm = breakT > 0 ? (val / breakT) : 0;
      float x = lerp(startPoint.x, breakPoint.x, norm);
      float y = lerp(startPoint.y, breakPoint.y, norm);
      y += sin(val * TWO_PI * 2) * 8;
      return new PVector(x, y);
    } else {
      float norm = map(val, breakT, 1.0f, 0.0f, 1.0f);
      float x = lerp(breakPoint.x, newEndPoint.x, norm);
      float y = lerp(breakPoint.y, newEndPoint.y, norm);
      y += sin(val * TWO_PI * 2) * 8;
      return new PVector(x, y);
    }
  }
}

class Particle {
  float x, y;
  float vx, vy;
  float size;
  float alpha;
  int colorVal;
  float decay;

  Particle(float nx, float ny, int c) {
    x = nx;
    y = ny;
    vx = random(-4, 4);
    vy = random(-4, 4);
    size = random(2, 6);
    alpha = 255;
    colorVal = c;
    decay = random(3, 8);
  }

  void update() {
    x += vx;
    y += vy;
    alpha -= decay;
  }

  void display() {
    noStroke();
    fill(colorVal, alpha);
    ellipse(x, y, size, size);
  }
}
