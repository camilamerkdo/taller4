/*


 * OBRA DE ARTE GENERATIVO: "Sinergias Colectivas" (Emergencia y Cooperación Geométrica)
 * - Arrastra las figuras para agruparlas.
 * - 4 Triángulos se unen para formar un gran triángulo estable y giratorio (Rosa pastel).
 * - 2 Cuadrados + 1 Círculo se alinean para proyectar un faro de iluminación mística (Cian/Verde pastel).
 * - Juntar dos grupos cargados aumenta el brillo global de la pantalla y genera arcos de energía.

ArrayList<Shape> shapes;
ArrayList<Particle> particles;
Shape draggedShape = null;

// Configuración de interacción y distancias de acoplamiento
float connectionDist = 100.0f; // Distancia para empezar a formar grupo
float snapSpeed = 0.15f;       // Velocidad del acoplamiento magnético
float globalGlow = 0.0f;       // Brillo extra del fondo por cooperación

// Colores de los estados activos
int colTriangleActive;
int colSquareActive;
int colCircleActive;

void setup() {
  size(900, 700);
  smooth(8);
  rectMode(CENTER);
  
  shapes = new ArrayList<Shape>();
  particles = new ArrayList<Particle>();
  
  // Inicialización de colores pastel para estados de sinergia
  colTriangleActive = color(255, 183, 178); // Rosa pastel
  colSquareActive = color(199, 206, 234);   // Azul pastel
  colCircleActive = color(175, 228, 222);   // Cian/Verde pastel
  
  // Instanciar figuras flotantes iniciales de forma equilibrada
  // Necesitamos múltiplos para que el usuario pueda formar varias combinaciones
  for (int i = 0; i < 8; i++) {
    shapes.add(new Shape(0, random(100, width-100), random(100, height-100))); // Triángulos
  }
  for (int i = 0; i < 6; i++) {
    shapes.add(new Shape(1, random(100, width-100), random(100, height-100))); // Cuadrados
  }
  for (int i = 0; i < 4; i++) {
    shapes.add(new Shape(2, random(100, width-100), random(100, height-100))); // Círculos
  }
}

void draw() {
  // El fondo reacciona dinámicamente iluminándose más cuando hay cooperación entre grupos
  int bgBase = color(5, 4, 9);
  int bgResonant = color(15, 12, 28);
  background(lerpColor(bgBase, bgResonant, globalGlow));
  
  // Actualizar posiciones físicas (flotación inerte cuando no están agrupados)
  for (Shape s : shapes) {
    s.updatePhysics();
  }
  
  // Buscar agrupaciones por proximidad utilizando un algoritmo de Componentes Conectados (DFS)
  ArrayList<ArrayList<Shape>> clusters = findClusters();
  
  // Resetear estados activos antes de evaluar las agrupaciones de este fotograma
  for (Shape s : shapes) {
    s.resetGroupState();
  }
  
  // Analizar cada cluster para verificar si cumple las recetas de cooperación
  ArrayList<PVector> activeGroupCentroids = new ArrayList<PVector>();
  float totalResonance = 0.0f;
  
  for (ArrayList<Shape> cluster : clusters) {
    int triangles = 0;
    int squares = 0;
    int circles = 0;
    PVector centroid = new PVector(0, 0);
    
    for (Shape s : cluster) {
      centroid.add(s.pos);
      if (s.type == 0) triangles++;
      else if (s.type == 1) squares++;
      else if (s.type == 2) circles++;
    }
    centroid.div(cluster.size());
    
    // CASO A: Composición Estable (Exactamente 4 Triángulos)
    if (triangles == 4 && cluster.size() == 4) {
      activeGroupCentroids.add(centroid);
      totalResonance += 1.0f;
      
      // Ángulo de rotación del grupo para dar dinamismo orbital
      float groupAngle = frameCount * 0.015f;
      float radius = 45.0f;
      
      // Asignar posiciones geométricas de acoplamiento magnético
      // 3 en los vértices de un triángulo equilátero exterior, 1 en el baricentro (centro)
      int tIndex = 0;
      for (Shape s : cluster) {
        s.isGrouped = true;
        s.targetColor = colTriangleActive;
        
        if (tIndex < 3) {
          float angleOffset = tIndex * TWO_PI / 3.0f + groupAngle;
          s.targetPos.set(centroid.x + cos(angleOffset) * radius, centroid.y + sin(angleOffset) * radius);
        } else {
          s.targetPos.set(centroid.x, centroid.y);
        }
        tIndex++;
      }
      
      // Efectos visuales de enlace del tetraedro
      stroke(colTriangleActive, 40);
      strokeWeight(2);
      noFill();
      beginShape();
      for (int k = 0; k < 3; k++) {
        float angleOffset = k * TWO_PI / 3.0f + groupAngle;
        vertex(centroid.x + cos(angleOffset) * radius, centroid.y + sin(angleOffset) * radius);
      }
      endShape(CLOSE);
    }
    
    // CASO B: Generador de Iluminación (Exactamente 2 Cuadrados y 1 Círculo)
    else if (squares == 2 && circles == 1 && cluster.size() == 3) {
      activeGroupCentroids.add(centroid);
      totalResonance += 1.2f;
      
      float alignAngle = frameCount * 0.01f; // Rotación lenta de la alineación
      float spacing = 50.0f;
      
      int sqIndex = 0;
      for (Shape s : cluster) {
        s.isGrouped = true;
        
        if (s.type == 2) {
          // El círculo toma el centro de la alineación óptico-geométrica
          s.targetPos.set(centroid.x, centroid.y);
          s.targetColor = colCircleActive;
        } else if (s.type == 1) {
          // Los cuadrados se sitúan en extremos opuestos del círculo
          float sign = (sqIndex == 0) ? 1.0f : -1.0f;
          s.targetPos.set(centroid.x + cos(alignAngle) * spacing * sign, centroid.y + sin(alignAngle) * spacing * sign);
          s.targetColor = colSquareActive;
          sqIndex++;
        }
      }
      
      // Dibujar haz de luz o lentes de conexión iluminada
      stroke(colCircleActive, 45);
      strokeWeight(3);
      line(centroid.x - cos(alignAngle) * spacing * 1.5f, centroid.y - sin(alignAngle) * spacing * 1.5f,
           centroid.x + cos(alignAngle) * spacing * 1.5f, centroid.y + sin(alignAngle) * spacing * 1.5f);
           
      // Onda expansiva de luz sutil
      noFill();
      stroke(colCircleActive, 30 * (1.0f - (frameCount % 60)/60.0f));
      ellipse(centroid.x, centroid.y, (frameCount % 60) * 2.5f, (frameCount % 60) * 2.5f);
    }
    
    // Si el grupo no cumple ninguna combinación cooperativa, se dibujan enlaces tenues
    else if (cluster.size() > 1) {
      stroke(255, 255, 255, 8);
      strokeWeight(1);
      for (int i = 0; i < cluster.size(); i++) {
        for (int j = i + 1; j < cluster.size(); j++) {
          line(cluster.get(i).pos.x, cluster.get(i).pos.y, cluster.get(j).pos.x, cluster.get(j).pos.y);
        }
      }
    }
  }
  
  // PREMIO A LA COOPERACIÓN MULTI-GRUPO (Resonancia Global)
  // Si hay más de un grupo especial activo, y están relativamente cerca, se genera un arco voltaico
  float resonanceDistanceLimit = 220.0f;
  float extraGlowTarget = 0.0f;
  
  if (activeGroupCentroids.size() >= 2) {
    for (int i = 0; i < activeGroupCentroids.size(); i++) {
      for (int j = i + 1; j < activeGroupCentroids.size(); j++) {
        PVector c1 = activeGroupCentroids.get(i);
        PVector c2 = activeGroupCentroids.get(j);
        float d = c1.dist(c2);
        
        if (d < resonanceDistanceLimit) {
          // Incrementar energía global
          float intensity = map(d, 0, resonanceDistanceLimit, 1.0f, 0.1f);
          extraGlowTarget += intensity * 0.4f;
          
          // Dibujar líneas eléctricas/puentes de luz de alta frecuencia entre centros de poder
          stroke(255, 255, 255, 90 * intensity);
          strokeWeight(2.0f * intensity);
          
          // Generar arco con vaivén eléctrico orgánico
          float steps = 8;
          PVector prevPoint = c1.copy();
          for (int k = 1; k <= steps; k++) {
            float tVal = (float) k / steps;
            PVector interp = PVector.lerp(c1, c2, tVal);
            if (k < steps) {
              interp.x += random(-8, 8) * intensity;
              interp.y += random(-8, 8) * intensity;
            }
            line(prevPoint.x, prevPoint.y, interp.x, interp.y);
            prevPoint = interp.copy();
          }
          
          // Emitir ráfagas de chispas ambientales
          if (frameCount % 4 == 0) {
            PVector spawnPos = PVector.lerp(c1, c2, random(0, 1));
            particles.add(new Particle(spawnPos.x, spawnPos.y, lerpColor(colTriangleActive, colCircleActive, random(0,1))));
          }
        }
      }
    }
  }
  
  // Suavizar la transición del brillo global de fondo
  globalGlow = lerp(globalGlow, min(0.6f, extraGlowTarget), 0.1f);
  
  // Dibujar y actualizar todas las figuras geométricas
  for (Shape s : shapes) {
    s.updatePosition();
    s.display();
  }
  
  // Dibujar y actualizar partículas
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.display();
    if (p.alpha <= 0) {
      particles.remove(i);
    }
  }
}

// Algoritmo DFS (Depth-First Search) para clasificar figuras por proximidad espacial
ArrayList<ArrayList<Shape>> findClusters() {
  ArrayList<ArrayList<Shape>> clusters = new ArrayList<ArrayList<Shape>>();
  boolean[] visited = new boolean[shapes.size()];
  
  for (int i = 0; i < shapes.size(); i++) {
    if (!visited[i]) {
      ArrayList<Shape> cluster = new ArrayList<Shape>();
      dfs(i, visited, cluster);
      clusters.add(cluster);
    }
  }
  return clusters;
}

void dfs(int index, boolean[] visited, ArrayList<Shape> cluster) {
  visited[index] = true;
  Shape current = shapes.get(index);
  cluster.add(current);
  
  for (int i = 0; i < shapes.size(); i++) {
    if (!visited[i]) {
      Shape other = shapes.get(i);
      
      // Si la distancia es menor a connectionDist, pertenecen al mismo núcleo interactivo
      if (current.pos.dist(other.pos) < connectionDist) {
        dfs(i, visited, cluster);
      }
    }
  }
}

// Eventos del Mouse para el Drag and Drop de figuras físicas
void mousePressed() {
  // Buscar qué figura se clickeó, priorizando la más cercana
  float minDist = 30.0f; // Radio de agarre cómodo
  for (Shape s : shapes) {
    float d = dist(mouseX, mouseY, s.pos.x, s.pos.y);
    if (d < minDist) {
      minDist = d;
      draggedShape = s;
    }
  }
  if (draggedShape != null) {
    draggedShape.isDragging = true;
  }
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

class Shape {
  int type; // 0: Triángulo, 1: Cuadrado, 2: Círculo
  PVector pos;
  PVector targetPos;
  PVector vel;
  
  float size = 30.0f;
  float angle;
  float floatSeed;
  
  boolean isDragging = false;
  boolean isGrouped = false;
  
  int currentColor;
  int targetColor;
  int idleColor = color(100, 105, 115); // Monocromo inactivo de reposo
  
  Shape(int t, float x, float y) {
    this.type = t;
    this.pos = new PVector(x, y);
    this.targetPos = new PVector(x, y);
    this.vel = PVector.random2D().mult(random(0.2f, 0.6f)); // Flotación inercial lenta
    this.angle = random(TWO_PI);
    this.floatSeed = random(1000);
    this.currentColor = idleColor;
    this.targetColor = idleColor;
  }
  
  void resetGroupState() {
    this.isGrouped = false;
    this.targetColor = idleColor;
  }
  
  void updatePhysics() {
    if (isDragging) {
      // Seguir suavemente el cursor
      pos.x = lerp(pos.x, mouseX, 0.35f);
      pos.y = lerp(pos.y, mouseY, 0.35f);
      vel.set(0, 0);
    } else if (!isGrouped) {
      // Flotación senoidal inerte cuando está solo en el plano
      pos.add(vel);
      pos.x += sin(frameCount * 0.015f + floatSeed) * 0.15f;
      pos.y += cos(frameCount * 0.015f + floatSeed) * 0.15f;
      
      // Rebote físico elástico en los bordes de la pantalla
      if (pos.x < 50 || pos.x > width - 50) vel.x *= -1;
      if (pos.y < 50 || pos.y > height - 50) vel.y *= -1;
      
      // Limitar posición para que no salgan de la vista
      pos.x = constrain(pos.x, 30, width - 30);
      pos.y = constrain(pos.y, 30, height - 30);
    }
  }
  
  void updatePosition() {
    // Si la figura está en un grupo activo, se acopla magnéticamente al target calculado
    if (isGrouped && !isDragging) {
      pos.x = lerp(pos.x, targetPos.x, snapSpeed);
      pos.y = lerp(pos.y, targetPos.y, snapSpeed);
    }
    
    // Transición de color suave para la activación de sinergia
    currentColor = lerpColor(currentColor, targetColor, 0.1f);
    
    // Rotación lenta decorativa
    angle += 0.005f;
  }
  
  void display() {
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(angle);
    
    // Cambiar grosor y visibilidad del borde según su estado de activación
    if (isGrouped) {
      stroke(currentColor, 180);
      strokeWeight(2.5f);
      fill(currentColor, 30); // Relleno translúcido para dar volumen lumínico
    } else {
      stroke(currentColor, 110);
      strokeWeight(1.5f);
      noFill();
    }
    
    // Dibujo geométrico limpio de las 3 entidades fundamentales
    if (type == 0) {
      // Triángulo Equilátero
      float r = size * 0.6f;
      beginShape();
      for (int i = 0; i < 3; i++) {
        float a = i * TWO_PI / 3.0f - HALF_PI;
        vertex(cos(a) * r, sin(a) * r);
      }
      endShape(CLOSE);
    } 
    else if (type == 1) {
      // Cuadrado
      rect(0, 0, size * 0.9f, size * 0.9f);
    } 
    else if (type == 2) {
      // Círculo
      ellipse(0, 0, size * 0.95f, size * 0.95f);
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
    vx = random(-2, 2);
    vy = random(-2, 2);
    size = random(2, 5);
    alpha = 255;
    col = c;
  }
  
  void update() {
    x += vx;
    y += vy;
    alpha -= 4.0f; // Desvanecimiento gradual
  }
  
  void display() {
    noStroke();
    fill(col, alpha);
    ellipse(x, y, size, size);
  }
}

*/

