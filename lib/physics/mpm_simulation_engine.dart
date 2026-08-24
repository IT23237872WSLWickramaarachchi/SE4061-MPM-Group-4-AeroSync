import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class MPMParticle {
  vm.Vector2 position;
  vm.Vector2 velocity;
  vm.Matrix2 affineB; // APIC affine velocity matrix
  double mass;
  double pressure;
  double life;
  double maxLife;
  Color color;
  int fanSource; // 1, 2, 3 or 0 for ambient

  MPMParticle({
    required this.position,
    required this.velocity,
    vm.Matrix2? affineB,
    this.mass = 1.0,
    this.pressure = 0.0,
    this.life = 1.0,
    this.maxLife = 1.0,
    this.color = const Color(0xFF35DBC7),
    this.fanSource = 0,
  }) : affineB = affineB ?? vm.Matrix2.zero();
}

class MPMGridNode {
  double mass = 0.0;
  vm.Vector2 velocity = vm.Vector2.zero();
  vm.Vector2 force = vm.Vector2.zero();
  double pressure = 0.0;

  void reset() {
    mass = 0.0;
    velocity.setZero();
    force.setZero();
    pressure = 0.0;
  }
}

class MPMWindSimulationEngine {
  static const int gridWidth = 48;
  static const int gridHeight = 28;
  
  final List<MPMParticle> particles = [];
  final List<List<MPMGridNode>> grid = List.generate(
    gridWidth,
    (_) => List.generate(gridHeight, (_) => MPMGridNode()),
  );

  final math.Random _random = math.Random();

  // Telemetry metrics
  double averageVelocity = 0.0;
  double maxVelocity = 0.0;
  double turbulenceIndex = 0.0;
  double totalKineticEnergy = 0.0;

  MPMWindSimulationEngine() {
    _initParticles();
  }

  void _initParticles() {
    particles.clear();
    const int count = 800;
    for (int i = 0; i < count; i++) {
      final x = _random.nextDouble() * gridWidth;
      final y = _random.nextDouble() * gridHeight;
      particles.add(
        MPMParticle(
          position: vm.Vector2(x, y),
          velocity: vm.Vector2(_random.nextDouble() * 2 + 1, (_random.nextDouble() - 0.5) * 0.5),
          life: _random.nextDouble(),
          maxLife: 0.8 + _random.nextDouble() * 0.6,
          color: const Color(0xFF35DBC7).withValues(alpha: 0.4 + _random.nextDouble() * 0.6),
        ),
      );
    }
  }

