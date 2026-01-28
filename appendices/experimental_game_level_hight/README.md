# Experimental Game Level — Height Estimation via Sensors

## Overview

This is an **experimental prototype** exploring the use of device motion sensors (accelerometer, gyroscope, magnetometer) for a potential game mechanic: **"The Floor is Lava"** or similar height-based challenges.

This code is **not integrated** into the main NexaBurst application but demonstrates sensor integration and algorithmic exploration for educational and engineering portfolio purposes.

---

## Concept

### Game Idea: "The Floor is Lava"

Players must physically jump, squat, or raise their device to trigger game events based on detected height changes. The accelerometer measures vertical movement to estimate height relative to a baseline position.

### Technical Challenge

Accurately estimating vertical position using only accelerometer data requires:
1. Sensor calibration (zero-gravity offset)
2. Double integration of acceleration → velocity → position
3. Noise filtering to reduce measurement drift
4. Threshold detection for discrete events

---

## What's Inside

### Files

```
experimental_game_level_hight/
├── main.dart              # Standalone Flutter app entry point
└── calculation_height.dart # Sensor math and algorithms
```

### `calculation_height.dart`

Core sensor processing module with:

- **Sensor Data Collection** — Accelerometer values
- **Calibration** — Establish baseline/zero point
- **Filter Algorithm** — Smooth noisy sensor data
- **Integration Logic** — Convert acceleration → position
- **Event Detection** — Recognize "jump" or "squat" events
- **Threshold Configuration** — Adjustable sensitivity

### `main.dart`

Minimal Flutter app demonstrating:

- **Sensor Stream Setup** — Listen to device motion
- **Real-Time Display** — Show acceleration values
- **Height Visualization** — Graph of detected height over time
- **Event Callback** — Trigger action on jump detection
- **Test Interface** — Manual threshold adjustment

---

## Technical Deep Dive

### Sensor Fusion Challenge

#### **Raw Accelerometer Data**

```dart
// Accelerometer provides acceleration in 3 axes
accelerometerEvents.listen((AccelerometerEvent event) {
  double ax = event.x;  // X-axis (side to side)
  double ay = event.y;  // Y-axis (front to back)
  double az = event.z;  // Z-axis (up/down) ← relevant for height
  // Units: m/s²
});
```

#### **Converting to Height**

Position requires double integration:

```
acceleration (a) → [integrate over time] → velocity (v)
                                          ↓
                                          [integrate over time]
                                          ↓
                                          position (p) / height
```

#### **Challenges**

1. **Sensor Noise** — Small random fluctuations cause drift
2. **Gravity Offset** — Need to subtract ~9.8 m/s² from Z-axis
3. **Integration Drift** — Small errors compound with each integration step
4. **Real-time Processing** — Must be fast enough for smooth gameplay

### Algorithm: Height Calculation

```dart
class HeightCalculator {
  double _velocity = 0.0;
  double _height = 0.0;
  double _lastZ = 0.0;
  
  /// Calculate height change based on acceleration
  double calculateHeight(double currentZ, double deltaTime) {
    // Subtract gravity (device at rest has az = 9.8)
    double acceleration = currentZ - GRAVITY_OFFSET;
    
    // Apply low-pass filter to reduce noise
    acceleration = _lowPassFilter(acceleration);
    
    // Integrate acceleration to get velocity
    _velocity += acceleration * deltaTime;
    
    // Integrate velocity to get position
    double heightDelta = _velocity * deltaTime;
    _height += heightDelta;
    
    // Apply dampening to prevent drift
    _height *= DAMPENING_FACTOR;
    
    return _height;
  }
  
  /// Low-pass filter for noise reduction
  double _lowPassFilter(double value) {
    return _lastZ * (1 - FILTER_ALPHA) + value * FILTER_ALPHA;
  }
}
```

### Configuration Parameters

```dart
const double GRAVITY_OFFSET = 9.8;      // m/s² (gravity)
const double FILTER_ALPHA = 0.1;         // Lower = more smoothing
const double DAMPENING_FACTOR = 0.99;    // Reduces drift
const double JUMP_THRESHOLD = 2.5;       // Meters to trigger event
const double JUMP_COOLDOWN = 0.5;        // Seconds between jumps
```

---

## Running the Experiment

### Prerequisites

- Flutter project setup
- Physical Android or iOS device (emulator works but less accurate)
- Motion sensor permission granted

### Installation

```bash
# Option 1: Run as standalone (if main.dart is in this folder)
flutter run

# Option 2: Copy files to nexaburst project and run
cp *.dart ../../../nexaburst/lib/debug/
cd ../../../nexaburst
flutter run
```

### Using the App

1. **Calibration**
   - Tap "Calibrate" button
   - Hold device steady for 2 seconds
   - System establishes baseline readings

2. **Testing Height Detection**
   - Tap "Start Detection"
   - Hold device upright
   - Jump or raise device vertically
   - Watch for "JUMP!" event trigger

3. **Adjusting Sensitivity**
   - Slider to change jump threshold
   - Lower threshold = more sensitive
   - Higher threshold = less false positives

4. **Viewing Data**
   - Real-time acceleration graph
   - Height vs. time chart
   - Event log

---

## Results & Findings

### What Worked Well

✅ **Acceleration Detection** — Reliably detects rapid upward movement  
✅ **Event Triggering** — Jump detection works with good threshold tuning  
✅ **Noise Filtering** — Low-pass filter effectively smooths data  
✅ **Responsiveness** — Real-time performance is acceptable  