/*
 * OBRA DE ARTE GENERATIVO: "Sinergias Colectivas" (Emergencia y Cooperación Geométrica)
 * - Arrastra las figuras para agruparlas.
 * - 4 Triángulos se unen para formar un gran triángulo estable y giratorio (Rosa pastel).
 * - 2 Cuadrados + 1 Círculo se alinean para proyectar un faro de iluminación mística (Cian/Verde pastel).
 * - Una vez formados, los conjuntos se bloquean permanentemente y se mueven en bloque.
 * - Juntar o superponer grupos cargados multiplica el brillo, expande las figuras y genera arcos de energía.
 */

ArrayList<Shape> shapes;
ArrayList<Particle> particles;
Shape draggedShape = null;

// Configuración de interacción y distancias de acoplamiento
float connectionDist = 100.0f; // Distancia para empezar a formar grupo
float snapSpeed = 0.15f;       // Velocidad del acoplamiento magnético
float globalGlow = 0.0f;       // Brillo extra del fondo por cooperación
int nextGroupID = 0;           // Generador de IDs únicos para grupos bloqueados

// Colores de los estados activos
int colTriangleActive;
int colSquareActive;
int colCircleActive;

void setup() {
  size(900, 700);
  smooth(8);
  rectMode(CENTER);
  
  shapes = new ArrayList<Shape>();
  particles = new ArrayList<Particle>();
  
  // Inicialización de colores pastel para estados de sinergia
  colTriangleActive = color(255, 183, 178); // Rosa pastel
  colSquareActive = color(199, 206, 234);   // Azul pastel
  colCircleActive = color(175, 228, 222);   // Cian/Verde pastel
  
  // Instanciar figuras flotantes iniciales de forma equilibrada
  for (int i = 0; i < 8; i++) {
    shapes.add(new Shape(0, random(100, width-100), random(100, height-100))); // Triángulos
  }
  for (int i = 0; i < 6; i++) {
    shapes.add(new Shape(1, random(100, width-100), random(100, height-100))); // Cuadrados
  }
  for (int i = 0; i < 4; i++) {
    shapes.add(new Shape(2, random(100, width-100), random(100, height-100))); // Círculos
  }
}

