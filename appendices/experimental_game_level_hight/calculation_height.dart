import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:rxdart/rxdart.dart';

/// A sophisticated vertical state estimator using an Extended Kalman Filter (EKF).
///
/// This class estimates the relative height, vertical velocity, and acceleration bias
/// of a device by fusing data from an accelerometer, gyroscope, and magnetometer.
///
/// ### Key Features:
/// * **EKF State Tracking:** Tracks position ($z$), velocity ($v_z$), and bias ($b_z$).
/// * **Rest Detection:** Uses Zero Velocity Update (ZUPT) to prevent drift when stationary.
/// * **Outlier Rejection:** Gates height innovations to ignore sudden sensor spikes.
/// * **Sensor Fusion:** Combines IMU data with complementary filtering for orientation.
class ExtendedKalmanHeightEstimator {
  /// The state vector $\mathbf{x} = [z, v_z, b_z]^T$ representing:
  /// * [0]: Height (meters)
  /// * [1]: Vertical Velocity (m/s)
  /// * [2]: Vertical Acceleration Bias ($m/s^2$)
  Vector3 _x = Vector3.zero();

  /// The error covariance matrix $\mathbf{P}$ (3x3), representing the uncertainty
  /// of the current state estimate.
  Matrix3 _P = Matrix3.zero();

  /// The process noise covariance matrix $\mathbf{Q}$, representing the
  /// expected noise in the system model.
  final Matrix3 _Q;

  /// Measurement noise for the height update.
  final double _R_height;

  /// Measurement noise for the Zero Velocity Update (ZUPT).
  final double _R_zupt;

  /// Weight for the complementary filter used in orientation fusion.
  final double _compAlpha;

  /// Acceleration threshold ($m/s^2$) below which horizontal motion is
  /// ignored for vertical height updates.
  final double _horizontalMotionThreshold;

  /// Low-pass filter coefficient for vertical acceleration smoothing.
  final double _vertLPAlpha;
  double _aZLP = 0.0;

  /// Maximum allowed difference (meters) between predicted and measured
  /// height before a measurement is rejected as an outlier.
  final double _maxInnovation;

  /// Maximum vertical displacement (meters) allowed between consecutive samples
  /// to prevent "teleporting" errors.
  final double _maxJump;
  double _lastHeight = 0.0;

  /// Stream emitting the estimated height in meters.
  BehaviorSubject<double>? heightSubject;

  /// Stream emitting the raw 3-axis accelerometer data.
  BehaviorSubject<Vector3>? accelSubject;

  /// Current device orientation represented as a Quaternion (Body-to-World frame).
  Quaternion _q = Quaternion.identity();

  /// Flag indicating if the gyroscope is currently stable (minimal rotation).
  bool _gyroStable = false;

  /// Alpha for Zero Angular Rate Update (ZARU) blending.
  final double _zaruAlpha;

  /// Threshold (rad/s) below which the gyroscope is considered "stable".
  final double _gyroThreshold;

  /// Internal state to track if the estimator is active.
  bool _isRunning = false;

  // Stream Subscriptions
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  /// Gravity vector estimate used for high-pass filtering and rest detection.
  Vector3 _gravityEstimate = Vector3(0, 0, 9.81);
  static const double _alphaHP = 0.98;

  // Timestamps for delta-time calculations
  DateTime? _lastAccelTimestamp;
  DateTime? _lastGyroTimestamp;

  /// Most recent magnetometer reading.
  Vector3? _latestMag;

  // Rest detection logic variables
  int _stationaryCount = 0;
  static const int _restWindowSize = 25;
  static const double _restMeanThreshold = 0.2;
  static const double _restStdThreshold = 0.1;
  final List<double> _hpBuffer = [];

