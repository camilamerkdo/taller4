ArrayList<Shape> shapes;
ArrayList<Particle> particles;
Shape draggedShape = null;

// Configuración de interacción
float connectionDist = 70.0f;  // Distancia para acoplar al soltar el clic
float snapSpeed = 0.15f;       // Velocidad del acoplamiento
float globalGlow = 0.0f;       // Brillo del fondo
int nextGroupID = 0;           // Generador de IDs únicos para grupos

// Colores pastel
int colTriangleActive;
int colSquareActive;
int colCircleActive;

// Lista que guarda los círculos de control que forman el anillo mayor
ArrayList<Shape> superRingCircles;

void setup() {
  size(900, 700);
  smooth(8);
  rectMode(CENTER);
  
  shapes = new ArrayList<Shape>();
  particles = new ArrayList<Particle>();
  superRingCircles = new ArrayList<Shape>();
  
  colTriangleActive = color(255, 183, 178); // Rosa pastel
  colSquareActive = color(199, 206, 234);   // Azul pastel
  colCircleActive = color(175, 228, 222);   // Cian/Verde pastel
  
  // 10 Triángulos y 10 Cuadrados para dar mucho juego de grupos
  for (int i = 0; i < 10; i++) {
    shapes.add(new Shape(0, random(100, width-100), random(100, height-100)));
  }
  for (int i = 0; i < 10; i++) {
    shapes.add(new Shape(1, random(100, width-100), random(100, height-100)));
  }
  // Los círculos ahora nacerán dinámicamente, por lo que empezamos con 0
}

void draw() {
  // Fondo dinámico
  int bgBase = color(5, 4, 9);
  int bgResonant = color(22, 15, 38);
  background(lerpColor(bgBase, bgResonant, globalGlow));
  
  // Actualizar posiciones físicas
  for (Shape s : shapes) {
    s.updatePhysics();
  }
  
  // Recopilar los círculos de control actuales
  ArrayList<Shape> controlCircles = new ArrayList<Shape>();
  for(Shape s : shapes) {
    if (s.isControlNode) controlCircles.add(s);
  }
  
  // ==========================================
  // LÓGICA DEL SÚPER ARO (Anillo de Círculos)
  // ==========================================
  if (superRingCircles.size() > 1) {
    globalGlow = lerp(globalGlow, 0.85f, 0.05f); // Iluminar todo
    
    PVector center = new PVector(width / 2, height / 2);
    float globalAngle = frameCount * 0.015f; // Rotación general
    
    for (int i = 0; i < superRingCircles.size(); i++) {
      Shape c = superRingCircles.get(i);
      float angle = globalAngle + (i * TWO_PI / superRingCircles.size());
      
      // El círculo se acomoda en un pequeño aro central
      c.targetPos.set(center.x + cos(angle) * 70, center.y + sin(angle) * 70);
      
      // Rayos de energía entre círculos del super aro
      Shape nextC = superRingCircles.get((i + 1) % superRingCircles.size());
      drawLightning(c.pos, nextC.pos, 1.0f);
      
      // Posicionar a las figuras del grupo como un gran aro exterior debajo de ellos
      float outerRadius = 180 + 20 * sin(frameCount * 0.05f);
      PVector groupCenter = new PVector(center.x + cos(angle) * outerRadius, center.y + sin(angle) * outerRadius);
      
      ArrayList<Shape> members = new ArrayList<Shape>();
      for(Shape s : shapes) if (s.groupID == c.linkedGroupID && !s.isControlNode) members.add(s);
      
      for(int j = 0; j < members.size(); j++){
        Shape m = members.get(j);
        float mAngle = frameCount * 0.05f + (j * TWO_PI / members.size());
        m.targetPos.set(groupCenter.x + cos(mAngle) * 45, groupCenter.y + sin(mAngle) * 45);
      }
    }
    
    // Halo de plasma en el centro de la pantalla
    noFill();
    stroke(255, 255, 255, 100);
    strokeWeight(2 + 2 * sin(frameCount * 0.1f));
    ellipse(center.x, center.y, 140, 140);
    if(frameCount % 3 == 0) {
        particles.add(new Particle(center.x + random(-20,20), center.y + random(-20,20), colCircleActive));
    }
    
  } else {
    // Si no hay Súper Aro, brillo disminuye
    globalGlow = lerp(globalGlow, 0.0f, 0.08f);
    
    // Grupos normales orbitando a sus círculos de control independientes
    for(Shape c : controlCircles) {
      if(superRingCircles.contains(c)) continue;
      
      ArrayList<Shape> members = new ArrayList<Shape>();
      for(Shape s : shapes) if (s.groupID == c.linkedGroupID && !s.isControlNode) members.add(s);
      
      for(int j = 0; j < members.size(); j++){
        Shape m = members.get(j);
        float mAngle = frameCount * 0.03f + (j * TWO_PI / members.size());
        m.targetPos.set(c.pos.x + cos(mAngle) * 55, c.pos.y + sin(mAngle) * 55);
      }
    }
  }
  
  // Dibujar enlaces visuales estéticos para todos los grupos
  for (Shape c : controlCircles) {
    ArrayList<Shape> members = new ArrayList<Shape>();
    for(Shape s : shapes) if (s.groupID == c.linkedGroupID && !s.isControlNode) members.add(s);
    
    if (members.size() > 0) {
      // Polígono del grupo
      stroke(c.targetColor, 50 + 150 * globalGlow);
      strokeWeight(2 + 2 * globalGlow);
      noFill();
      beginShape();
      for(Shape m : members) vertex(m.pos.x, m.pos.y);
      endShape(CLOSE);
      
      // Líneas de cada miembro a su círculo de control
      stroke(255, 255, 255, 40);
      strokeWeight(1);
      for(Shape m : members) line(m.pos.x, m.pos.y, c.pos.x, c.pos.y);
    }
  }
  
  // Actualizar gráficos de cada figura
  for (Shape s : shapes) {
    s.updatePosition();
    s.display();
  }
  
  // Sistema de Partículas
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.display();
    if (p.alpha <= 0) particles.remove(i);
  }
}