void draw() {
  // El fondo reacciona dinámicamente iluminándose más cuando hay cooperación estrecha entre grupos
  int bgBase = color(5, 4, 9);
  int bgResonant = color(22, 15, 38);
  background(lerpColor(bgBase, bgResonant, globalGlow));
  
  // Actualizar posiciones físicas (flotación inerte cuando no están agrupados)
  for (Shape s : shapes) {
    s.updatePhysics();
  }
  
  // Buscar agrupaciones utilizando un DFS adaptado a IDs fijos y proximidad libre
  ArrayList<ArrayList<Shape>> clusters = findClusters();
  
  // Resetear estados activos solo de las figuras no bloqueadas
  for (Shape s : shapes) {
    s.resetGroupState();
  }
  
  // Analizar cada cluster para verificar si cumple las recetas de cooperación o mantener grupos existentes
  ArrayList<PVector> activeGroupCentroids = new ArrayList<PVector>();
  
  for (ArrayList<Shape> cluster : clusters) {
    int triangles = 0;
    int squares = 0;
    int circles = 0;
    PVector centroid = new PVector(0, 0);
    
    for (Shape s : cluster) {
      centroid.add(s.pos);
      if (s.type == 0) triangles++;
      else if (s.type == 1) squares++;
      else if (s.type == 2) circles++;
    }
    centroid.div(cluster.size());
    
    // CASO A: Composición Estable (Exactamente 4 Triángulos)
    if (triangles == 4 && cluster.size() == 4) {
      activeGroupCentroids.add(centroid);
      
      // Bloquear grupo de forma permanente asignando un ID común
      int idToUse = -1;
      for (Shape s : cluster) {
        if (s.groupID >= 0) {
          idToUse = s.groupID;
          break;
        }
      }
      if (idToUse == -1) {
        idToUse = nextGroupID++;
        createExplosion(centroid.x, centroid.y, colTriangleActive, 30);
      }
      
      // Ángulo de rotación del grupo para dar dinamismo orbital
      float groupAngle = frameCount * 0.015f;
      float radius = 45.0f;
      
      int tIndex = 0;
      for (Shape s : cluster) {
        s.isGrouped = true;
        s.groupID = idToUse;
        s.targetColor = colTriangleActive;
        
        if (tIndex < 3) {
          float angleOffset = tIndex * TWO_PI / 3.0f + groupAngle;
          s.targetPos.set(centroid.x + cos(angleOffset) * radius, centroid.y + sin(angleOffset) * radius);
        } else {
          s.targetPos.set(centroid.x, centroid.y);
        }
        tIndex++;
      }
      
      // Enlaces visuales del gran triángulo
      stroke(colTriangleActive, 50 + 100 * globalGlow);
      strokeWeight(2 + 2 * globalGlow);
      noFill();
      beginShape();
      for (int k = 0; k < 3; k++) {
        float angleOffset = k * TWO_PI / 3.0f + groupAngle;
        vertex(centroid.x + cos(angleOffset) * radius, centroid.y + sin(angleOffset) * radius);
      }
      endShape(CLOSE);
    }
    
    // CASO B: Generador de Iluminación (Exactamente 2 Cuadrados y 1 Círculo)
    else if (squares == 2 && circles == 1 && cluster.size() == 3) {
      activeGroupCentroids.add(centroid);
      
      // Bloquear grupo de forma permanente asignando un ID común
      int idToUse = -1;
      for (Shape s : cluster) {
        if (s.groupID >= 0) {
          idToUse = s.groupID;
          break;
        }
      }
      if (idToUse == -1) {
        idToUse = nextGroupID++;
        createExplosion(centroid.x, centroid.y, colCircleActive, 30);
      }
      
      float alignAngle = frameCount * 0.01f; // Rotación lenta de la alineación
      float spacing = 50.0f;
      
      int sqIndex = 0;
      for (Shape s : cluster) {
        s.isGrouped = true;
        s.groupID = idToUse;
        
        if (s.type == 2) {
          s.targetPos.set(centroid.x, centroid.y);
          s.targetColor = colCircleActive;
        } else if (s.type == 1) {
          float sign = (sqIndex == 0) ? 1.0f : -1.0f;
          s.targetPos.set(centroid.x + cos(alignAngle) * spacing * sign, centroid.y + sin(alignAngle) * spacing * sign);
          s.targetColor = colSquareActive;
          sqIndex++;
        }
      }
      
      // Dibujar haz de luz central de alta intensidad
      stroke(colCircleActive, 60 + 100 * globalGlow);
      strokeWeight(3 + 3 * globalGlow);
      line(centroid.x - cos(alignAngle) * spacing * 1.5f, centroid.y - sin(alignAngle) * spacing * 1.5f,
           centroid.x + cos(alignAngle) * spacing * 1.5f, centroid.y + sin(alignAngle) * spacing * 1.5f);
           
      // Onda expansiva de luz sutil
      noFill();
      stroke(colCircleActive, 40 * (1.0f - (frameCount % 60)/60.0f));
      ellipse(centroid.x, centroid.y, (frameCount % 60) * 2.5f, (frameCount % 60) * 2.5f);
    }
    
    // Si el grupo es temporal y no cumple ninguna combinación, se enlazan de forma básica
    else if (cluster.size() > 1) {
      stroke(255, 255, 255, 8);
      strokeWeight(1);
      for (int i = 0; i < cluster.size(); i++) {
        for (int j = i + 1; j < cluster.size(); j++) {
          line(cluster.get(i).pos.x, cluster.get(i).pos.y, cluster.get(j).pos.x, cluster.get(j).pos.y);
        }
      }
    }
  }
  
  // RESONANCIA CRÍTICA Y SÚPER GLOW POR PROXIMIDAD DE GRUPOS ESTABLES
  float resonanceDistanceLimit = 250.0f;
  float extraGlowTarget = 0.0f;
  
  if (activeGroupCentroids.size() >= 2) {
    for (int i = 0; i < activeGroupCentroids.size(); i++) {
      for (int j = i + 1; j < activeGroupCentroids.size(); j++) {
        PVector c1 = activeGroupCentroids.get(i);
        PVector c2 = activeGroupCentroids.get(j);
        float d = c1.dist(c2);
        
        if (d < resonanceDistanceLimit) {
          // La intensidad escala de manera exponencial a menor distancia (superposición)
          float intensity = map(d, 0, resonanceDistanceLimit, 1.0f, 0.0f);
          intensity = pow(intensity, 1.5f); // Curva más dramática
          extraGlowTarget += intensity * 0.8f;
          
          // Ondas de choque circulares interactivas
          noFill();
          stroke(255, 255, 255, 80 * intensity);
          strokeWeight(1.0f + 4.0f * intensity);
          float ringSize = 60 + 50 * sin(frameCount * 0.1f);
          ellipse(c1.x, c1.y, ringSize, ringSize);
          ellipse(c2.x, c2.y, ringSize, ringSize);
          
          // Dibujar líneas eléctricas vibrantes entre centros de poder
          stroke(255, 255, 255, 120 * intensity);
          strokeWeight(2.5f * intensity);
          
          float steps = 10;
          PVector prevPoint = c1.copy();
          for (int k = 1; k <= steps; k++) {
            float tVal = (float) k / steps;
            
            // CORRECCIÓN: Reemplazado PVector.lerp estático por interpolación segura nativa
            PVector interp = new PVector(
              lerp(c1.x, c2.x, tVal),
              lerp(c1.y, c2.y, tVal)
            );
            
            if (k < steps) {
              interp.x += random(-12, 12) * intensity;
              interp.y += random(-12, 12) * intensity;
            }
            line(prevPoint.x, prevPoint.y, interp.x, interp.y);
            prevPoint = interp.copy();
          }
          
          // Si están sumamente superpuestos, generar una fusión de plasma de alta energía
          if (d < 100.0f) {
            PVector midpoint = PVector.lerp(c1, c2, 0.5f);
            stroke(255, 255, 255, 200);
            strokeWeight(4);
            ellipse(midpoint.x, midpoint.y, 110 - d, 110 - d);
            
            // Explosión continua de partículas fusionadas
            if (frameCount % 2 == 0) {
              int blendedCol = lerpColor(colTriangleActive, colCircleActive, sin(frameCount * 0.05f) * 0.5f + 0.5f);
              
              // CORRECCIÓN: Reemplazado PVector.lerp estático por interpolación segura nativa
              float tRand = random(0, 1);
              PVector spawnPos = new PVector(
                lerp(c1.x, c2.x, tRand) + random(-15, 15),
                lerp(c1.y, c2.y, tRand) + random(-15, 15)
              );
              
              particles.add(new Particle(spawnPos.x, spawnPos.y, blendedCol));
            }
          }
        }
      }
    }
  }
  
  // Suavizar la transición del brillo global de fondo
  globalGlow = lerp(globalGlow, min(0.85f, extraGlowTarget), 0.08f);
  
  // Dibujar y actualizar todas las figuras geométricas
  for (Shape s : shapes) {
    s.updatePosition();
    s.display();
  }
  
  // Dibujar y actualizar partículas
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.display();
    if (p.alpha <= 0) {
      particles.remove(i);
    }
  }
}

