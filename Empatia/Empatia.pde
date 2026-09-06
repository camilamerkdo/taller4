// ==========================================
// EMPATÍA: La Paciencia de Escuchar (Tríada)
// ==========================================

ArrayList<Entity> entities;
Entity draggedEntity = null;

// Matriz para rastrear el progreso de sincronización entre cada par [i][j]
float[][] syncProgress = new float[3][3];
boolean[][] isLinked = new boolean[3][3];

void setup() {
  size(900, 700);
  smooth(8);
  rectMode(CENTER);
  
  entities = new ArrayList<Entity>();
  
  // 3 Figuras únicas con ritmos (frecuencias) muy diferentes. 
  // Ahora las frecuencias son más bajas (más tranquilas).
  
  // 0: Triángulo (Ritmo rápido/ansioso) - Menta Brillante
  entities.add(new Entity(0, 0, 250, 250, color(0, 245, 212), 22.0f, 0.08f)); 
  
  // 1: Cuadrado (Ritmo lento/rígido) - Teal Oscuro
  entities.add(new Entity(1, 1, 650, 250, color(4, 139, 133), 28.0f, 0.02f)); 
  
  // 2: Círculo (Ritmo medio/fluido) - Cian Suave
  entities.add(new Entity(2, 2, 450, 550, color(72, 202, 228), 24.0f, 0.04f)); 
  
  for(int i = 0; i < 3; i++) {
    for(int j = 0; j < 3; j++) {
      syncProgress[i][j] = 0.0f;
      isLinked[i][j] = false;
    }
  }
}

void draw() {
  // Fondo oscuro y sereno
  int bgBase = color(4, 15, 22);
  int bgHarmony = color(10, 45, 55);
  
  // Contar cuántos enlaces hay para iluminar el fondo
  int linkCount = 0;
  if(isLinked[0][1]) linkCount++;
  if(isLinked[1][2]) linkCount++;
  if(isLinked[0][2]) linkCount++;
  
  float harmonyGlow = linkCount / 3.0f;
  background(lerpColor(bgBase, bgHarmony, harmonyGlow));
  
  
  // 1. EMPATÍA TRANSITIVA (Si A entiende a B, y B entiende a C, los tres se conectan)
  if (isLinked[0][1] && isLinked[1][2]) { isLinked[0][2] = true; syncProgress[0][2] = 1.0f; }
  if (isLinked[0][1] && isLinked[0][2]) { isLinked[1][2] = true; syncProgress[1][2] = 1.0f; }
  if (isLinked[1][2] && isLinked[0][2]) { isLinked[0][1] = true; syncProgress[0][1] = 1.0f; }

  // 2. LÓGICA DE ESCUCHA Y CONEXIÓN
  for (int i = 0; i < 3; i++) {
    for (int j = i + 1; j < 3; j++) {
      Entity e1 = entities.get(i);
      Entity e2 = entities.get(j);
      float d = e1.pos.dist(e2.pos);
      
      if (d < 140) {
        if (!isLinked[i][j]) {
          // El progreso es muy lento, invitando a la paciencia (aprox 6 segundos)
          syncProgress[i][j] += 0.003f;
          syncProgress[j][i] = syncProgress[i][j];
          
          // Fricción visual (Temblor suave que se calma al acercarse al 1.0)
          float shake = (1.0f - syncProgress[i][j]) * 1.5f; 
          stroke(lerpColor(e1.col, e2.col, 0.5f), 120 * syncProgress[i][j]);
          strokeWeight(1.0f);
          line(e1.pos.x + random(-shake, shake), e1.pos.y + random(-shake, shake), 
               e2.pos.x + random(-shake, shake), e2.pos.y + random(-shake, shake));
               
          if (syncProgress[i][j] >= 1.0f) {
            isLinked[i][j] = true;
            isLinked[j][i] = true;
          }
        }
      } else {
        if (!isLinked[i][j] && syncProgress[i][j] > 0) {
          // Si se separan antes de entenderse, el progreso se pierde lentamente
          syncProgress[i][j] -= 0.005f;
          syncProgress[j][i] = syncProgress[i][j];
        }
      }
      
      // Dibujar hilos de armonía si ya están conectados
      if (isLinked[i][j]) {
        // La línea pulsa suavemente con la respiración compartida
        float pulseLine = map(sin(e1.phase), -1, 1, 1.0f, 3.0f);
        stroke(lerpColor(e1.col, e2.col, 0.5f), 200);
        strokeWeight(pulseLine);
        line(e1.pos.x, e1.pos.y, e2.pos.x, e2.pos.y);
        
        // Física Orbital: Se atraen suavemente y orbitan
        PVector pull = PVector.sub(e2.pos, e1.pos);
        float dist = pull.mag();
        pull.normalize();
        
        float force = (dist - 130) * 0.0005f; // Resorte muy delicado
        e1.vel.add(PVector.mult(pull, force));
        e2.vel.sub(PVector.mult(pull, force));
        
        // Movimiento circular conjunto
        PVector tangent = new PVector(-pull.y, pull.x).mult(0.0015f);
        e1.vel.add(tangent);
        e2.vel.sub(tangent);
      }
    }
  }
  
  // 3. SINCRONIZACIÓN DE RITMOS (Agrupar las frecuencias)
  updateGroupFrequencies();
  
  // 4. ACTUALIZAR Y DIBUJAR FIGURAS
  for (Entity e : entities) {
    e.updatePhysics();
    e.display();
  }
}