// ==========================================
// INTERACCIONES (MANUAL DRAG & DROP)
// ==========================================
void mousePressed() {
  float minDist = 35.0f;
  for (Shape s : shapes) {
    float d = dist(mouseX, mouseY, s.pos.x, s.pos.y);
    if (d < minDist) {
      minDist = d;
      draggedShape = s;
    }
  }
  if (draggedShape != null) draggedShape.isDragging = true;
}

void mouseReleased() {
  if (draggedShape != null) {
    draggedShape.isDragging = false;
    
    if (!draggedShape.isControlNode) {
      // 1. LÓGICA DE FUSIÓN: Triángulos con Triángulos / Cuadrados con Cuadrados
      Shape closest = null;
      float minDist = connectionDist;
      
      for (Shape s : shapes) {
        if (s != draggedShape && s.type == draggedShape.type && !s.isControlNode) {
          float d = dist(draggedShape.pos.x, draggedShape.pos.y, s.pos.x, s.pos.y);
          if (d < minDist) {
            minDist = d;
            closest = s;
          }
        }
      }
      
      if (closest != null) {
        if (!draggedShape.isGrouped && !closest.isGrouped) {
          // Crear un grupo nuevo de 2 figuras
          int id = nextGroupID++;
          draggedShape.isGrouped = closest.isGrouped = true;
          draggedShape.groupID = closest.groupID = id;
          
          draggedShape.targetColor = closest.targetColor = (draggedShape.type == 0) ? colTriangleActive : colSquareActive;
          
          // NACE EL CÍRCULO (Control Node)
          PVector avg = new PVector((draggedShape.pos.x + closest.pos.x) / 2, (draggedShape.pos.y + closest.pos.y) / 2);
          Shape control = new Shape(2, avg.x, avg.y);
          control.isControlNode = true;
          control.linkedGroupID = id;
          control.targetColor = colCircleActive;
          control.vel = PVector.random2D().mult(0.5f);
          shapes.add(control);
          
          createExplosion(avg.x, avg.y, colCircleActive, 30);
          
        } else if (closest.isGrouped && !draggedShape.isGrouped) {
          // La figura suelta se une al grupo existente
          draggedShape.isGrouped = true;
          draggedShape.groupID = closest.groupID;
          draggedShape.targetColor = closest.targetColor;
          createExplosion(draggedShape.pos.x, draggedShape.pos.y, closest.targetColor, 15);
          
        } else if (draggedShape.isGrouped && !closest.isGrouped) {
          // La figura objetivo se une al grupo de la que arrastramos
          closest.isGrouped = true;
          closest.groupID = draggedShape.groupID;
          closest.targetColor = draggedShape.targetColor;
          createExplosion(closest.pos.x, closest.pos.y, draggedShape.targetColor, 15);
          
        } else if (draggedShape.isGrouped && closest.isGrouped && draggedShape.groupID != closest.groupID) {
          // Fusionar dos grupos del mismo tipo en uno solo masivo
          int targetId = closest.groupID;
          int oldId = draggedShape.groupID;
          for (Shape s : shapes) {
            if (s.groupID == oldId) s.groupID = targetId;
          }
          // Destruimos el círculo de control sobrante
          for (int i = shapes.size() - 1; i >= 0; i--) {
            Shape s = shapes.get(i);
            if (s.isControlNode && s.linkedGroupID == oldId) {
              superRingCircles.remove(s);
              shapes.remove(i);
              createExplosion(s.pos.x, s.pos.y, color(255), 20);
            }
          }
        }
      }
      
    } else {
      // 2. LÓGICA DEL SÚPER ARO: Juntar Círculos
      for (Shape s : shapes) {
        if (s != draggedShape && s.isControlNode) {
          if (dist(draggedShape.pos.x, draggedShape.pos.y, s.pos.x, s.pos.y) < connectionDist * 1.5f) {
            if (!superRingCircles.contains(draggedShape)) superRingCircles.add(draggedShape);
            if (!superRingCircles.contains(s)) superRingCircles.add(s);
            createExplosion(draggedShape.pos.x, draggedShape.pos.y, color(255), 40);
          }
        }
      }
    }
    draggedShape = null;
  }
}