// Algoritmo DFS adaptado para respetar clusters ya unidos por ID
ArrayList<ArrayList<Shape>> findClusters() {
  ArrayList<ArrayList<Shape>> clusters = new ArrayList<ArrayList<Shape>>();
  boolean[] visited = new boolean[shapes.size()];
  
  for (int i = 0; i < shapes.size(); i++) {
    if (!visited[i]) {
      ArrayList<Shape> cluster = new ArrayList<Shape>();
      dfs(i, visited, cluster);
      clusters.add(cluster);
    }
  }
  return clusters;
}

void dfs(int index, boolean[] visited, ArrayList<Shape> cluster) {
  visited[index] = true;
  Shape current = shapes.get(index);
  cluster.add(current);
  
  for (int i = 0; i < shapes.size(); i++) {
    if (!visited[i]) {
      Shape other = shapes.get(i);
      
      if (current.groupID >= 0) {
        // Figuras bloqueadas solo pueden agruparse con miembros de su MISMO grupo
        if (other.groupID == current.groupID) {
          dfs(i, visited, cluster);
        }
      } else {
        // Figuras libres se agrupan por distancia con otras figuras libres
        if (other.groupID == -1 && current.pos.dist(other.pos) < connectionDist) {
          dfs(i, visited, cluster);
        }
      }
    }
  }
}

