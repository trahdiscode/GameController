import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// ══════════════════════════════════════════════════════════════════════════════
// PALETTE: Luxury Frosted Mint & Emerald
// ══════════════════════════════════════════════════════════════════════════════
class EmeraldPalette {
  static const Color frostedMint = Color(0xFFD8F3DC);
  static const Color celadon     = Color(0xFFB7E4C7);
  static const Color celadon2    = Color(0xFF95D5B2);
  static const Color mintLeaf    = Color(0xFF74C69D);
  static const Color mintLeaf2   = Color(0xFF52B788);
  static const Color seaGreen    = Color(0xFF40916C);
  static const Color darkEmerald = Color(0xFF2D6A4F);
  static const Color pineTeal    = Color(0xFF1B4332);
  static const Color evergreen   = Color(0xFF081C15);

  // Neumorphic Surface & Shadow Tokens
  static const Color neuBg           = Color(0xFF0A1F18);
  static const Color neuSurface      = Color(0xFF0E281F);
  static const Color neuSurfaceHi    = Color(0xFF14392D);
  static const Color neuSurfaceLo    = Color(0xFF081812);
  static const Color neuLightShadow  = Color(0x3552B788);
  static const Color neuDarkShadow   = Color(0xE0000000);
  static const Color neuWellBg       = Color(0xFF05140F);
}