// Rayos estéticos 
void drawLightning(PVector p1, PVector p2, float intensity) {
  stroke(255, 255, 255, 150 * intensity);
  strokeWeight(2.0f * intensity);
  int steps = 8;
  PVector prevPoint = p1.copy();
  for (int k = 1; k <= steps; k++) {
    float tVal = (float) k / steps;
    PVector interp = new PVector(lerp(p1.x, p2.x, tVal), lerp(p1.y, p2.y, tVal));
    if (k < steps) {
      interp.x += random(-10, 10) * intensity;
      interp.y += random(-10, 10) * intensity;
    }
    line(prevPoint.x, prevPoint.y, interp.x, interp.y);
    prevPoint = interp.copy();
  }
}

void createExplosion(float x, float y, int c, int count) {
  for (int i = 0; i < count; i++) {
    particles.add(new Particle(x, y, c));
  }
}

// ==========================================
// CLASES
// ==========================================
class Shape {
  int type; // 0: Triángulo, 1: Cuadrado, 2: Círculo (Control)
  PVector pos;
  PVector targetPos;
  PVector vel;
  
  int groupID = -1; 
  int linkedGroupID = -1; // Para saber a qué grupo manda este círculo
  
  float size = 30.0f;
  float angle;
  
  boolean isDragging = false;
  boolean isGrouped = false;
  boolean isControlNode = false; 
  
  int currentColor;
  int targetColor;
  int idleColor = color(100, 105, 115);
  
  Shape(int t, float x, float y) {
    this.type = t;
    this.pos = new PVector(x, y);
    this.targetPos = new PVector(x, y);
    this.vel = PVector.random2D().mult(random(0.2f, 0.6f));
    this.angle = random(TWO_PI);
    this.currentColor = idleColor;
    this.targetColor = idleColor;
  }
  