// Lógica para promediar las frecuencias si están unidas y alinear la respiración
void updateGroupFrequencies() {
  int[] group = new int[3];
  for(int i=0; i<3; i++) group[i] = i;
  
  if(isLinked[0][1]) { group[1] = group[0]; }
  if(isLinked[1][2]) { group[2] = group[1]; group[0] = group[1]; } 
  if(isLinked[0][2]) { group[2] = group[0]; group[1] = group[0]; }
  
  float[] sumF = new float[3];
  int[] countF = new int[3];
  for(int i=0; i<3; i++) {
    sumF[group[i]] += entities.get(i).baseFreq;
    countF[group[i]]++;
  }
  
  for(int g=0; g<3; g++) {
    if(countF[g] > 0) {
      float avgF = sumF[g] / countF[g]; // Ritmo promedio (empatía de grupo)
      int leader = -1;
      for(int i=0; i<3; i++) {
        if(group[i] == g) {
          Entity e = entities.get(i);
          e.currentFreq = lerp(e.currentFreq, avgF, 0.05f); // Transición suave al nuevo ritmo
          
          if(leader == -1) {
            leader = i;
            e.phase += e.currentFreq; 
          } else {
            // Siguen la misma fase exacta para respirar al unísono
            e.phase = entities.get(leader).phase; 
          }
        }
      }
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
// CLASE ENTITY
// ==========================================
class Entity {
  int id; 
  int type; // 0: Triángulo, 1: Cuadrado, 2: Círculo
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
    // Velocidad inicial muy tranquila
    this.vel = PVector.random2D().mult(random(0.1f, 0.3f));
    this.col = c;
    this.sz = s;
    this.baseFreq = freq;
    this.currentFreq = freq;
    this.phase = random(TWO_PI);
  }
  
  void updatePhysics() {
    if (this == draggedEntity) {
      // Movimiento suave hacia el mouse (no instantáneo, para mantener la calma)
      pos.x = lerp(pos.x, mouseX, 0.2f);
      pos.y = lerp(pos.y, mouseY, 0.2f);
      vel.set(0, 0);
    } else {
      pos.add(vel);
      vel.mult(0.96f); // Mucha fricción = movimientos más flotantes y lentos
      
      // Vagan libremente si están sueltos y lentos
      if (vel.mag() < 0.2f) {
        vel.add(PVector.random2D().mult(0.02f));
      }
      
      // Rebotes delicados en los bordes
      if (pos.x < 40 || pos.x > width - 40) vel.x *= -1;
      if (pos.y < 40 || pos.y > height - 40) vel.y *= -1;
      pos.x = constrain(pos.x, 40, width - 40);
      pos.y = constrain(pos.y, 40, height - 40);
    }
    
    // Rotación muy lenta
    angle += 0.005f;
  }
  
  void display() {
    pushMatrix();
    
    // Determinar si esta figura está experimentando fricción de escucha
    float maxFriction = 0;
    for(int j=0; j<3; j++) {
      if (j != id && !isLinked[id][j] && syncProgress[id][j] > 0) {
        maxFriction = max(maxFriction, (1.0f - syncProgress[id][j]));
      }
    }
    // Temblor muy sutil
    float shake = maxFriction * 1.0f;
    translate(pos.x + random(-shake, shake), pos.y + random(-shake, shake));
    rotate(angle);
    
    // Respiración (tamaño que pulsa)
    float currentSize = sz + sin(phase) * (sz * 0.3f);
    
    // Comprobar si está unido a algo para mostrar el aura empática
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
    
    // Figura Principal
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