// Eventos del Mouse para el Drag and Drop de figuras físicas
void mousePressed() {
  float minDist = 35.0f; // Margen cómodo para arrastrar
  for (Shape s : shapes) {
    float d = dist(mouseX, mouseY, s.pos.x, s.pos.y);
    if (d < minDist) {
      minDist = d;
      draggedShape = s;
    }
  }
  if (draggedShape != null) {
    draggedShape.isDragging = true;
  }
}

void mouseReleased() {
  if (draggedShape != null) {
    draggedShape.isDragging = false;
    draggedShape = null;
  }
}

// Función encargada de instanciar ráfagas de chispas en el Canvas
void createExplosion(float x, float y, int c, int count) {
  for (int i = 0; i < count; i++) {
    particles.add(new Particle(x, y, c));
  }
}

// ==========================================
// CLASES COMPLEMENTARIAS
// ==========================================

class Shape {
  int type; // 0: Triángulo, 1: Cuadrado, 2: Círculo
  PVector pos;
  PVector targetPos;
  PVector vel;
  int groupID = -1; // -1 indica figura libre
  
  float size = 30.0f;
  float angle;
  float floatSeed;
  
  boolean isDragging = false;
  boolean isGrouped = false;
  
  int currentColor;
  int targetColor;
  int idleColor = color(100, 105, 115); // Monocromo inactivo de reposo
  
