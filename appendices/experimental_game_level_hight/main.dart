import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:height/calculation_height.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

/// The entry point for the Height Estimation application.
void main() {
  runApp(const MyApp());
}

/// A root-level widget that configures the [MaterialApp] and its theme.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CalibrationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// A screen that provides a user interface for calibrating and
/// monitoring real-time height estimation using device sensors.
class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

/// The state for [CalibrationScreen], managing sensor permissions,
/// the EKF estimator lifecycle, and reactive stream UI updates.
class _CalibrationScreenState extends State<CalibrationScreen> {
  /// The core Extended Kalman Filter (EKF) logic for height calculation.
  ExtendedKalmanHeightEstimator? _estimator;

  /// Subscription to the height output stream from the estimator.
  StreamSubscription<double>? _heightSub;

  /// Subscription to the raw accelerometer data stream.
  StreamSubscription<Vector3>? _accelSub;

  /// Controller for broadcasting height string updates to the [StreamBuilder].
  final StreamController<String> _statusStreamController =
      StreamController<String>.broadcast();

  /// Controller for broadcasting formatted accelerometer strings to the [StreamBuilder].
  final StreamController<String> _accelStreamController =
      StreamController<String>.broadcast();

  /// User-facing instructional or error text.
  String? _text;

  /// Indicates if the calibration/estimation process is currently active.
  bool _isCalibrating = false;

  /// Tracks if the device sensors are accessible and permissions are granted.
  bool _sensorsAvailable = false;

  /// A timer used to manage calibration timeouts or mock data on web platforms.
  Timer? _calibrationTimer;

  @override
  void initState() {
    super.initState();
    _checkSensorPermissionsAndAvailability();
  }

  /// Validates hardware sensor permissions and initializes the estimator.
  ///
  /// On mobile platforms, it requests [Permission.sensors].
  /// If permissions are denied, the UI updates to notify the user.
  Future<void> _checkSensorPermissionsAndAvailability() async {
    try {
      if (!kIsWeb) {
        final status = await Permission.sensors.request();
        if (status != PermissionStatus.granted) {
          setState(() {
            _sensorsAvailable = false;
            _text = "Sensors unavailable or not approved";
          });
          return;
        }
      }

      setState(() {
        _sensorsAvailable = true;
        _text = "Place the device flat on the floor and press Calibrate";
        _estimator = ExtendedKalmanHeightEstimator();
      });
    } catch (e) {
      setState(() {
        _sensorsAvailable = false;
        _text = "Error checking permissions: $e";
      });
    }
  }

  /// Initiates the sensor calibration and height estimation sequence.
  ///
  /// 1. **Validation**: Checks for sensor availability and initialization.
  /// 2. **Calibration**: Collects initial samples to establish the gravity vector.
  /// 3. **Streaming**: Subscribes to estimator subjects to update the UI via [StreamController]s.
  /// 4. **Web Support**: Provides mock data generation if running in a web environment.
  Future<void> _startCalibration() async {
    if (!_sensorsAvailable) {
      setState(() {
        _text = "Sensors not available or permission denied.";
      });
      return;
    }
    if (_isCalibrating) return;
    if (_estimator == null && !kIsWeb) {
      setState(() {
        _text = "Error: Estimator not initialized.";
      });
      return;
    }

    if (!kIsWeb && _estimator != null) {
      // Safety timeout for the calibration process
      _calibrationTimer = Timer(const Duration(seconds: 90), () {
        if (_isCalibrating) {
          _stopCalibration();
          setState(() {
            _text = "Calibration timeout. Please try again.";
          });
        }
      });

      setState(() {
        _isCalibrating = true;
        _text = "Calibrating... hold still";
      });

      // Attempt to calibrate with 30 initial sensor samples
      final success = await _estimator?.start(30) ?? false;
      if (!success) {
        setState(() {
          _isCalibrating = false;
          _text = "Calibration failed. Keep phone flat!";
        });
        return;
      }

      setState(() {
        _text = "Altitude computing... press stop to finish...";
      });

      // Listen to height updates (m)
      _heightSub = _estimator?.heightSubject?.listen((height) {
        _statusStreamController.add(height.toStringAsFixed(2));
      });
      // Listen to raw accelerometer updates (m/s²)
      _accelSub = _estimator?.accelSubject?.listen((v) {
        _accelStreamController.add(
          "\nx: ${v.x.toStringAsFixed(2)}, \ny: ${v.y.toStringAsFixed(2)}, \nz: ${v.z.toStringAsFixed(2)}",
        );
      });
    } else {
      // Web/Mock Implementation
      setState(() {
        _isCalibrating = true;
        _text = "Altitude computing... press stop to finish...";
      });

      _calibrationTimer = Timer.periodic(const Duration(milliseconds: 500), (
        _,
      ) {
        final number = (Random().nextDouble() * 100).toStringAsFixed(2);
        _statusStreamController.add(number);
      });
    }
  }

  /// Terminates sensor tracking and resets the UI state.
  void _stopCalibration() {
    _estimator?.stop();
    _heightSub?.cancel();
    _accelSub?.cancel();
    _calibrationTimer?.cancel();
    setState(() {
      _isCalibrating = false;
      _text = "Place the device flat on the floor and press Calibrate";
    });

    _statusStreamController.add("0.0");
    _accelStreamController.add("\nx: 0.0, \ny: 0.0, \nz: 0.0");
  }

  @override
  void dispose() {
    _heightSub?.cancel();
    _accelSub?.cancel();
    _estimator?.dispose();
    _calibrationTimer?.cancel();
    if (!_statusStreamController.isClosed) _statusStreamController.close();
    if (!_accelStreamController.isClosed) _accelStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 500 : double.infinity,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Display for Accelerometer Data
                        StreamBuilder<String>(
                          stream: _accelStreamController.stream,
                          builder: (context, snapshot) {
                            return Text(
                              '*accel* ${snapshot.data ?? "\nx: 0.0, \ny: 0.0, \nz: 0.0"}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 4,
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        // Display for Height/Altitude Data
                        StreamBuilder<String>(
                          stream: _statusStreamController.stream,
                          builder: (context, snapshot) {
                            return Text(
                              'height: ${snapshot.data ?? '0.0'}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                        // Control Buttons
                        Wrap(
                          spacing: 20,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: (_sensorsAvailable && !_isCalibrating)
                                  ? _startCalibration
                                  : null,
                              child: const Text('Calibrate'),
                            ),
                            ElevatedButton(
                              onPressed: (_sensorsAvailable && _isCalibrating)
                                  ? _stopCalibration
                                  : null,
                              child: const Text('Stop'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        // Status/Instruction Footer
                        Text(
                          _text ?? "Loading...",
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