  /// Step the simulation given dt and active fan speed intensities (0.0 to 1.0)
  void stepSimulation(double dt, double f1Speed, double f2Speed, double f3Speed) {
    if (dt <= 0) return;
    dt = dt.clamp(0.001, 0.033);

    // 1. Reset Grid
    for (int x = 0; x < gridWidth; x++) {
      for (int y = 0; y < gridHeight; y++) {
        grid[x][y].reset();
      }
    }

    // 2. Particle to Grid (P2G Transfer with Quadratic Weights)
    for (final p in particles) {
      final gx = p.position.x.floor().clamp(1, gridWidth - 2);
      final gy = p.position.y.floor().clamp(1, gridHeight - 2);

      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          final nx = gx + i;
          final ny = gy + j;
          if (nx < 0 || nx >= gridWidth || ny < 0 || ny >= gridHeight) continue;

          final dx = p.position.x - nx;
          final dy = p.position.y - ny;

          final wX = _quadraticWeight(dx);
          final wY = _quadraticWeight(dy);
          final weight = wX * wY;

          final node = grid[nx][ny];
          node.mass += weight * p.mass;
          
          final dpos = vm.Vector2(dx, dy);
          final affineContrib = p.affineB.transformed(dpos);
          final weightedVel = (p.velocity - affineContrib) * (weight * p.mass);
          node.velocity.add(weightedVel);
        }
      }
    }

    // 3. Grid Velocity Normalization & Fan Momentum Injections
    for (int x = 0; x < gridWidth; x++) {
      for (int y = 0; y < gridHeight; y++) {
        final node = grid[x][y];
        if (node.mass > 1e-5) {
          node.velocity.scale(1.0 / node.mass);
        }

        // Fan Nozzle Thrust Injections (Left Boundary x <= 6)
        if (x <= 6) {
          // Fan 1: Top nozzle (y: 1 to 9)
          if (y >= 1 && y <= 9 && f1Speed > 0.001) {
            final thrust = f1Speed * 35.0;
            node.velocity.x += thrust * (1.0 - (x / 6.0) * 0.25);
            node.velocity.y += (y - 5.0) * 0.3 * f1Speed;
          }
          // Fan 2: Middle nozzle (y: 10 to 17)
          if (y >= 10 && y <= 17 && f2Speed > 0.001) {
            final thrust = f2Speed * 40.0;
            node.velocity.x += thrust * (1.0 - (x / 6.0) * 0.25);
            node.velocity.y += (y - 13.5) * 0.3 * f2Speed;
          }
          // Fan 3: Bottom nozzle (y: 18 to 26)
          if (y >= 18 && y <= 26 && f3Speed > 0.001) {
            final thrust = f3Speed * 38.0;
            node.velocity.x += thrust * (1.0 - (x / 6.0) * 0.25);
            node.velocity.y += (y - 22.0) * 0.3 * f3Speed;
          }
        }

        // Tunnel Obstacle (Center right boundary: x in 24..34, y in 10..18)
        if (x >= 24 && x <= 34 && y >= 10 && y <= 18) {
          node.velocity.x *= 0.15;
          node.velocity.y -= (14 - y) * 0.8; 
          node.pressure += node.velocity.length * 1.5;
        }

        // Boundary damping
        if (x == 0 || x == gridWidth - 1) node.velocity.x *= 0.1;
        if (y == 0 || y == gridHeight - 1) node.velocity.y *= 0.1;
      }
    }

    // 4. Grid to Particle (G2P) & Particle Advection
    double sumVel = 0.0;
    double maxV = 0.0;
    double kineticSum = 0.0;

    for (final p in particles) {
      final gx = p.position.x.floor().clamp(1, gridWidth - 2);
      final gy = p.position.y.floor().clamp(1, gridHeight - 2);

      vm.Vector2 newVel = vm.Vector2.zero();
      vm.Matrix2 newB = vm.Matrix2.zero();

      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          final nx = gx + i;
          final ny = gy + j;
          if (nx < 0 || nx >= gridWidth || ny < 0 || ny >= gridHeight) continue;

          final dx = p.position.x - nx;
          final dy = p.position.y - ny;

          final weight = _quadraticWeight(dx) * _quadraticWeight(dy);
          final node = grid[nx][ny];

          newVel.add(node.velocity * weight);

          final dpos = vm.Vector2(dx, dy);
          final outerProduct = vm.Matrix2(
            node.velocity.x * dpos.x, node.velocity.x * dpos.y,
            node.velocity.y * dpos.x, node.velocity.y * dpos.y,
          );
          newB.add(outerProduct * (weight * 4.0));
        }
      }

      // Dynamic stream thrust multiplier based on active fan height
      double targetThrust = 1.0;
      if (p.position.y < 9) {
        targetThrust = f1Speed;
      } else if (p.position.y < 17) {
        targetThrust = f2Speed;
      } else {
        targetThrust = f3Speed;
      }

      // Immediate velocity response: Blend grid velocity scaled by target fan thrust
      p.velocity = p.velocity * 0.10 + newVel * 0.90;
      if (targetThrust <= 0.01) {
        p.velocity.scale(0.85); // Rapid decay when fan is turned off
      }

      p.affineB = newB;

      // Advect particle position
      p.position.add(p.velocity * dt);
      p.life += dt;

      final speed = p.velocity.length;
      sumVel += speed;
      if (speed > maxV) maxV = speed;
      kineticSum += 0.5 * p.mass * speed * speed;

      // Dynamic color coding by velocity & fan stream
      final normSpeed = (speed / 30.0).clamp(0.0, 1.0);
      if (p.position.y < 9) {
        p.color = Color.lerp(const Color(0xFF35DBC7), const Color(0xFFE07A48), normSpeed.clamp(0.0, 1.0))!;
      } else if (p.position.y < 17) {
        p.color = Color.lerp(const Color(0xFF35DBC7), const Color(0xFFE05688), normSpeed.clamp(0.0, 1.0))!;
      } else {
        p.color = Color.lerp(const Color(0xFF35DBC7), const Color(0xFF569AE0), normSpeed.clamp(0.0, 1.0))!;
      }

      // Respawn particles exiting right edge or expired
      if (p.position.x >= gridWidth - 0.5 || p.position.x < 0 || p.position.y < 0 || p.position.y >= gridHeight || p.life > p.maxLife) {
        p.position.x = _random.nextDouble() * 2.0;
        p.position.y = _random.nextDouble() * gridHeight;
        
        double initThrust = 1.0;
        if (p.position.y < 9) {
          initThrust += f1Speed * 28.0;
        } else if (p.position.y < 17) {
          initThrust += f2Speed * 32.0;
        } else {
          initThrust += f3Speed * 30.0;
        }

        p.velocity = vm.Vector2(initThrust + _random.nextDouble() * 2, (_random.nextDouble() - 0.5) * 0.4);
        p.life = 0.0;
        p.maxLife = 0.8 + _random.nextDouble() * 0.6;
      }
    }

    // Telemetry metrics
    if (particles.isNotEmpty) {
      averageVelocity = sumVel / particles.length;
      maxVelocity = maxV;
      totalKineticEnergy = kineticSum;
      turbulenceIndex = ((maxV - averageVelocity) / (averageVelocity + 0.1)).clamp(0.0, 5.0);
    }
  }

  double _quadraticWeight(double x) {
    x = x.abs();
    if (x < 0.5) {
      return 0.75 - x * x;
    } else if (x < 1.5) {
      return 0.5 * (1.5 - x) * (1.5 - x);
    }
    return 0.0;
  }
}