  /// Initializes the EKF with configurable noise parameters and thresholds.
  ///
  /// [Q] is the process noise. Higher values make the filter more responsive but noisier.
  /// [R_height] is measurement noise. Higher values trust the sensor less.
  ExtendedKalmanHeightEstimator({
    Matrix3? Q,
    double? R_height,
    double? R_zupt,
    double gyroThreshold = 0.01,
    double zaruAlpha = 0.1,
    double compAlpha = 0.02,
    double horizontalMotionThreshold = 0.2,
    double vertLPAlpha = 0.9,
    double maxInnovation = 0.5,
    double maxJump = 0.2,
  }) : _Q = Q ?? Matrix3(1e-4, 0, 0, 0, 1e-4, 0, 0, 0, 1e-4),
       _R_height = R_height ?? 0.1,
       _R_zupt = R_zupt ?? 0.001,
       _gyroThreshold = gyroThreshold,
       _zaruAlpha = zaruAlpha,
       _compAlpha = compAlpha,
       _horizontalMotionThreshold = horizontalMotionThreshold,
       _vertLPAlpha = vertLPAlpha,
       _maxInnovation = maxInnovation,
       _maxJump = maxJump {
    _P = Matrix3.identity()..scale(1e-2);
  }

  /// Starts the estimator by performing an initial static calibration.
  ///
  /// [samples] determines the number of initial accelerometer readings used to
  /// find the gravity vector.
  /// [maxTiltAngleDeg] is the maximum allowed tilt from the vertical axis
  /// for a valid calibration.
  ///
  /// Returns `true` if calibration succeeded and the estimator started.
  Future<bool> start(int samples, {double maxTiltAngleDeg = 5.0}) async {
    if (_isRunning) return true;
    try {
      _x = Vector3.zero();
      _P = Matrix3.identity()..scale(1e-2);
      _q = Quaternion.identity();
      _lastAccelTimestamp = null;
      _lastGyroTimestamp = null;
      _latestMag = null;
      _lastHeight = 0.0;
      heightSubject = BehaviorSubject.seeded(0.0);
      accelSubject = BehaviorSubject.seeded(Vector3.zero());

      // Calibration Phase: Average samples to find local 'down'
      List<Vector3> samplesList = [];
      for (int i = 0; i < samples; i++) {
        final e = await accelerometerEvents.first;
        samplesList.add(Vector3(e.x, e.y, e.z));
      }
      final avg = samplesList.reduce((a, b) => a + b).scaled(1 / samples);
      final axis = avg.normalized();
      final tilt = acos(axis.dot(Vector3(0, 0, 1)).clamp(-1.0, 1.0)) * 180 / pi;

      // Fail if the device isn't relatively flat
      if (tilt > maxTiltAngleDeg) return false;

      // Check for stability during calibration
      final mags = samplesList.map((v) => v.length).toList();
      final mean = mags.reduce((a, b) => a + b) / mags.length;
      final std = sqrt(
        mags.map((m) => pow(m - mean, 2)).reduce((a, b) => a + b) / mags.length,
      );
      if (std > 0.02) return false;

      _q = _estimateInitialOrientation(avg);
      _isRunning = true;

      _gyroSub = gyroscopeEvents.listen(_onGyro);
      _accelSub = accelerometerEvents.listen(_onAccel);
      _magSub = magnetometerEvents.listen(_onMagnetometer);

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stops sensor data subscriptions and clears internal subjects.
  void stop() {
    if (!_isRunning) return;
    _gyroSub?.cancel();
    _accelSub?.cancel();
    _magSub?.cancel();
    heightSubject?.add(0.0);
    accelSubject?.add(Vector3.zero());
    _isRunning = false;
  }

  /// Permanently shuts down the estimator and closes reactive streams.
  void dispose() {
    stop();
    heightSubject?.close();
    accelSubject?.close();
  }

  /// Processes gyroscope data to update the orientation quaternion.
  /// Uses SLERP to blend with a stable reference if rotation is minimal.
  void _onGyro(GyroscopeEvent e) {
    if (!_isRunning) return;
    final omega = Vector3(e.x, e.y, e.z);
    _gyroStable = omega.length < _gyroThreshold;
    final now = e.timestamp;
    final dt = _lastGyroTimestamp == null
        ? 0.0
        : now.difference(_lastGyroTimestamp!).inMicroseconds / 1e6;
    _lastGyroTimestamp = now;
    if (dt <= 0) return;

    final prevQ = _q.clone();
    final theta = omega.length * dt;
    if (theta > 1e-6) {
      final axis = omega.normalized();
      _q = (_q * Quaternion.axisAngle(axis, theta)).normalized();
    }
    // ZARU: If nearly still, drift back slightly to the previous stable orientation
    if (_gyroStable) {
      _q = slerp(prevQ, _q, 1 - _zaruAlpha).normalized();
    }
  }

  /// The primary processing loop for accelerometer data.
  /// Performs gravity compensation, rest detection, and Kalman prediction/updates.
  void _onAccel(AccelerometerEvent e) {
    if (!_isRunning) return;
    final now = e.timestamp;
    final dt = _lastAccelTimestamp == null
        ? 0.0
        : now.difference(_lastAccelTimestamp!).inMicroseconds / 1e6;
    _lastAccelTimestamp = now;
    if (dt <= 0) return;

    final aRaw = Vector3(e.x, e.y, e.z);
    accelSubject?.add(aRaw);

    // Transform acceleration into the world frame
    final qInv = _q.clone()..inverse();
    final gBodyTrue = qInv.rotated(Vector3(0, 0, 9.81));
    final aNetWorld = _q.rotated(aRaw - gBodyTrue);

    final horizontalMag = sqrt(
      aNetWorld.x * aNetWorld.x + aNetWorld.y * aNetWorld.y,
    );
    final verticallySignificant = horizontalMag < _horizontalMotionThreshold;

    _aZLP = _vertLPAlpha * _aZLP + (1 - _vertLPAlpha) * aNetWorld.z;

    // --- Rest Detection (ZUPT) ---
    final gravityLP = _estimateGravity(aRaw, dt);
    final aNetLP = aRaw - gravityLP;
    _hpBuffer.add(aNetLP.length);
    if (_hpBuffer.length > _restWindowSize) _hpBuffer.removeAt(0);

    final buf = _hpBuffer;
    final meanRP = buf.fold(0.0, (s, v) => s + v) / buf.length;
    final stdRP = sqrt(
      buf.fold(0.0, (s, v) => s + pow(v - meanRP, 2)) / buf.length,
    );

    final isRest =
        meanRP < _restMeanThreshold && stdRP < _restStdThreshold && _gyroStable;
    if (isRest) {
      if (++_stationaryCount >= _restWindowSize) _zupt();
      return;
    } else {
      _stationaryCount = 0;
    }

    // --- Orientation Correction ---
    final qAcc = _estimateInitialOrientation(aRaw);
    if (_latestMag != null) {
      final qMag = _estimateMagYawCorrection(qAcc, _latestMag!);
      if (qMag != null) {
        final fused = slerp(qAcc, qMag, _compAlpha).normalized();
        _q = slerp(_q, fused, _compAlpha).normalized();
      } else {
        _q = slerp(_q, qAcc, _compAlpha).normalized();
      }
    } else {
      _q = slerp(_q, qAcc, _compAlpha).normalized();
    }

    // Correct bias if the device is roughly at 1G
    if ((aRaw.length - 9.81).abs() < 0.3) _biasCorrection(aRaw);

    // --- Kalman Filter Steps ---
    _predict(dt, _aZLP);
    if (verticallySignificant) _updateHeight(aRaw, gBodyTrue);

    // Prevent sudden height artifacts
    double rawHeight = _x.x;
    double delta = rawHeight - _lastHeight;
    if (delta.abs() > _maxJump) {
      rawHeight = _lastHeight + _maxJump * delta.sign;
    }
    _lastHeight = rawHeight;
    heightSubject?.add(rawHeight);
  }

  void _onMagnetometer(MagnetometerEvent e) =>
      _latestMag = Vector3(e.x, e.y, e.z);

  /// Tracks the gravity vector using a low-pass filter.
  Vector3 _estimateGravity(Vector3 aRaw, double dt) {
    _gravityEstimate.x =
        _alphaHP * _gravityEstimate.x + (1 - _alphaHP) * aRaw.x;
    _gravityEstimate.y =
        _alphaHP * _gravityEstimate.y + (1 - _alphaHP) * aRaw.y;
    _gravityEstimate.z =
        _alphaHP * _gravityEstimate.z + (1 - _alphaHP) * aRaw.z;
    return _gravityEstimate;
  }

  /// Small Kalman update to correct the internal bias estimate when at rest.
  void _biasCorrection(Vector3 aRaw) {
    final magError = aRaw.length - 9.81;
    final H = Vector3(0, 0, 1);
    final S = H.dot(_P * H) + 0.5;
    final K = (_P * H) / S;
    _x += K.scaled(magError);
    _P =
        (Matrix3.identity() -
            Matrix3.columns(K.scaled(H.x), K.scaled(H.y), K.scaled(H.z))) *
        _P;
  }

  /// Predicts the next state based on the previous state and current vertical acceleration.
  void _predict(double dt, double az) {
    // State transition matrix F
    final F = Matrix3(1, dt, -0.5 * dt * dt, 0, 1, -dt, 0, 0, 1);
    final unbiased = az - _x.z;

    // x = F * x + B * u
    _x.x += _x.y * dt + 0.5 * unbiased * dt * dt;
    _x.y += unbiased * dt;

    // P = F * P * F^T + Q
    _P = F * _P * F.transposed() + _Q;
  }

  /// Updates the Kalman state with a new height measurement.
  void _updateHeight(Vector3 aRaw, Vector3 gBody) {
    final innovation = (aRaw.z - gBody.z) - _x.x;

    if (innovation.abs() > _maxInnovation) return;

    final H = Vector3(1, 0, 0); // Jacobian of measurement function
    final S = H.dot(_P * H) + _R_height;
    if (S.abs() < 1e-9) return;

    final K = (_P * H) / S; // Kalman gain
    _x += K.scaled(innovation);
    _P =
        (Matrix3.identity() -
            Matrix3.columns(K.scaled(H.x), K.scaled(H.y), K.scaled(H.z))) *
        _P;
  }

  /// Zero Velocity Update: Forces the velocity estimate toward zero when rest is detected.
  void _zupt() {
    final H = Vector3(0, 1, 0);
    final S = H.dot(_P * H) + _R_zupt;
    if (S.abs() < 1e-9) return;

    final K = (_P * H) / S;
    final innov = -_x.y;
    _x += K.scaled(innov);
    _P =
        (Matrix3.identity() -
            Matrix3.columns(K.scaled(H.x), K.scaled(H.y), K.scaled(H.z))) *
        _P;
  }

  /// Estimates the orientation relative to the gravity vector.
  Quaternion _estimateInitialOrientation(Vector3 g) {
    final v = Vector3(0, 0, 1).cross(g.normalized());
    final w = 1 + Vector3(0, 0, 1).dot(g.normalized());
    return v.length2 < 1e-8
        ? Quaternion.identity()
        : Quaternion(v.x, v.y, v.z, w).normalized();
  }

  /// Uses the magnetometer to correct yaw drift in the orientation quaternion.
  Quaternion? _estimateMagYawCorrection(Quaternion qAcc, Vector3 mag) {
    final world = qAcc.rotated(mag);
    final proj = Vector2(world.x, world.y);
    final strength = proj.length;

    // Ignore magnetic fields that are too weak or too strong (interference)
    if (strength < 10 || strength > 70) return null;

    final heading = atan2(proj.y, proj.x);
    final qYaw = Quaternion.axisAngle(Vector3(0, 0, 1), -heading);
    final rg = qYaw.rotated(Vector3(0, 0, -1));
    final qComb = _estimateInitialOrientation(rg);
    return qYaw * qComb;
  }

  double _quatDot(Quaternion a, Quaternion b) =>
      a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;

  /// Spherical Linear Interpolation for smooth transitions between Quaternions.
  Quaternion slerp(Quaternion a, Quaternion b, double t) {
    double cosH = _quatDot(a, b);
    if (cosH < 0) {
      b = Quaternion(-b.x, -b.y, -b.z, -b.w);
      cosH = -cosH;
    }
    if (cosH > 0.9995) {
      final lerp = Quaternion(
        a.x + t * (b.x - a.x),
        a.y + t * (b.y - a.y),
        a.z + t * (b.z - a.z),
        a.w + t * (b.w - a.w),
      );
      return lerp.normalized();
    }
    final theta = acos(cosH);
    final s = sin(theta);
    final wa = sin((1 - t) * theta) / s;
    final wb = sin(t * theta) / s;
    return Quaternion(
      a.x * wa + b.x * wb,
      a.y * wa + b.y * wb,
      a.z * wa + b.z * wb,
      a.w * wa + b.w * wb,
    );
  }
}
