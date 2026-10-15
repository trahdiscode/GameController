import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TiltArenaApp());
}

class TiltArenaApp extends StatelessWidget {
  const TiltArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tilt Arena Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090C15),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4F6BFF),
          secondary: Color(0xFF2ED573),
          surface: Color(0xFF12172B),
        ),
      ),
      home: const ControllerScreen(),
    );
  }
}

class ControllerScreen extends StatefulWidget {
  const ControllerScreen({super.key});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  // Input Controllers
  final TextEditingController _serverController = TextEditingController(text: '172.17.176.166:8000');
  final TextEditingController _codeController = TextEditingController();

  // Connection State
  WebSocketChannel? _channel;
  StreamSubscription? _wsSubscription;
  bool _isConnected = false;
  bool _isConnecting = false;
  String _statusText = 'Disconnected';
  Color _statusColor = const Color(0xFFFF4757);
  int _playerId = 0;
  int _rtt = 0;
  int _jumpCount = 0;
  Timer? _reconnectTimer;
  Timer? _streamTimer;
  Timer? _pingTimer;
  Timer? _uiTimer;
  int _reconnectAttempts = 0;
  bool _manualDisconnect = false;

  // Sensor state
  double _smoothPitch = 0.0;
  double _smoothRoll = 0.0;
  double _offsetPitch = 0.0;
  double _offsetRoll = 0.0;
  List<double> _accData = [0.0, 9.8, 0.0];
  List<double> _rotData = [0.0, 0.0, 0.0];
  DateTime _lastShakeTime = DateTime.now();

  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  // Active Controller Layout
  int _selectedLayout = 0; // 0: Motion & Tilt, 1: Pro Gamepad, 2: Racing Wheel
  bool _isLandscape = false;
  int _orientationMode = 0; // 0: Auto, 1: Locked Landscape, 2: Locked Portrait
  bool _invertRoll = false;
  bool _invertPitch = false;
  double _sensitivity = 1.3; // Default 1.3x for responsive steering

  // Virtual Gamepad State
  double _stickX = 0.0;
  double _stickY = 0.0;
  double _wheelAngle = 0.0;
  double _gasPedal = 0.0;
  double _brakePedal = 0.0;
  final Map<String, int> _buttons = {};

  final List<Color> _playerColors = [
    const Color(0xFF4F6BFF),
    const Color(0xFFFF4757), // P1 Red
    const Color(0xFF2ED573), // P2 Green
    const Color(0xFF1E90FF), // P3 Blue
    const Color(0xFFFFA502), // P4 Orange
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _startSensorListeners();
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _streamTimer?.cancel();
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _accSub?.cancel();
    _gyroSub?.cancel();
    _wsSubscription?.cancel();
    _channel?.sink.close();
    _serverController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedServer = prefs.getString('server_host');
    final savedCode = prefs.getString('room_code');
    final savedOffP = prefs.getDouble('offset_pitch');
    final savedOffR = prefs.getDouble('offset_roll');

    if (savedServer != null && savedServer.isNotEmpty) {
      _serverController.text = savedServer;
    }
    if (savedCode != null && savedCode.isNotEmpty) {
      _codeController.text = savedCode;
    }
    if (savedOffP != null) _offsetPitch = savedOffP;
    if (savedOffR != null) _offsetRoll = savedOffR;
    setState(() {});
  }

