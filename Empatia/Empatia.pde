// ==========================================
// EMPATÍA: Flotación Libre y Pulsación Compartida
// ==========================================

ArrayList<Entity> entities;
ArrayList<BackgroundShape> bgShapes;
Entity draggedEntity = null;

float[][] syncProgress = new float[3][3];
boolean[][] isLinked = new boolean[3][3];

void setup() {
  size(900, 700);
  smooth(8);
  rectMode(CENTER);
  
  entities = new ArrayList<Entity>();
  bgShapes = new ArrayList<BackgroundShape>();
  
  // 3 Figuras principales
  entities.add(new Entity(0, 0, 250, 250, color(0, 245, 212), 22.0f, 0.08f)); // Triángulo
  entities.add(new Entity(1, 1, 650, 250, color(4, 139, 133), 28.0f, 0.02f)); // Cuadrado
  entities.add(new Entity(2, 2, 450, 550, color(72, 202, 228), 24.0f, 0.04f)); // Círculo
  
  // Figuras de fondo (flotando libremente por toda la pantalla)
  for (int i = 0; i < 15; i++) {
    bgShapes.add(new BackgroundShape());
  }
  
  for(int i = 0; i < 3; i++) {
    for(int j = 0; j < 3; j++) {
      syncProgress[i][j] = 0.0f;
      isLinked[i][j] = false;
    }
  }
}

void draw() {
  int bgBase = color(4, 15, 22);
  int bgHarmony = color(10, 45, 55);
  
  int linkCount = 0;
  if(isLinked[0][1]) linkCount++;
  if(isLinked[1][2]) linkCount++;
  if(isLinked[0][2]) linkCount++;
  
  float harmonyGlow = linkCount / 3.0f;
  background(lerpColor(bgBase, bgHarmony, harmonyGlow));
  
  // Tomar la fase de la primera figura principal como referencia de palpitación global
  float globalPhase = entities.get(0).phase;
  
  // Actualizar y dibujar fondo atmosférico (flotando libremente y pulsando con el ritmo central)
  for (BackgroundShape bg : bgShapes) {
    bg.update();
    bg.display(globalPhase);
  }
  

  // 1. LÓGICA DE ESCUCHA, CONEXIÓN Y RUPTURA (Desvincular al alejar)
  for (int i = 0; i < 3; i++) {
    for (int j = i + 1; j < 3; j++) {
      Entity e1 = entities.get(i);
      Entity e2 = entities.get(j);
      float d = e1.pos.dist(e2.pos);
      
      if (isLinked[i][j]) {
        if (d > 210) {
          isLinked[i][j] = false;
          isLinked[j][i] = false;
          syncProgress[i][j] = 0.0f;
          syncProgress[j][i] = 0.0f;
        } else {
          float pulseLine = map(sin(e1.phase), -1, 1, 1.0f, 3.0f);
          stroke(lerpColor(e1.col, e2.col, 0.5f), 200);
          strokeWeight(pulseLine);
          line(e1.pos.x, e1.pos.y, e2.pos.x, e2.pos.y);
          
          PVector pull = PVector.sub(e2.pos, e1.pos);
          float dist = pull.mag();
          pull.normalize();
          
          float force = (dist - 130) * 0.0005f;
          e1.vel.add(PVector.mult(pull, force));
          e2.vel.sub(PVector.mult(pull, force));
          
          PVector tangent = new PVector(-pull.y, pull.x).mult(0.0015f);
          e1.vel.add(tangent);
          e2.vel.sub(tangent);
        }
      } else {
        if (d < 140) {
          syncProgress[i][j] += 0.003f;
          syncProgress[j][i] = syncProgress[i][j];
          
          float shake = (1.0f - syncProgress[i][j]) * 1.5f; 
          stroke(lerpColor(e1.col, e2.col, 0.5f), 120 * syncProgress[i][j]);
          strokeWeight(1.0f);
          line(e1.pos.x + random(-shake, shake), e1.pos.y + random(-shake, shake), 
               e2.pos.x + random(-shake, shake), e2.pos.y + random(-shake, shake));
               
          if (syncProgress[i][j] >= 1.0f) {
            isLinked[i][j] = true;
            isLinked[j][i] = true;
          }
        } else {
          if (syncProgress[i][j] > 0) {
            syncProgress[i][j] -= 0.005f;
            syncProgress[j][i] = syncProgress[i][j];
          }
        }
      }
    }
  }
  
  // 2. SINCRONIZACIÓN AISLADA POR GRUPOS DINÁMICOS
  updateGroupFrequencies();
  
  // 3. ACTUALIZAR Y DIBUJAR FIGURAS
  for (Entity e : entities) {
    e.updatePhysics();
    e.display();
  }
}