  Shape(int t, float x, float y) {
    this.type = t;
    this.pos = new PVector(x, y);
    this.targetPos = new PVector(x, y);
    this.vel = PVector.random2D().mult(random(0.2f, 0.6f)); // Flotación inercial lenta
    this.angle = random(TWO_PI);
    this.floatSeed = random(1000);
    this.currentColor = idleColor;
    this.targetColor = idleColor;
  }
  
  void resetGroupState() {
    if (groupID < 0) {
      this.isGrouped = false;
      this.targetColor = idleColor;
    } else {
      this.isGrouped = true;
      if (type == 0) this.targetColor = colTriangleActive;
      else if (type == 1) this.targetColor = colSquareActive;
      else if (type == 2) this.targetColor = colCircleActive;
    }
  }
  
  void updatePhysics() {
    if (isDragging) {
      if (groupID >= 0) {
        // DRAG COLECTIVO: Mover todo el grupo completo por el delta del cursor
        float dx = mouseX - pmouseX;
        float dy = mouseY - pmouseY;
        for (Shape s : shapes) {
          if (s.groupID == groupID) {
            s.pos.x += dx;
            s.pos.y += dy;
            s.vel.set(0, 0);
          }
        }
      } else {
        // Drag individual normal
        pos.x = lerp(pos.x, mouseX, 0.35f);
        pos.y = lerp(pos.y, mouseY, 0.35f);
        vel.set(0, 0);
      }
    } else if (!isGrouped) {
      // Flotación senoidal inerte cuando está solo en el plano
      pos.add(vel);
      pos.x += sin(frameCount * 0.015f + floatSeed) * 0.15f;
      pos.y += cos(frameCount * 0.015f + floatSeed) * 0.15f;
      
      // Rebote físico elástico en los bordes de la pantalla
      if (pos.x < 50 || pos.x > width - 50) vel.x *= -1;
      if (pos.y < 50 || pos.y > height - 50) vel.y *= -1;
      
      pos.x = constrain(pos.x, 30, width - 30);
      pos.y = constrain(pos.y, 30, height - 30);
    }
  }
  