  void _cycleOrientation() {
    setState(() {
      _orientationMode = (_orientationMode + 1) % 3;
    });

    if (_orientationMode == 1) {
      // Lock Landscape
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      _showToast('Locked to Landscape');
    } else if (_orientationMode == 2) {
      // Lock Portrait
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      _showToast('Locked to Portrait');
    } else {
      // Auto
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      _showToast('Auto-Rotation Enabled');
    }
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF1E2646),
      ),
    );
  }

  void _startSensorListeners() {
    _accSub = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen((event) {
      _accData = [event.x, event.y, event.z];

      final ax = event.x;
      final ay = event.y;
      final az = event.z;

      final normX = (ax / 9.81).clamp(-1.0, 1.0);
      final normY = (ay / 9.81).clamp(-1.0, 1.0);

      double targetRoll;
      double targetPitch;

      // Adapt axes based on phone orientation (zero gimbal lock)
      if (_isLandscape) {
        // In landscape: Y axis is horizontal tilt, X axis is vertical tilt
        targetRoll = math.asin(-normY) * (180.0 / math.pi);
        targetPitch = math.asin(normX) * (180.0 / math.pi);
      } else {
        // In portrait: X axis is horizontal tilt, Y axis is vertical tilt
        targetRoll = math.asin(normX) * (180.0 / math.pi);
        targetPitch = math.asin(normY) * (180.0 / math.pi);
      }

      // Snappy and smooth Exponential Moving Average (alpha = 0.40)
      _smoothRoll += (targetRoll - _smoothRoll) * 0.40;
      _smoothPitch += (targetPitch - _smoothPitch) * 0.40;

      // Shake Detection: detect sudden acceleration spike > 13 m/s^2
      final now = DateTime.now();
      if (now.difference(_lastShakeTime).inMilliseconds > 420) {
        final totalMag = math.sqrt(ax * ax + ay * ay + az * az);
        final deltaMag = (totalMag - 9.81).abs();
        if (deltaMag > 13.0) {
          _lastShakeTime = now;
          _triggerJump();
        }
      }
    });

    _gyroSub = gyroscopeEventStream(samplingPeriod: SensorInterval.gameInterval).listen((event) {
      _rotData = [
        event.x * (180.0 / math.pi),
        event.y * (180.0 / math.pi),
        event.z * (180.0 / math.pi),
      ];
    });

    // Decoupled UI timer at smooth 30 FPS
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (mounted) setState(() {});
    });
  }

  void _triggerJump() {
    setState(() {
      _jumpCount++;
    });
    _haptic(duration: 70);
  }

  void _calibrateNeutral() async {
    setState(() {
      _offsetPitch = _smoothPitch;
      _offsetRoll = _smoothRoll;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('offset_pitch', _offsetPitch);
    await prefs.setDouble('offset_roll', _offsetRoll);
    _haptic(duration: 90);
    _showToast('Neutral Angle Calibrated!');
  }

  void _haptic({int duration = 60}) {
    try {
      if (duration > 70) {
        HapticFeedback.heavyImpact();
      } else if (duration > 30) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  String _buildWsUrl(String hostInput, String code, int slot) {
    String host = hostInput.trim();
    bool isSecure = host.startsWith('wss://') || host.startsWith('https://');
    host = host.replaceAll(RegExp(r'^(https?|wss?)://'), '').replaceAll(RegExp(r'/.*$'), '');
    if (host.isEmpty) host = 'localhost:8000';
    final scheme = isSecure ? 'wss' : 'ws';
    return '$scheme://$host/ws/mobile/$code?pid=$slot';
  }

  void _connect() async {
    final code = _codeController.text.trim();
    final server = _serverController.text.trim();

    if (code.isEmpty) {
      _showToast('Please enter a 4-digit room code');
      return;
    }

    _manualDisconnect = false;
    _reconnectTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_host', server);
    await prefs.setString('room_code', code);

    final urlStr = _buildWsUrl(server, code, _playerId);
    setState(() {
      _isConnecting = true;
      _statusText = 'Connecting...';
      _statusColor = const Color(0xFFFFA502);
    });

    try {
      _wsSubscription?.cancel();
      _channel?.sink.close();

      final uri = Uri.parse(urlStr);
      _channel = WebSocketChannel.connect(uri);

      _wsSubscription = _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onDone: () {
          _handleDisconnect();
        },
        onError: (err) {
          _handleDisconnect();
        },
      );

      _streamTimer?.cancel();
      _streamTimer = Timer.periodic(const Duration(milliseconds: 16), (_) => _sendSensorPacket());

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 1), (_) => _sendPing());
    } catch (e) {
      _handleDisconnect();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final msg = jsonDecode(data.toString());
      final type = msg['type'];

      if (type == 'hello') {
        setState(() {
          _playerId = msg['id'] ?? 1;
          _isConnected = true;
          _isConnecting = false;
          _reconnectAttempts = 0;
          _statusText = 'P$_playerId Connected';
          _statusColor = _playerColors[_playerId % _playerColors.length];
        });
        _haptic(duration: 80);
      } else if (type == 'pong') {
        if (msg['to'] == null || msg['to'] == _playerId) {
          final sentTs = msg['ts'] ?? 0;
          final now = DateTime.now().millisecondsSinceEpoch;
          setState(() {
            _rtt = math.max(0, now - (sentTs as int));
          });
        }
      } else if (type == 'vib') {
        if (msg['to'] == null || msg['to'] == _playerId) {
          final ms = msg['ms'] ?? 60;
          _haptic(duration: ms as int);
        }
      }
    } catch (_) {}
  }

  void _disconnect() {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _streamTimer?.cancel();
    _pingTimer?.cancel();
    _wsSubscription?.cancel();
    _channel?.sink.close();
    setState(() {
      _isConnected = false;
      _isConnecting = false;
      _statusText = 'Disconnected';
      _statusColor = const Color(0xFFFF4757);
    });
  }

  void _handleDisconnect() {
    _streamTimer?.cancel();
    _pingTimer?.cancel();

    if (_manualDisconnect) return;

    setState(() {
      _isConnected = false;
      _isConnecting = false;
      _statusText = 'Reconnecting...';
      _statusColor = const Color(0xFFFF4757);
    });

    _reconnectAttempts++;
    final delay = math.min(500 * _reconnectAttempts, 3000);
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      if (!_manualDisconnect && mounted) {
        _connect();
      }
    });
  }

  void _sendSensorPacket() {
    if (!_isConnected || _channel == null || _playerId == 0) return;

    double calPitch = (_smoothPitch - _offsetPitch) * _sensitivity;
    double calRoll = (_smoothRoll - _offsetRoll) * _sensitivity;

    if (_invertRoll) calRoll = -calRoll;
    if (_invertPitch) calPitch = -calPitch;

    // Small deadzone (0.5 deg) eliminates resting jitter
    if (calPitch.abs() < 0.5) calPitch = 0.0;
    if (calRoll.abs() < 0.5) calRoll = 0.0;

    final packet = {
      'id': _playerId,
      'b': double.parse(calPitch.toStringAsFixed(2)),
      'g': double.parse(calRoll.toStringAsFixed(2)),
      'a': [
        double.parse(_accData[0].toStringAsFixed(2)),
        double.parse(_accData[1].toStringAsFixed(2)),
        double.parse(_accData[2].toStringAsFixed(2)),
      ],
      'r': [
        double.parse(_rotData[0].toStringAsFixed(2)),
        double.parse(_rotData[1].toStringAsFixed(2)),
        double.parse(_rotData[2].toStringAsFixed(2)),
      ],
      'j': _jumpCount,
      'l': _rtt,
      'mode': _selectedLayout == 0
          ? 'motion'
          : (_selectedLayout == 1 ? 'gamepad' : 'racing'),
      'buttons': _buttons,
      'sticks': {
        'lx': double.parse(_stickX.toStringAsFixed(2)),
        'ly': double.parse(_stickY.toStringAsFixed(2)),
      },
      'wheel': double.parse(_wheelAngle.toStringAsFixed(2)),
      'gas': double.parse(_gasPedal.toStringAsFixed(2)),
      'brake': double.parse(_brakePedal.toStringAsFixed(2)),
    };

    try {
      _channel?.sink.add(jsonEncode(packet));
    } catch (_) {}
  }

  void _sendPing() {
    if (!_isConnected || _channel == null || _playerId == 0) return;
    try {
      _channel?.sink.add(jsonEncode({
        'type': 'ping',
        'id': _playerId,
        'ts': DateTime.now().millisecondsSinceEpoch,
      }));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    _isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(),

            // Connection Configuration Panel (Scrollable to prevent overflow)
            if (!_isConnected) _buildSetupCard(),

            // Mode Selector Tabs
            _buildModeTabs(),

            // Main Active Controller View
            Expanded(
              child: _selectedLayout == 0
                  ? _buildMotionView()
                  : (_selectedLayout == 1 ? _buildGamepadView() : _buildRacingView()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final padVert = _isLandscape ? 4.0 : 8.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: padVert),
      decoration: const BoxDecoration(
        color: Color(0xFF12172B),
        border: Border(bottom: BorderSide(color: Color(0xFF1E2646))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Connection Status Pill
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: _statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: _statusColor.withOpacity(0.6), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _statusText,
                style: TextStyle(
                  color: _statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          // Actions Row (Orientation Lock, Invert Roll, Latency, Disconnect)
          Row(
            children: [
              // Screen Rotation Lock Button
              IconButton(
                icon: Icon(
                  _orientationMode == 1
                      ? Icons.stay_current_landscape
                      : (_orientationMode == 2 ? Icons.stay_current_portrait : Icons.screen_rotation),
                  color: _orientationMode == 0 ? const Color(0xFF8290B8) : const Color(0xFF4F6BFF),
                  size: 18,
                ),
                tooltip: 'Toggle Screen Lock',
                onPressed: _cycleOrientation,
                visualDensity: VisualDensity.compact,
              ),

              // Invert Steering (Roll) Toggle
              IconButton(
                icon: Icon(
                  Icons.swap_horiz,
                  color: _invertRoll ? const Color(0xFFFFA502) : const Color(0xFF8290B8),
                  size: 18,
                ),
                tooltip: _invertRoll ? 'Steering: Inverted' : 'Steering: Normal',
                onPressed: () {
                  setState(() => _invertRoll = !_invertRoll);
                  _showToast(_invertRoll ? 'Steer Invert: ON' : 'Steer Invert: OFF');
                },
                visualDensity: VisualDensity.compact,
              ),

              // Invert Pitch Toggle
              IconButton(
                icon: Icon(
                  Icons.swap_vert,
                  color: _invertPitch ? const Color(0xFFFFA502) : const Color(0xFF8290B8),
                  size: 18,
                ),
                tooltip: _invertPitch ? 'Pitch: Inverted' : 'Pitch: Normal',
                onPressed: () {
                  setState(() => _invertPitch = !_invertPitch);
                  _showToast(_invertPitch ? 'Pitch Invert: ON' : 'Pitch Invert: OFF');
                },
                visualDensity: VisualDensity.compact,
              ),

              // Sensitivity Quick Toggle
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_sensitivity == 1.0) {
                      _sensitivity = 1.4;
                    } else if (_sensitivity == 1.4) {
                      _sensitivity = 2.0;
                    } else {
                      _sensitivity = 1.0;
                    }
                  });
                  _showToast('Sensitivity: ${_sensitivity}x');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2646),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_sensitivity}x',
                    style: const TextStyle(
                      color: Color(0xFF4F6BFF),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),

              if (_isConnected) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2646),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_rtt}ms',
                    style: const TextStyle(
                      color: Color(0xFF2ED573),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.power_settings_new, color: Color(0xFFFF4757), size: 18),
                  onPressed: _disconnect,
                  tooltip: 'Disconnect',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetupCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: _isLandscape ? 4 : 8),
      padding: EdgeInsets.all(_isLandscape ? 8 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFF12172B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2646)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _serverController,
                  decoration: const InputDecoration(
                    labelText: 'Laptop IP : Port',
                    labelStyle: TextStyle(color: Color(0xFF8290B8), fontSize: 11),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                    hintText: '192.168.1.X:8000',
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'Room Code',
                    labelStyle: TextStyle(color: Color(0xFF8290B8), fontSize: 11),
                    isDense: true,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                    hintText: '4-digits',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isConnecting ? null : _connect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F6BFF),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  _isConnecting ? '...' : 'Connect',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabs() {
    final modes = ['📱 Motion', '🎮 Gamepad', '🏎️ Wheel'];
    final tabHeight = _isLandscape ? 32.0 : 38.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: _isLandscape ? 3 : 6),
      height: tabHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF12172B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E2646)),
      ),
      child: Row(
        children: List.generate(modes.length, (idx) {
          final isSel = _selectedLayout == idx;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedLayout = idx);
                _haptic(duration: 20);
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFF4F6BFF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  modes[idx],
                  style: TextStyle(
                    color: isSel ? Colors.white : const Color(0xFF8290B8),
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // VIEW 1: MOTION & TILT (Fully Responsive for Landscape & Portrait)
  Widget _buildMotionView() {
    final calRoll = _smoothRoll - _offsetRoll;
    final calPitch = _smoothPitch - _offsetPitch;

    final bubbleX = (calRoll / 45.0).clamp(-1.0, 1.0);
    final bubbleY = (calPitch / 45.0).clamp(-1.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_isLandscape) {
          // LANDSCAPE: Dual-cockpit layout (Left: Telemetry & Spirit Level, Right: Giant Jump Target)
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Side: Spirit level + Telemetry + Calibrate
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12172B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF1E2646)),
                    ),
                    child: Row(
                      children: [
                        // Spirit Level Circle
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: _buildSpiritLevelCircle(bubbleX, bubbleY, 120),
                          ),
                        ),
                        // Telemetry info & Calibrate button
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _telemetryItem('Roll (Steer)', '${calRoll.toStringAsFixed(1)}°'),
                              _telemetryItem('Pitch (Tilt)', '${calPitch.toStringAsFixed(1)}°'),
                              OutlinedButton.icon(
                                onPressed: _calibrateNeutral,
                                icon: const Icon(Icons.center_focus_strong, color: Color(0xFF4F6BFF), size: 14),
                                label: const Text('Calibrate', style: TextStyle(color: Colors.white, fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  side: const BorderSide(color: Color(0xFF4F6BFF)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Right Side: Giant JUMP / BOOST Button
                Expanded(
                  flex: 2,
                  child: _buildJumpButton(isFullHeight: true),
                ),
              ],
            ),
          );
        } else {
          // PORTRAIT: Vertical stack
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Telemetry and Spirit Level
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12172B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF1E2646)),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: _buildSpiritLevelCircle(bubbleX, bubbleY, 150),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _telemetryItem('Roll (Steer)', '${calRoll.toStringAsFixed(1)}°'),
                            _telemetryItem('Pitch (Tilt)', '${calPitch.toStringAsFixed(1)}°'),
                            _telemetryItem('Jumps', '$_jumpCount'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Calibrate Neutral Button
                OutlinedButton.icon(
                  onPressed: _calibrateNeutral,
                  icon: const Icon(Icons.center_focus_strong, color: Color(0xFF4F6BFF), size: 16),
                  label: const Text('Calibrate Neutral Angle', style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF4F6BFF)),
                    minimumSize: const Size(double.infinity, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),

                const SizedBox(height: 8),

                // Giant JUMP Button
                SizedBox(
                  height: 80,
                  width: double.infinity,
                  child: _buildJumpButton(isFullHeight: false),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildSpiritLevelCircle(double bubbleX, double bubbleY, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF090C15),
        border: Border.all(color: const Color(0xFF222C54), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: size, height: 1, color: Colors.white10),
          Container(width: 1, height: size, color: Colors.white10),
          Container(
            width: size * 0.35,
            height: size * 0.35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
          ),
          Transform.translate(
            offset: Offset(bubbleX * (size * 0.36), bubbleY * (size * 0.36)),
            child: Container(
              width: size * 0.16,
              height: size * 0.16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _playerColors[_playerId % _playerColors.length],
                boxShadow: [
                  BoxShadow(
                    color: _playerColors[_playerId % _playerColors.length].withOpacity(0.8),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJumpButton({required bool isFullHeight}) {
    return GestureDetector(
      onTapDown: (_) => _triggerJump(),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF2ED573), Color(0xFF1B9E50)],
          ),
          boxShadow: [
            BoxShadow(color: const Color(0xFF2ED573).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 3)),
          ],
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'JUMP',
              style: TextStyle(
                color: Colors.white,
                fontSize: isFullHeight ? 24 : 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Shake phone or tap',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _telemetryItem(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF8290B8), fontSize: 10)),
        const SizedBox(height: 1),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  // VIEW 2: PRO GAMEPAD
  Widget _buildGamepadView() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: _isLandscape ? 6.0 : 16.0),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: _buildVirtualJoystick(),
            ),
          ),
          Expanded(
            child: Center(
              child: _buildABXYDiamond(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVirtualJoystick() {
    final size = _isLandscape ? 120.0 : 135.0;
    final radius = size / 2.0;

    return GestureDetector(
      onPanUpdate: (details) {
        final dx = details.localPosition.dx - radius;
        final dy = details.localPosition.dy - radius;
        final dist = math.sqrt(dx * dx + dy * dy);
        final clampedDist = math.min(dist, radius);
        final angle = math.atan2(dy, dx);

        setState(() {
          _stickX = (clampedDist / radius) * math.cos(angle);
          _stickY = (clampedDist / radius) * math.sin(angle);
        });
      },
      onPanEnd: (_) {
        setState(() {
          _stickX = 0;
          _stickY = 0;
        });
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF101428),
          border: Border.all(color: const Color(0xFF222C54), width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: Offset(_stickX * (radius * 0.65), _stickY * (radius * 0.65)),
              child: Container(
                width: size * 0.36,
                height: size * 0.36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF3B4C80),
                  boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 6)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildABXYDiamond() {
    final size = _isLandscape ? 120.0 : 135.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 0, child: _gamepadBtn('Y', const Color(0xFFFFA502))),
          Positioned(bottom: 0, child: _gamepadBtn('A', const Color(0xFF2ED573), action: _triggerJump)),
          Positioned(left: 0, child: _gamepadBtn('X', const Color(0xFF1E90FF))),
          Positioned(right: 0, child: _gamepadBtn('B', const Color(0xFFFF4757))),
        ],
      ),
    );
  }

  Widget _gamepadBtn(String label, Color col, {VoidCallback? action}) {
    final btnSize = _isLandscape ? 38.0 : 42.0;

    return GestureDetector(
      onTapDown: (_) {
        _buttons[label] = 1;
        action?.call();
        _haptic(duration: 40);
      },
      onTapUp: (_) => _buttons[label] = 0,
      onTapCancel: () => _buttons[label] = 0,
      child: Container(
        width: btnSize,
        height: btnSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF12172B),
          border: Border.all(color: col, width: 2),
          boxShadow: [BoxShadow(color: col.withOpacity(0.3), blurRadius: 6)],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: btnSize * 0.4),
        ),
      ),
    );
  }

  // VIEW 3: RACING WHEEL
  Widget _buildRacingView() {
    final wheelSize = _isLandscape ? 130.0 : 150.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: _isLandscape ? 6.0 : 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: GestureDetector(
                onPanUpdate: (details) {
                  final center = Offset(wheelSize / 2, wheelSize / 2);
                  final touch = details.localPosition;
                  final angle = math.atan2(touch.dy - center.dy, touch.dx - center.dx) * (180 / math.pi);
                  setState(() {
                    _wheelAngle = angle.clamp(-90.0, 90.0);
                  });
                },
                onPanEnd: (_) => setState(() => _wheelAngle = 0.0),
                child: Transform.rotate(
                  angle: (_wheelAngle * math.pi / 180),
                  child: Container(
                    width: wheelSize,
                    height: wheelSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF12172B),
                      border: Border.all(color: const Color(0xFF4F6BFF), width: 5),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF4F6BFF).withOpacity(0.3), blurRadius: 10),
                      ],
                    ),
                    child: const Icon(Icons.radio_button_checked, size: 36, color: Colors.white24),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTapDown: (_) {
                      setState(() => _gasPedal = 1.0);
                      _haptic(duration: 40);
                    },
                    onTapUp: (_) => setState(() => _gasPedal = 0.0),
                    onTapCancel: () => setState(() => _gasPedal = 0.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _gasPedal > 0 ? const Color(0xFF2ED573) : const Color(0xFF12172B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2ED573), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: const Text('GAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: GestureDetector(
                    onTapDown: (_) {
                      setState(() => _brakePedal = 1.0);
                      _haptic(duration: 40);
                    },
                    onTapUp: (_) => setState(() => _brakePedal = 0.0),
                    onTapCancel: () => setState(() => _brakePedal = 0.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _brakePedal > 0 ? const Color(0xFFFF4757) : const Color(0xFF12172B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFF4757), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: const Text('BRAKE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