// Agrupación dinámica por componentes conectados
void updateGroupFrequencies() {
  int[] root = {0, 1, 2};
  if (isLinked[0][1]) {
    int r0 = root[0];
    int r1 = root[1];
    for(int k=0; k<3; k++) if(root[k] == r1) root[k] = r0;
  }
  if (isLinked[1][2]) {
    int r1 = root[1];
    int r2 = root[2];
    for(int k=0; k<3; k++) if(root[k] == r2) root[k] = r1;
  }
  if (isLinked[0][2]) {
    int r0 = root[0];
    int r2 = root[2];
    for(int k=0; k<3; k++) if(root[k] == r2) root[k] = r0;
  }
  
  float[] sumF = new float[3];
  int[] countF = new int[3];
  for(int i=0; i<3; i++) {
    sumF[root[i]] += entities.get(i).baseFreq;
    countF[root[i]]++;
  }
  
  for(int i=0; i<3; i++) {
    Entity e = entities.get(i);
    int r = root[i];
    float avgF = sumF[r] / countF[r];
    e.currentFreq = lerp(e.currentFreq, avgF, 0.05f);
    
    int leader = -1;
    for(int k=0; k<3; k++) {
      if(root[k] == r) { leader = k; break; }
    }
    
    if (i == leader) {
      e.phase += e.currentFreq;
    } else {
      e.phase = entities.get(leader).phase;
    }
  }
}

// ==========================================
// INTERACCIONES MOUSE
// ==========================================
void mousePressed() {
  for (Entity e : entities) {
    if (dist(mouseX, mouseY, e.pos.x, e.pos.y) < max(35, e.sz)) {
      draggedEntity = e;
      break;
    }
  }
}

void mouseReleased() {
  draggedEntity = null;
}

// ==========================================
// CLASES
// ==========================================
class Entity {
  int id; 
  int type; 
  PVector pos, vel;
  int col;
  float sz;
  
  float baseFreq;
  float currentFreq;
  float phase;
  float angle = 0;
  
  Entity(int id, int t, float x, float y, int c, float s, float freq) {
    this.id = id;
    this.type = t;
    this.pos = new PVector(x, y);
    this.vel = PVector.random2D().mult(random(0.1f, 0.3f));
    this.col = c;
    this.sz = s;
    this.baseFreq = freq;
    this.currentFreq = freq;
    this.phase = random(TWO_PI);
  }
  
  void updatePhysics() {
    if (this == draggedEntity) {
      pos.x = lerp(pos.x, mouseX, 0.2f);
      pos.y = lerp(pos.y, mouseY, 0.2f);
      vel.set(0, 0);
    } else {
      pos.add(vel);
      vel.mult(0.96f);
      
      if (vel.mag() < 0.2f) {
        vel.add(PVector.random2D().mult(0.02f));
      }
      
      if (pos.x < 40 || pos.x > width - 40) vel.x *= -1;
      if (pos.y < 40 || pos.y > height - 40) vel.y *= -1;
      pos.x = constrain(pos.x, 40, width - 40);
      pos.y = constrain(pos.y, 40, height - 40);
    }
    angle += 0.005f;
  }
  