  void updatePosition() {
    // Si está agrupado, se acopla magnéticamente al target calculado
    if (isGrouped && !isDragging) {
      pos.x = lerp(pos.x, targetPos.x, snapSpeed);
      pos.y = lerp(pos.y, targetPos.y, snapSpeed);
    }
    
    // Transición de color suave
    currentColor = lerpColor(currentColor, targetColor, 0.1f);
    
    // Rotación lenta decorativa
    angle += 0.005f;
  }
  
  void display() {
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(angle);
    
    // Las figuras crecen de tamaño y se iluminan intensamente durante la resonancia crítica
    float pulseScale = 1.0f;
    if (isGrouped) {
      pulseScale += globalGlow * 0.35f; // Crecen hasta un 35% extra
      stroke(currentColor, 200 + 55 * globalGlow);
      strokeWeight(2.5f + 3.0f * globalGlow);
      fill(currentColor, 30 + 90 * globalGlow); // Relleno translúcido más denso al resonar
    } else {
      stroke(currentColor, 110);
      strokeWeight(1.5f);
      noFill();
    }
    
    // Dibujo geométrico limpio
    if (type == 0) {
      // Triángulo Equilátero
      float r = (size * 0.6f) * pulseScale;
      beginShape();
      for (int i = 0; i < 3; i++) {
        float a = i * TWO_PI / 3.0f - HALF_PI;
        vertex(cos(a) * r, sin(a) * r);
      }
      endShape(CLOSE);
    } 
    else if (type == 1) {
      // Cuadrado
      float finalSize = (size * 0.9f) * pulseScale;
      rect(0, 0, finalSize, finalSize);
    } 
    else if (type == 2) {
      // Círculo
      float finalSize = (size * 0.95f) * pulseScale;
      ellipse(0, 0, finalSize, finalSize);
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
    vx = random(-3, 3);
    vy = random(-3, 3);
    size = random(2.5f, 6.0f);
    alpha = 255;
    col = c;
  }
  
  void update() {
    x += vx;
    y += vy;
    alpha -= 5.0f; // Desvanecimiento gradual rápido
  }
  
  void display() {
    noStroke();
    fill(col, alpha);
    ellipse(x, y, size, size);
  }
}