// ══════════════════════════════════════════════════════════════════════════════
// NEUMORPHIC DECORATION SYSTEM (Tactile Soft UI)
// ══════════════════════════════════════════════════════════════════════════════
class NeuDecor {
  static BoxDecoration raised({
    double radius = 16,
    BoxShape shape = BoxShape.rectangle,
    Color? surfaceColor,
    Border? border,
    double distance = 4.0,
    double blur = 8.0,
    Color? lightShadow,
    Color? darkShadow,
    Gradient? gradient,
  }) {
    final base = surfaceColor ?? EmeraldPalette.neuSurface;
    return BoxDecoration(
      shape: shape,
      borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
      color: base,
      gradient: gradient ??
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              EmeraldPalette.neuSurfaceHi,
              base,
              EmeraldPalette.neuSurfaceLo,
            ],
          ),
      border: border ??
          Border.all(
            color: EmeraldPalette.pineTeal.withOpacity(0.4),
            width: 1.0,
          ),
      boxShadow: [
        BoxShadow(
          color: lightShadow ?? EmeraldPalette.neuLightShadow,
          offset: Offset(-distance, -distance),
          blurRadius: blur,
        ),
        BoxShadow(
          color: darkShadow ?? EmeraldPalette.neuDarkShadow,
          offset: Offset(distance, distance),
          blurRadius: blur,
        ),
      ],
    );
  }

  static BoxDecoration recessed({
    double radius = 16,
    BoxShape shape = BoxShape.rectangle,
    Color? wellColor,
    Border? border,
    double distance = 3.0,
    double blur = 6.0,
  }) {
    final base = wellColor ?? EmeraldPalette.neuWellBg;
    return BoxDecoration(
      shape: shape,
      borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
      color: base,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF030D09),
          Color(0xFF061611),
          Color(0xFF0B241A),
        ],
      ),
      border: border ??
          Border.all(
            color: EmeraldPalette.pineTeal.withOpacity(0.55),
            width: 1.2,
          ),
      boxShadow: [
        BoxShadow(
          color: EmeraldPalette.neuDarkShadow.withOpacity(0.75),
          offset: Offset(distance, distance),
          blurRadius: blur,
        ),
        BoxShadow(
          color: EmeraldPalette.neuLightShadow.withOpacity(0.12),
          offset: Offset(-distance, -distance),
          blurRadius: blur,
        ),
      ],
    );
  }

  static BoxDecoration pressed({
    double radius = 16,
    BoxShape shape = BoxShape.rectangle,
    Color? surfaceColor,
    Border? border,
  }) {
    return BoxDecoration(
      shape: shape,
      borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
      color: surfaceColor ?? EmeraldPalette.neuWellBg,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF030D0A),
          Color(0xFF071B14),
          Color(0xFF0E2C22),
        ],
      ),
      border: border ??
          Border.all(
            color: EmeraldPalette.mintLeaf2.withOpacity(0.65),
            width: 1.2,
          ),
      boxShadow: const [
        BoxShadow(
          color: Color(0xCC000000),
          offset: Offset(2, 2),
          blurRadius: 4,
        ),
        BoxShadow(
          color: Color(0x2252B788),
          offset: Offset(-1, -1),
          blurRadius: 3,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// NEUMORPHIC TACTILE BUTTON WIDGET
// ══════════════════════════════════════════════════════════════════════════════
class NeuButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final double radius;
  final BoxShape shape;
  final EdgeInsetsGeometry padding;
  final bool isSelected;
  final Color? activeColor;
  final double? width;
  final double? height;

  const NeuButton({
    super.key,
    required this.child,
    this.onTap,
    this.radius = 12,
    this.shape = BoxShape.rectangle,
    this.padding = const EdgeInsets.all(8),
    this.isSelected = false,
    this.activeColor,
    this.width,
    this.height,
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _isDown = false;

  @override
  Widget build(BuildContext context) {
    final isDepressed = _isDown || widget.isSelected;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isDown = true),
      onTapUp: (_) {
        setState(() => _isDown = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isDown = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: widget.width,
        height: widget.height,
        padding: widget.padding,
        decoration: isDepressed
            ? NeuDecor.pressed(
                radius: widget.radius,
                shape: widget.shape,
                border: widget.isSelected
                    ? Border.all(color: widget.activeColor ?? EmeraldPalette.mintLeaf2, width: 1.4)
                    : null,
              )
            : NeuDecor.raised(
                radius: widget.radius,
                shape: widget.shape,
              ),
        child: widget.child,
      ),
    );
  }
}

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
        scaffoldBackgroundColor: EmeraldPalette.neuBg,
        colorScheme: const ColorScheme.dark(
          primary: EmeraldPalette.mintLeaf2,
          secondary: EmeraldPalette.celadon2,
          surface: EmeraldPalette.neuSurface,
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
  Color _statusColor = const Color(0xFFE74C3C);
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

  // Sensitivity & Inversion controls
  double _sensitivity = 1.0;
  bool _invertRoll = false;
  bool _invertPitch = false;

  // Virtual Gamepad State
  double _stickX = 0.0;
  double _stickY = 0.0;
  double _wheelAngle = 0.0;
  double _gasPedal = 0.0;
  double _brakePedal = 0.0;
  final Map<String, int> _buttons = {};
  bool _isJumpPressed = false;

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
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      _showToast('Locked to Landscape');
    } else if (_orientationMode == 2) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      _showToast('Locked to Portrait');
    } else {
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
        content: Text(msg, style: const TextStyle(color: EmeraldPalette.frostedMint, fontWeight: FontWeight.bold)),
        duration: const Duration(seconds: 1),
        backgroundColor: EmeraldPalette.pineTeal,
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
        targetRoll = math.asin(-normY) * (180.0 / math.pi);
        targetPitch = math.asin(normX) * (180.0 / math.pi);
      } else {
        targetRoll = math.asin(normX) * (180.0 / math.pi);
        targetPitch = math.asin(normY) * (180.0 / math.pi);
      }

      // Snappy and responsive Exponential Moving Average (alpha = 0.40)
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
      _statusColor = EmeraldPalette.celadon2;
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
          _statusColor = EmeraldPalette.mintLeaf2;
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
      _statusColor = const Color(0xFFE74C3C);
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
      _statusColor = const Color(0xFFE74C3C);
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
      backgroundColor: EmeraldPalette.neuBg,
      body: SafeArea(
        child: Container(
          color: EmeraldPalette.neuBg,
          child: Column(
            children: [
              // Neumorphic Top Bar
              _buildTopBar(),

              // Neumorphic Setup Panel
              if (!_isConnected) _buildSetupCard(),

              // Neumorphic Mode Selector Tabs
              _buildModeTabs(),

              // Main Active Neumorphic View
              Expanded(
                child: _selectedLayout == 0
                    ? _buildMotionView()
                    : (_selectedLayout == 1 ? _buildGamepadView() : _buildRacingView()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final padVert = _isLandscape ? 6.0 : 8.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: padVert),
      decoration: const BoxDecoration(
        color: EmeraldPalette.neuBg,
        boxShadow: [
          BoxShadow(
            color: EmeraldPalette.neuDarkShadow,
            offset: Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Neumorphic Connection Status Pill (Recessed well)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: NeuDecor.recessed(radius: 20, distance: 2, blur: 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: _statusColor.withOpacity(0.85), blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _statusText,
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Actions Row (Orientation Lock, Invert Roll, Invert Pitch, Sensitivity, Latency, Disconnect)
          Row(
            children: [
              // Screen Rotation Lock
              NeuButton(
                radius: 10,
                padding: const EdgeInsets.all(6),
                isSelected: _orientationMode != 0,
                onTap: _cycleOrientation,
                child: Icon(
                  _orientationMode == 1
                      ? Icons.stay_current_landscape
                      : (_orientationMode == 2 ? Icons.stay_current_portrait : Icons.screen_rotation),
                  color: _orientationMode == 0 ? EmeraldPalette.celadon2 : EmeraldPalette.frostedMint,
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),

              // Invert Steering (Roll)
              NeuButton(
                radius: 10,
                padding: const EdgeInsets.all(6),
                isSelected: _invertRoll,
                onTap: () {
                  setState(() => _invertRoll = !_invertRoll);
                  _showToast(_invertRoll ? 'Steer Invert: ON' : 'Steer Invert: OFF');
                },
                child: Icon(
                  Icons.swap_horiz,
                  color: _invertRoll ? EmeraldPalette.frostedMint : EmeraldPalette.celadon2,
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),

              // Invert Pitch
              NeuButton(
                radius: 10,
                padding: const EdgeInsets.all(6),
                isSelected: _invertPitch,
                onTap: () {
                  setState(() => _invertPitch = !_invertPitch);
                  _showToast(_invertPitch ? 'Pitch Invert: ON' : 'Pitch Invert: OFF');
                },
                child: Icon(
                  Icons.swap_vert,
                  color: _invertPitch ? EmeraldPalette.frostedMint : EmeraldPalette.celadon2,
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),

              // Sensitivity Quick Toggle
              NeuButton(
                radius: 10,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                isSelected: _sensitivity > 1.0,
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
                child: Text(
                  '${_sensitivity}x',
                  style: const TextStyle(
                    color: EmeraldPalette.mintLeaf2,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),

              if (_isConnected) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: NeuDecor.recessed(radius: 10, distance: 2, blur: 4),
                  child: Text(
                    '${_rtt}ms',
                    style: const TextStyle(
                      color: EmeraldPalette.mintLeaf,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                NeuButton(
                  radius: 10,
                  padding: const EdgeInsets.all(6),
                  onTap: _disconnect,
                  child: const Icon(Icons.power_settings_new, color: Color(0xFFE74C3C), size: 16),
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
      margin: EdgeInsets.symmetric(horizontal: 14, vertical: _isLandscape ? 4 : 8),
      padding: EdgeInsets.all(_isLandscape ? 10 : 14),
      decoration: NeuDecor.raised(radius: 18),
      child: Row(
        children: [
          // Neumorphic Input: Laptop IP
          Expanded(
            flex: 3,
            child: Container(
              decoration: NeuDecor.recessed(radius: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: TextField(
                controller: _serverController,
                decoration: const InputDecoration(
                  labelText: 'Laptop IP : Port',
                  labelStyle: TextStyle(color: EmeraldPalette.celadon2, fontSize: 11),
                  isDense: true,
                  border: InputBorder.none,
                  hintText: '192.168.1.X:8000',
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                ),
                style: const TextStyle(color: EmeraldPalette.frostedMint, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Neumorphic Input: Room Code
          Expanded(
            flex: 2,
            child: Container(
              decoration: NeuDecor.recessed(radius: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Room Code',
                  labelStyle: TextStyle(color: EmeraldPalette.celadon2, fontSize: 11),
                  isDense: true,
                  counterText: '',
                  border: InputBorder.none,
                  hintText: '4-digits',
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                ),
                style: const TextStyle(
                  color: EmeraldPalette.frostedMint,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Neumorphic Connect CTA Button
          NeuButton(
            radius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            onTap: _isConnecting ? null : _connect,
            child: Text(
              _isConnecting ? '...' : 'Connect',
              style: const TextStyle(
                color: EmeraldPalette.frostedMint,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabs() {
    final modes = ['📱 Motion', '🎮 Gamepad', '🏎️ Wheel'];
    final tabHeight = _isLandscape ? 34.0 : 42.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14, vertical: _isLandscape ? 4 : 6),
      height: tabHeight,
      padding: const EdgeInsets.all(3),
      decoration: NeuDecor.recessed(radius: 14, distance: 2, blur: 4),
      child: Row(
        children: List.generate(modes.length, (idx) {
          final isSel = _selectedLayout == idx;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedLayout = idx);
                _haptic(duration: 20);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                decoration: isSel
                    ? NeuDecor.raised(
                        radius: 10,
                        surfaceColor: EmeraldPalette.neuSurface,
                        border: Border.all(color: EmeraldPalette.mintLeaf2.withOpacity(0.5), width: 1.0),
                        lightShadow: EmeraldPalette.neuLightShadow.withOpacity(0.4),
                      )
                    : null,
                child: Text(
                  modes[idx],
                  style: TextStyle(
                    color: isSel ? EmeraldPalette.frostedMint : EmeraldPalette.celadon2.withOpacity(0.65),
                    fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                    letterSpacing: 0.3,
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

  // ══════════════════════════════════════════════════════════════════════════
  // VIEW 1: NEUMORPHIC MOTION & TILT (Tactile Spirit Level Cockpit)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMotionView() {
    final calRoll = _smoothRoll - _offsetRoll;
    final calPitch = _smoothPitch - _offsetPitch;

    final bubbleX = (calRoll / 45.0).clamp(-1.0, 1.0);
    final bubbleY = (calPitch / 45.0).clamp(-1.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_isLandscape) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left: Neumorphic Spirit Level & Telemetry Deck
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: NeuDecor.raised(radius: 20),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: _buildSpiritLevelCircle(bubbleX, bubbleY, 120),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _telemetryItem('Roll (Steer)', '${calRoll.toStringAsFixed(1)}°'),
                              _telemetryItem('Pitch (Tilt)', '${calPitch.toStringAsFixed(1)}°'),
                              NeuButton(
                                radius: 8,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                onTap: _calibrateNeutral,
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.center_focus_strong, color: EmeraldPalette.mintLeaf2, size: 13),
                                    SizedBox(width: 4),
                                    Text('Calibrate', style: TextStyle(color: EmeraldPalette.frostedMint, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Right: Neumorphic Giant Jump Target
                Expanded(
                  flex: 2,
                  child: _buildJumpButton(isFullHeight: true),
                ),
              ],
            ),
          );
        } else {
          // Portrait layout
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            child: Column(
              children: [
                // Neumorphic Main Telemetry Plate
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: NeuDecor.raised(radius: 22),
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: _buildSpiritLevelCircle(bubbleX, bubbleY, 160),
                          ),
                        ),
                        const SizedBox(height: 8),
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

                const SizedBox(height: 12),

                // Neumorphic Calibrate Neutral Button
                NeuButton(
                  radius: 14,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onTap: _calibrateNeutral,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.center_focus_strong, color: EmeraldPalette.mintLeaf2, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Calibrate Neutral Angle',
                        style: TextStyle(
                          color: EmeraldPalette.frostedMint,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Giant Neumorphic JUMP Button
                SizedBox(
                  height: 90,
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

  // Recessed Neumorphic Spirit Level Dish with Floating 3D Bubble
  Widget _buildSpiritLevelCircle(double bubbleX, double bubbleY, double size) {
    return Container(
      width: size,
      height: size,
      decoration: NeuDecor.recessed(shape: BoxShape.circle, distance: 4, blur: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Engraved Concentric Rings
          Container(
            width: size * 0.70,
            height: size * 0.70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: EmeraldPalette.pineTeal.withOpacity(0.35), width: 1.0),
            ),
          ),
          Container(
            width: size * 0.38,
            height: size * 0.38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: EmeraldPalette.seaGreen.withOpacity(0.4), width: 1.0),
            ),
          ),

          // Engraved Crosshairs
          Container(width: size * 0.85, height: 1, color: EmeraldPalette.pineTeal.withOpacity(0.5)),
          Container(width: 1, height: size * 0.85, color: EmeraldPalette.pineTeal.withOpacity(0.5)),

          // 3D Extruded Radiant Level Bubble
          Transform.translate(
            offset: Offset(bubbleX * (size * 0.36), bubbleY * (size * 0.36)),
            child: Container(
              width: size * 0.19,
              height: size * 0.19,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.35, -0.35),
                  colors: [
                    EmeraldPalette.frostedMint,
                    EmeraldPalette.mintLeaf2,
                    EmeraldPalette.darkEmerald,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: EmeraldPalette.mintLeaf2.withOpacity(0.85),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                  const BoxShadow(
                    color: Color(0xCC000000),
                    offset: Offset(3, 3),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Neumorphic JUMP Button with Physical Sinking Interaction
  Widget _buildJumpButton({required bool isFullHeight}) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isJumpPressed = true);
        _triggerJump();
      },
      onTapUp: (_) => setState(() => _isJumpPressed = false),
      onTapCancel: () => setState(() => _isJumpPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: _isJumpPressed
            ? NeuDecor.pressed(
                radius: 20,
                surfaceColor: const Color(0xFF071912),
                border: Border.all(color: EmeraldPalette.mintLeaf2, width: 2.0),
              )
            : NeuDecor.raised(
                radius: 20,
                surfaceColor: EmeraldPalette.neuSurface,
                border: Border.all(color: EmeraldPalette.mintLeaf2.withOpacity(0.7), width: 1.6),
                lightShadow: EmeraldPalette.mintLeaf2.withOpacity(0.4),
                darkShadow: const Color(0xF5000000),
                distance: 5.0,
                blur: 10.0,
              ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'JUMP',
              style: TextStyle(
                color: _isJumpPressed ? EmeraldPalette.mintLeaf2 : EmeraldPalette.frostedMint,
                fontSize: isFullHeight ? 28 : 25,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                shadows: [
                  Shadow(
                    color: EmeraldPalette.mintLeaf2.withOpacity(0.7),
                    blurRadius: _isJumpPressed ? 14 : 6,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Shake phone or press',
              style: TextStyle(
                color: EmeraldPalette.celadon2.withOpacity(0.75),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _telemetryItem(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: EmeraldPalette.celadon2, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: NeuDecor.recessed(radius: 8, distance: 2, blur: 4),
          child: Text(
            val,
            style: const TextStyle(
              color: EmeraldPalette.frostedMint,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VIEW 2: NEUMORPHIC PRO GAMEPAD (Concave Well & Raised Tactile Buttons)
  // ══════════════════════════════════════════════════════════════════════════
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

  // Neumorphic Concave Analog Stick Well with 3D Thumb Cap
  Widget _buildVirtualJoystick() {
    final size = _isLandscape ? 130.0 : 150.0;
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
        decoration: NeuDecor.recessed(shape: BoxShape.circle, distance: 4, blur: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center Deadzone Ring
            Container(
              width: size * 0.35,
              height: size * 0.35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: EmeraldPalette.pineTeal.withOpacity(0.4), width: 1),
              ),
            ),
            // Tactile Convex Thumb Knob
            Transform.translate(
              offset: Offset(_stickX * (radius * 0.65), _stickY * (radius * 0.65)),
              child: Container(
                width: size * 0.40,
                height: size * 0.40,
                decoration: NeuDecor.raised(
                  shape: BoxShape.circle,
                  border: Border.all(color: EmeraldPalette.mintLeaf2.withOpacity(0.6), width: 1.5),
                  lightShadow: EmeraldPalette.mintLeaf2.withOpacity(0.4),
                  distance: 3,
                  blur: 6,
                ),
                child: Center(
                  child: Container(
                    width: size * 0.16,
                    height: size * 0.16,
                    decoration: NeuDecor.recessed(shape: BoxShape.circle, distance: 1.5, blur: 3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Neumorphic ABXY Diamond Cluster
  Widget _buildABXYDiamond() {
    final size = _isLandscape ? 120.0 : 145.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 0, child: _gamepadBtn('Y', EmeraldPalette.frostedMint)),
          Positioned(bottom: 0, child: _gamepadBtn('A', EmeraldPalette.mintLeaf2, action: _triggerJump)),
          Positioned(left: 0, child: _gamepadBtn('X', EmeraldPalette.celadon2)),
          Positioned(right: 0, child: _gamepadBtn('B', EmeraldPalette.mintLeaf)),
        ],
      ),
    );
  }

  Widget _gamepadBtn(String label, Color col, {VoidCallback? action}) {
    final btnSize = _isLandscape ? 40.0 : 46.0;
    final isDown = _buttons[label] == 1;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _buttons[label] = 1);
        action?.call();
        _haptic(duration: 40);
      },
      onTapUp: (_) => setState(() => _buttons[label] = 0),
      onTapCancel: () => setState(() => _buttons[label] = 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: btnSize,
        height: btnSize,
        decoration: isDown
            ? NeuDecor.pressed(
                shape: BoxShape.circle,
                border: Border.all(color: col, width: 2),
              )
            : NeuDecor.raised(
                shape: BoxShape.circle,
                border: Border.all(color: col.withOpacity(0.8), width: 1.6),
                lightShadow: col.withOpacity(0.35),
                distance: 3.5,
                blur: 7,
              ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: col,
            fontWeight: FontWeight.w900,
            fontSize: btnSize * 0.42,
            shadows: isDown
                ? [Shadow(color: col.withOpacity(0.8), blurRadius: 8)]
                : null,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VIEW 3: NEUMORPHIC RACING WHEEL (Tactile Hub & Tread Pedals)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRacingView() {
    final wheelSize = _isLandscape ? 135.0 : 160.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: _isLandscape ? 6.0 : 16.0),
      child: Row(
        children: [
          // Neumorphic Tactile Steering Wheel
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
                    decoration: NeuDecor.raised(
                      shape: BoxShape.circle,
                      border: Border.all(color: EmeraldPalette.mintLeaf2, width: 4),
                      lightShadow: EmeraldPalette.mintLeaf2.withOpacity(0.35),
                      distance: 5,
                      blur: 10,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Spokes
                        Container(width: wheelSize * 0.75, height: 8, decoration: NeuDecor.recessed(radius: 4)),
                        Container(width: 8, height: wheelSize * 0.4, margin: EdgeInsets.only(top: wheelSize * 0.35), decoration: NeuDecor.recessed(radius: 4)),
                        // Center Horn Hub
                        Container(
                          width: wheelSize * 0.4,
                          height: wheelSize * 0.4,
                          decoration: NeuDecor.raised(
                            shape: BoxShape.circle,
                            border: Border.all(color: EmeraldPalette.celadon2.withOpacity(0.5), width: 1.5),
                          ),
                          child: const Icon(Icons.speed, size: 28, color: EmeraldPalette.mintLeaf2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Neumorphic Pedals (Gas & Brake)
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Gas Pedal
                Expanded(
                  child: GestureDetector(
                    onTapDown: (_) {
                      setState(() => _gasPedal = 1.0);
                      _haptic(duration: 40);
                    },
                    onTapUp: (_) => setState(() => _gasPedal = 0.0),
                    onTapCancel: () => setState(() => _gasPedal = 0.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      decoration: _gasPedal > 0
                          ? NeuDecor.pressed(
                              radius: 14,
                              surfaceColor: const Color(0xFF092419),
                              border: Border.all(color: EmeraldPalette.mintLeaf2, width: 2),
                            )
                          : NeuDecor.raised(
                              radius: 14,
                              border: Border.all(color: EmeraldPalette.mintLeaf2.withOpacity(0.7), width: 1.5),
                            ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up,
                            color: _gasPedal > 0 ? EmeraldPalette.frostedMint : EmeraldPalette.mintLeaf2,
                            size: 24,
                          ),
                          Text(
                            'GAS',
                            style: TextStyle(
                              color: _gasPedal > 0 ? EmeraldPalette.frostedMint : EmeraldPalette.celadon2,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Brake Pedal
                Expanded(
                  child: GestureDetector(
                    onTapDown: (_) {
                      setState(() => _brakePedal = 1.0);
                      _haptic(duration: 40);
                    },
                    onTapUp: (_) => setState(() => _brakePedal = 0.0),
                    onTapCancel: () => setState(() => _brakePedal = 0.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      decoration: _brakePedal > 0
                          ? NeuDecor.pressed(
                              radius: 14,
                              surfaceColor: const Color(0xFF280B0B),
                              border: Border.all(color: const Color(0xFFE74C3C), width: 2),
                            )
                          : NeuDecor.raised(
                              radius: 14,
                              border: Border.all(color: const Color(0xFFE74C3C).withOpacity(0.7), width: 1.5),
                            ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pause,
                            color: _brakePedal > 0 ? Colors.white : const Color(0xFFE74C3C),
                            size: 20,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'BRAKE',
                            style: TextStyle(
                              color: _brakePedal > 0 ? Colors.white : const Color(0xFFE74C3C),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
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