  void updatePhysics() {
    if (isDragging) {
      float dx = mouseX - pmouseX;
      float dy = mouseY - pmouseY;
      
      if (isGrouped || isControlNode) {
        // Al arrastrar una figura, movemos A TODO EL GRUPO unido a ella
        int targetGroup = isControlNode ? linkedGroupID : groupID;
        
        // Si arrancamos un círculo del aro central, lo sacamos del Súper Aro
        if (isControlNode && superRingCircles.contains(this)) {
          superRingCircles.remove(this);
        }
        
        for (Shape s : shapes) {
          if ((s.groupID == targetGroup && targetGroup != -1) || 
              (s.isControlNode && s.linkedGroupID == targetGroup)) {
            s.pos.x += dx;
            s.pos.y += dy;
            s.vel.set(0, 0);
          }
        }
      } else {
        // Si está completamente libre
        pos.x += dx;
        pos.y += dy;
        vel.set(0, 0);
      }
    } else if (!isGrouped && !isControlNode) {
      // Figuras sueltas flotan inertes por la pantalla
      pos.add(vel);
      if (pos.x < 30 || pos.x > width - 30) vel.x *= -1;
      if (pos.y < 30 || pos.y > height - 30) vel.y *= -1;
      pos.x = constrain(pos.x, 30, width - 30);
      pos.y = constrain(pos.y, 30, height - 30);
      
    } else if (isControlNode && !superRingCircles.contains(this)) {
      // Los círculos sueltos (con sus grupos detrás) flotan sutilmente
      pos.add(vel);
      if (pos.x < 50 || pos.x > width - 50) vel.x *= -1;
      if (pos.y < 50 || pos.y > height - 50) vel.y *= -1;
      pos.x = constrain(pos.x, 50, width - 50);
      pos.y = constrain(pos.y, 50, height - 50);
    }
  }
  
  void updatePosition() {
    // Fuerzas magnéticas orbitales (se adhieren a sus objetivos calculados en el Draw)
    if ((isGrouped && !isDragging) || (isControlNode && superRingCircles.contains(this) && !isDragging)) {
      pos.x = lerp(pos.x, targetPos.x, snapSpeed);
      pos.y = lerp(pos.y, targetPos.y, snapSpeed);
    }
    
    currentColor = lerpColor(currentColor, targetColor, 0.1f);
    angle += 0.005f;
  }
  
  void display() {
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(angle);
    
    float pulseScale = 1.0f;
    if (isGrouped || isControlNode) {
      pulseScale += globalGlow * 0.35f;
      stroke(currentColor, 200 + 55 * globalGlow);
      strokeWeight(2.5f + 3.0f * globalGlow);
      fill(currentColor, 30 + 90 * globalGlow);
    } else {
      stroke(currentColor, 110);
      strokeWeight(1.5f);
      noFill();
    }
    
    if (type == 0) {
      float r = (size * 0.6f) * pulseScale;
      beginShape();
      for (int i = 0; i < 3; i++) {
        float a = i * TWO_PI / 3.0f - HALF_PI;
        vertex(cos(a) * r, sin(a) * r);
      }
      endShape(CLOSE);
    } else if (type == 1) {
      float finalSize = (size * 0.9f) * pulseScale;
      rect(0, 0, finalSize, finalSize);
    } else if (type == 2) {
      float finalSize = (size * 0.95f) * pulseScale;
      ellipse(0, 0, finalSize, finalSize);
      
      // Dibujo especial interior para indicar que es un Nodo de Control
      fill(255, 100);
      noStroke();
      ellipse(0, 0, finalSize * 0.3f, finalSize * 0.3f);
    }
    popMatrix();
  }
}

class Particle {
  float x, y;
  float vx, vy;
  float size;
  float alpha;
  int col;
  
  Particle(float nx, float ny, int c) {
    x = nx;
    y = ny;
    vx = random(-4, 4);
    vy = random(-4, 4);
    size = random(2.5f, 7.0f);
    alpha = 255;
    col = c;
  }
  
  void update() {
    x += vx;
    y += vy;
    alpha -= 5.0f; 
  }
  
  void display() {
    noStroke();
    fill(col, alpha);
    ellipse(x, y, size, size);
  }
}