  void display() {
    pushMatrix();
    
    float maxFriction = 0;
    for(int j=0; j<3; j++) {
      if (j != id && !isLinked[id][j] && syncProgress[id][j] > 0) {
        maxFriction = max(maxFriction, (1.0f - syncProgress[id][j]));
      }
    }
    float shake = maxFriction * 1.0f;
    translate(pos.x + random(-shake, shake), pos.y + random(-shake, shake));
    rotate(angle);
    
    float currentSize = sz + sin(phase) * (sz * 0.3f);
    boolean isUnited = (isLinked[id][0] || isLinked[id][1] || isLinked[id][2]);
    
    if (isUnited) {
      noStroke();
      fill(red(col), green(col), blue(col), 60);
      if (type == 0) {
        float glowR = currentSize * 1.6f;
        beginShape();
        for (int i = 0; i < 3; i++) {
          float a = i * TWO_PI / 3.0f - HALF_PI;
          vertex(cos(a) * glowR, sin(a) * glowR);
        }
        endShape(CLOSE);
      } else if (type == 1) {
        rect(0, 0, currentSize * 2.2f, currentSize * 2.2f);
      } else {
        ellipse(0, 0, currentSize * 2.4f, currentSize * 2.4f);
      }
    }
    
    noStroke();
    fill(col);
    
    if (type == 0) {
      beginShape();
      for (int i = 0; i < 3; i++) {
        float a = i * TWO_PI / 3.0f - HALF_PI;
        vertex(cos(a) * currentSize, sin(a) * currentSize);
      }
      endShape(CLOSE);
    } else if (type == 1) {
      rect(0, 0, currentSize * 1.5f, currentSize * 1.5f);
    } else if (type == 2) {
      ellipse(0, 0, currentSize * 1.6f, currentSize * 1.6f);
    }
    
    popMatrix();
  }
}

// ==========================================
// CLASE BACKGROUND SHAPE (Flotación libre y palpitante)
// ==========================================
class BackgroundShape {
  PVector pos, vel;
  int type; // 0: Triángulo, 1: Cuadrado, 2: Círculo
  float sz, angle, rotSpeed;
  int col;
  
  BackgroundShape() {
    pos = new PVector(random(width), random(height));
    vel = PVector.random2D().mult(random(0.1f, 0.4f));
    type = int(random(3));
    sz = random(15, 30);
    angle = random(TWO_PI);
    rotSpeed = random(-0.005f, 0.005f);
    col = color(72, 202, 228); 
  }
  
  void update() {
    pos.add(vel);
    vel.mult(0.99f);
    if (vel.mag() < 0.2f) {
      vel.add(PVector.random2D().mult(0.05f));
    }
    vel.limit(0.5f);
    
    angle += rotSpeed;
    
    // Pantalla infinita (rebote o loop por los bordes)
    if (pos.x < -30) pos.x = width + 30;
    if (pos.x > width + 30) pos.x = -30;
    if (pos.y < -30) pos.y = height + 30;
    if (pos.y > height + 30) pos.y = -30;
  }
  
  void display(float globalPhase) {
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(angle);
    
    // Las figuras de fondo toman la velocidad de palpitación de las figuras centrales
    float currentSz = sz + sin(globalPhase) * (sz * 0.2f);
    
    noFill();
    float alpha = 25 + sin(globalPhase) * 15; // Suave variación de opacidad con el latido
    stroke(col, alpha); 
    strokeWeight(1.0f);
    
    if (type == 0) {
      beginShape();
      for (int i = 0; i < 3; i++) {
        float a = i * TWO_PI / 3.0f - HALF_PI;
        vertex(cos(a) * currentSz, sin(a) * currentSz);
      }
      endShape(CLOSE);
    } else if (type == 1) {
      rect(0, 0, currentSz * 1.2f, currentSz * 1.2f);
    } else {
      ellipse(0, 0, currentSz * 1.3f, currentSz * 1.3f);
    }
    
    popMatrix();
  }
}