### Limitations

❌ **Position Drift** — Over time, height estimate drifts (gravity integration errors)  
❌ **Absolute Height** — Can't reliably measure absolute jump height  
❌ **Device Orientation** — Pitch/roll rotation affects Z-axis reading  
❌ **Sensor Calibration** — Different devices have different baseline offsets  

### Realistic Use Cases

**Feasible:**
- Detect binary "jump/no-jump" events ✓
- Measure jump count in a time window ✓
- Rank players by jump frequency ✓

**Not Reliable:**
- Measure exact jump height (±20-30cm error)
- Estimate vertical position over long periods (drift accumulates)
- Work with multiple device orientations simultaneously

---

## Why Not in Main App?

### Decision Rationale

1. **Accuracy Limitations** — Position drift makes gameplay feel imprecise
2. **Device Variation** — Different phones have different sensor characteristics
3. **User Experience** — Jump detection feels more "gamey" than physically accurate
4. **Development Focus** — Other 6 game stages provide better variety
5. **Accessibility** — Not all devices have equally capable motion sensors

### Potential Future Improvements

- **Sensor Fusion** — Combine accelerometer + gyroscope + magnetometer
- **Quaternion-Based** — Use rotation matrices for orientation independence
- **Machine Learning** — Train classifier on jump patterns
- **Baseline Calibration** — User-specific calibration at game start
- **Statistical Filtering** — Kalman filter for better drift handling

---

## Educational Value

This experiment demonstrates:

### Software Engineering
- Sensor API integration (Flutter motion sensors)
- Real-time signal processing
- Algorithm optimization for mobile performance
- Testing physical phenomena via software

### Mathematics & Physics
- Kinematics (acceleration, velocity, position)
- Numerical integration
- Signal filtering (low-pass filters)
- Noise reduction techniques

### Mobile Development
- Permission handling (motion sensor access)
- High-frequency data streaming
- State management during continuous input
- UI responsiveness with computationally intensive algorithms

### Problem-Solving
- Identifying unreliable sensor data
- Iterating on algorithm parameters
- Graceful degradation when accuracy is insufficient
- Documenting "failed" experiments for learning

---

## Code Structure

### Key Classes

```dart
class HeightCalculator {
  /// Core algorithm for calculating height from acceleration
  double calculateHeight(double currentZ, double deltaTime)
  
  /// Reset internal state (for new jump detection)
  void reset()
  
  /// Get current velocity estimate
  double getVelocity()
}

class JumpDetector {
  /// Detect if acceleration indicates a jump event
  bool isJumping(double heightEstimate)
  
  /// Configure sensitivity
  void setThreshold(double threshold)
}
```

### Main UI Flow

```
Home Screen
├── Calibrate Button → Establish baseline
├── Start Detection → Begin listening to sensors
├── Real-time Graphs → Display acceleration & height
├── Event Log → Show detected jumps
└── Sensitivity Slider → Adjust threshold
```

---

## Lessons Learned

### ✅ What We Discovered

1. **Sensor data is noisy** — Always filter
2. **Gravity is your enemy** — Calibration is critical
3. **Integration compounds errors** — Dampening helps
4. **Threshold tuning is crucial** — No one-size-fits-all value
5. **Testing on real devices is essential** — Emulators inadequate

### 🔄 Iteration Process

1. Initial naive double-integration → lots of drift
2. Add gravity offset → much better
3. Add low-pass filter → smoother signals
4. Add dampening → fewer false positives
5. Add threshold tuning UI → user customization

### 📚 Relevant Research

- [Inertial Measurement Unit (IMU) Basics](https://en.wikipedia.org/wiki/Inertial_measurement_unit)
- [Kalman Filtering](https://en.wikipedia.org/wiki/Kalman_filter)
- [Signal Processing for Mobile Sensors](https://www.researchgate.net/publication/260391339_Signal_processing_for_mobile_sensors)

---

## If You Were to Implement This

### Recommended Approach

Instead of pure acceleration integration, consider:

```dart
// Hybrid approach: Track jump events, not absolute height
class SmartJumpDetector {
  final _peakDetector = PeakDetector(windowSize: 10);
  
  /// Detect jump by finding local maxima in acceleration
  bool detectJump(double acceleration) {
    if (_peakDetector.isPeak(acceleration)) {
      return acceleration > JUMP_THRESHOLD;
    }
    return false;
  }
}
```

This avoids integration drift while still detecting the physical motion.

---

## Files Reference

- [main.dart](main.dart) — App entry point and UI
- [calculation_height.dart](calculation_height.dart) — Core algorithms

---

## Further Exploration

### Adjacent Topics to Study

- Sensor calibration techniques
- Kalman filter theory
- Quaternion mathematics (for rotation-aware calculations)
- Machine learning classification (training jump detectors)
- Signal processing (FFT, wavelets)

### Possible Extensions

- Combine with gyroscope for orientation tracking
- Implement step-counting algorithm (like fitness trackers)
- Create gesture recognition system
- Build augmented reality game using motion

---

## Conclusion

While "The Floor is Lava" didn't make it into the final NexaBurst build, this experiment was **valuable for learning** and demonstrates:

- Willingness to explore novel solutions
- Understanding of physics and mathematics
- Problem-solving when faced with limitations
- Clear documentation of experimental work
- Honest assessment of when to pivot away

This is the kind of **exploration and documentation** that employers appreciate in portfolios! 🚀

---

*Experiment Date: 2026-01-28*  
*Status: Archived (Educational Reference)*
