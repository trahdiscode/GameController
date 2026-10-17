import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// ══════════════════════════════════════════════════════════════════════════════
// NEUMORPHIC THEME SYSTEM (Light & Dark Soft UI Architecture)
// ══════════════════════════════════════════════════════════════════════════════
class NeuTheme {
  final bool isDark;

  const NeuTheme({this.isDark = false});
  factory NeuTheme.dark() => const NeuTheme(isDark: true);
  factory NeuTheme.light() => const NeuTheme(isDark: false);

  // Accent Color (Vibrant Cyan / Blue)
  Color get accent => isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB);

  // Base Canvas & Neutral Surfaces
  Color get bg => isDark ? const Color(0xFF14171C) : const Color(0xFFE9EDF2);
  Color get surface => isDark ? const Color(0xFF1A1D23) : const Color(0xFFE9EDF2);
  Color get surfaceLight => isDark ? const Color(0xFF242831) : const Color(0xFFFFFFFF);
  Color get surfaceDark => isDark ? const Color(0xFF111317) : const Color(0xFFDFE4EC);

  // Soft Ambient Shadows (Light Source: Top-Left)
  Color get shadowLight => isDark ? const Color(0x1AFFFFFF) : const Color(0xF5FFFFFF);
  Color get shadowDiffuse => isDark ? const Color(0x80000000) : const Color(0x1A2D3E50);
  Color get shadowContact => isDark ? const Color(0x40000000) : const Color(0x0E2D3E50);

  // Carved / Recessed Wells
  Color get wellBg => isDark ? const Color(0xFF101216) : const Color(0xFFE1E6EE);
  Color get wellInnerDark => isDark ? const Color(0x99000000) : const Color(0x142D3E50);

  // Monochromatic Typography & Details
  Color get textPrimary => isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
  Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
  Color get textMuted => isDark ? const Color(0xFF64748B) : const Color(0xFF64748B);
  Color get textLight => isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8);

  // Status Dots
  Color get dotConnected => const Color(0xFF22C55E);
  Color get dotDisconnected => const Color(0xFFEF4444);

  // Raised / Extruded Plate Decoration
  BoxDecoration raised({
    double radius = 18,
    BoxShape shape = BoxShape.rectangle,
    Color? surfaceColor,
    Border? border,
    double distance = 5.0,
    double blur = 14.0,
    Gradient? gradient,
  }) {
    final base = surfaceColor ?? surface;
    return BoxDecoration(
      shape: shape,
      borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
      color: base,
      gradient: gradient ??
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              surfaceLight.withOpacity(isDark ? 0.35 : 0.9),
              base,
              surfaceDark,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
      border: border ??
          Border.all(
            color: (isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.4)),
            width: 0.5,
          ),
      boxShadow: [
        BoxShadow(
          color: shadowLight,
          offset: Offset(-distance, -distance),
          blurRadius: blur,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: shadowDiffuse,
          offset: Offset(distance, distance),
          blurRadius: blur,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: shadowContact,
          offset: Offset(distance * 0.4, distance * 0.4),
          blurRadius: blur * 0.35,
          spreadRadius: 0,
        ),
      ],
    );
  }

  // Recessed / Carved Well Decoration
  BoxDecoration recessed({
    double radius = 16,
    BoxShape shape = BoxShape.rectangle,
    Color? wellColor,
    Border? border,
    double distance = 3.0,
    double blur = 7.0,
  }) {
    final base = wellColor ?? wellBg;
    return BoxDecoration(
      shape: shape,
      borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
      color: base,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                const Color(0xFF0A0C0F),
                base,
                const Color(0xFF1E2128),
              ]
            : [
                const Color(0xFFD6DBE4),
                base,
                surfaceLight.withOpacity(0.7),
              ],
        stops: const [0.0, 0.45, 1.0],
      ),
      border: border ??
          Border.all(
            color: isDark ? const Color(0xFF252933) : const Color(0xFFD0D6E0).withOpacity(0.8),
            width: 0.8,
          ),
      boxShadow: [
        BoxShadow(
          color: wellInnerDark,
          offset: Offset(distance, distance),
          blurRadius: blur,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: shadowLight,
          offset: Offset(-distance, -distance),
          blurRadius: blur,
          spreadRadius: 0,
        ),
      ],
    );
  }

  // Pressed / Depressed Plate Decoration
  BoxDecoration pressed({
    double radius = 16,
    BoxShape shape = BoxShape.rectangle,
    Color? surfaceColor,
    Border? border,
  }) {
    return BoxDecoration(
      shape: shape,
      borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
      color: surfaceColor ?? wellBg,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [
                Color(0xFF090A0D),
                Color(0xFF14171D),
                Color(0xFF222630),
              ]
            : const [
                Color(0xFFD3D8E2),
                Color(0xFFDFE4ED),
                Color(0xFFEEF2F8),
              ],
        stops: const [0.0, 0.5, 1.0],
      ),
      border: border ??
          Border.all(
            color: isDark ? const Color(0xFF282D37) : const Color(0xFFC7CED8),
            width: 0.8,
          ),
      boxShadow: [
        BoxShadow(
          color: isDark ? const Color(0x80000000) : const Color(0x182D3E50),
          offset: const Offset(2.0, 2.0),
          blurRadius: 5.0,
        ),
        BoxShadow(
          color: isDark ? const Color(0x14FFFFFF) : const Color(0xE6FFFFFF),
          offset: const Offset(-2.0, -2.0),
          blurRadius: 5.0,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MINIMAL NEUMORPHIC BUTTON WIDGET
// ══════════════════════════════════════════════════════════════════════════════
class NeuButton extends StatefulWidget {
  final NeuTheme theme;
  final VoidCallback? onTap;
  final Widget child;
  final double radius;
  final BoxShape shape;
  final EdgeInsetsGeometry padding;
  final bool isSelected;
  final double? width;
  final double? height;

  const NeuButton({
    super.key,
    required this.theme,
    required this.child,
    this.onTap,
    this.radius = 12,
    this.shape = BoxShape.rectangle,
    this.padding = const EdgeInsets.all(8),
    this.isSelected = false,
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
            ? widget.theme.pressed(
                radius: widget.radius,
                shape: widget.shape,
                border: widget.isSelected
                    ? Border.all(color: widget.theme.textSecondary.withOpacity(0.4), width: 1.0)
                    : null,
              )
            : widget.theme.raised(
                radius: widget.radius,
                shape: widget.shape,
                distance: 3.5,
                blur: 8.0,
              ),
        child: widget.child,
      ),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const TiltArenaApp());
}

class TiltArenaApp extends StatelessWidget {
  const TiltArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Tilt Arena Controller',
      debugShowCheckedModeBanner: false,
      home: ControllerScreen(),
    );
  }
}

class ControllerScreen extends StatefulWidget {
  const ControllerScreen({super.key});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  // Theme Mode State (Persisted)
  bool _isDarkMode = false;

  // Input Controllers
  final TextEditingController _serverController = TextEditingController(text: '172.17.176.166:8000');
  final TextEditingController _codeController = TextEditingController();

  // Connection State
  WebSocketChannel? _channel;
  StreamSubscription? _wsSubscription;
  bool _isConnected = false;
  bool _isConnecting = false;
  String _statusText = 'Disconnected';
  Color _statusColor = const Color(0xFFEF4444);
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
  bool _isLandscape = true;

  // Sensitivity & Inversion controls (Built-in reversed natural steering default)
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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
    final savedDarkMode = prefs.getBool('is_dark_mode');

    if (savedServer != null && savedServer.isNotEmpty) {
      _serverController.text = savedServer;
    }
    if (savedCode != null && savedCode.isNotEmpty) {
      _codeController.text = savedCode;
    }
    if (savedOffP != null) _offsetPitch = savedOffP;
    if (savedOffR != null) _offsetRoll = savedOffR;
    if (savedDarkMode != null) _isDarkMode = savedDarkMode;
    setState(() {});
  }

  void _toggleDarkMode() async {
    setState(() => _isDarkMode = !_isDarkMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    _haptic(duration: 25);
    _showToast(_isDarkMode ? 'Dark Mode' : 'Light Mode');
  }



  void _showToast(String msg) {
    if (!mounted) return;
    final theme = NeuTheme(isDark: _isDarkMode);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold)),
        duration: const Duration(seconds: 1),
        backgroundColor: theme.wellBg,
        behavior: SnackBarBehavior.floating,
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

  void _onQrCodeScanned(String raw) {
    raw = raw.trim();
    String? foundHost;
    String? foundCode;

    try {
      final uri = Uri.parse(raw);
      if (uri.host.isNotEmpty) {
        foundHost = uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
      }
      if (uri.queryParameters.containsKey('code')) {
        foundCode = uri.queryParameters['code'];
      }
    } catch (_) {}

    // Fallbacks if not standard URL
    if (foundCode == null) {
      final codeMatch = RegExp(r'code=(\d{4})').firstMatch(raw);
      if (codeMatch != null) {
        foundCode = codeMatch.group(1);
      } else if (RegExp(r'^\d{4}$').hasMatch(raw)) {
        foundCode = raw;
      }
    }

    if (foundHost == null) {
      final hostMatch = RegExp(r'https?://([^/?#]+)').firstMatch(raw);
      if (hostMatch != null) {
        foundHost = hostMatch.group(1);
      }
    }

    bool updated = false;
    if (foundHost != null && foundHost.isNotEmpty) {
      _serverController.text = foundHost;
      updated = true;
    }
    if (foundCode != null && foundCode.isNotEmpty) {
      _codeController.text = foundCode;
      updated = true;
    }

    if (updated) {
      _haptic(duration: 80);
      _showToast('QR Scanned! Room: ${_codeController.text}');
      if (_codeController.text.isNotEmpty) {
        _connect();
      }
    } else {
      _showToast('Could not read room code from QR');
    }
  }

  void _openQrScanner() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: _QrScannerSheet(
          isDark: _isDarkMode,
          onScanned: (val) {
            Navigator.of(ctx).pop();
            _onQrCodeScanned(val);
          },
        ),
      ),
    );
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
    final theme = NeuTheme(isDark: _isDarkMode);
    setState(() {
      _isConnecting = true;
      _statusText = 'Connecting...';
      _statusColor = theme.textMuted;
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
      final theme = NeuTheme(isDark: _isDarkMode);

      if (type == 'hello') {
        setState(() {
          _playerId = msg['id'] ?? 1;
          _isConnected = true;
          _isConnecting = false;
          _reconnectAttempts = 0;
          _statusText = 'P$_playerId Connected';
          _statusColor = theme.dotConnected;
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
    final theme = NeuTheme(isDark: _isDarkMode);
    setState(() {
      _isConnected = false;
      _isConnecting = false;
      _statusText = 'Disconnected';
      _statusColor = theme.dotDisconnected;
    });
  }

  void _handleDisconnect() {
    _streamTimer?.cancel();
    _pingTimer?.cancel();

    if (_manualDisconnect) return;

    final theme = NeuTheme(isDark: _isDarkMode);
    setState(() {
      _isConnected = false;
      _isConnecting = false;
      _statusText = 'Reconnecting...';
      _statusColor = theme.dotDisconnected;
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
    // Built-in reversed steering for natural landscape steering
    double calRoll = -(_smoothRoll - _offsetRoll) * _sensitivity;

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
    final theme = NeuTheme(isDark: _isDarkMode);

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Container(
          color: theme.bg,
          child: Column(
            children: [
              // Clean, Professional Minimal Top Bar with Embedded Mode Selector
              _buildTopBar(theme),

              // Setup Panel (only when disconnected)
              if (!_isConnected) _buildSetupCard(theme),

              // Main Active Neumorphic View
              Expanded(
                child: _selectedLayout == 0
                    ? _buildMotionView(theme)
                    : (_selectedLayout == 1 ? _buildGamepadView(theme) : _buildRacingView(theme)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleInvertRoll() async {
    setState(() => _invertRoll = !_invertRoll);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('invert_roll', _invertRoll);
    _haptic(duration: 25);
    _showToast(_invertRoll ? 'Steer: Inverted (Alt)' : 'Steer: Natural');
  }

  Widget _buildTopBar(NeuTheme theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: _isLandscape ? 5.0 : 8.0),
      color: theme.bg,
      child: Row(
        children: [
          // 1. Connection & Latency Badge
          _buildStatusBadge(theme),

          const SizedBox(width: 10),

          // 2. Embedded Mode Tabs in Center
          Expanded(
            child: Center(
              child: _buildEmbeddedModeTabs(theme),
            ),
          ),

          const SizedBox(width: 10),

          // 3. Compact Quick Controls: Steer Invert Chip + Settings Cog + (Disconnect)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quick Steer Invert Chip
              NeuButton(
                theme: theme,
                radius: 10,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                isSelected: _invertRoll,
                onTap: _toggleInvertRoll,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      color: _invertRoll ? theme.accent : theme.textMuted,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _invertRoll ? 'INVERT' : 'STEER',
                      style: TextStyle(
                        color: _invertRoll ? theme.accent : theme.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Settings Cog (Opens Settings Sheet)
              NeuButton(
                theme: theme,
                radius: 10,
                padding: const EdgeInsets.all(7),
                onTap: () => _openSettingsSheet(theme),
                child: Icon(
                  Icons.tune_rounded,
                  color: theme.textSecondary,
                  size: 16,
                ),
              ),

              if (_isConnected) ...[
                const SizedBox(width: 8),
                NeuButton(
                  theme: theme,
                  radius: 10,
                  padding: const EdgeInsets.all(7),
                  onTap: _disconnect,
                  child: const Icon(
                    Icons.power_settings_new_rounded,
                    color: Color(0xFFEF4444),
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(NeuTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: theme.recessed(radius: 16, distance: 1.5, blur: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: _statusColor.withOpacity(0.6), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _isConnected ? 'P$_playerId • ${_rtt}ms' : _statusText,
            style: TextStyle(
              color: theme.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              fontSize: 11,
              fontFamily: _isConnected ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmbeddedModeTabs(NeuTheme theme) {
    final modes = ['📱 Motion', '🎮 Gamepad', '🏎️ Wheel'];

    return Container(
      constraints: const BoxConstraints(maxWidth: 310),
      height: 32,
      padding: const EdgeInsets.all(2.5),
      decoration: theme.recessed(radius: 10, distance: 1.5, blur: 4.0),
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
                duration: const Duration(milliseconds: 140),
                alignment: Alignment.center,
                decoration: isSel
                    ? theme.raised(
                        radius: 8,
                        distance: 2.0,
                        blur: 5.0,
                        border: Border.all(color: theme.accent.withOpacity(0.35), width: 0.8),
                      )
                    : const BoxDecoration(),
                child: Text(
                  modes[idx],
                  style: TextStyle(
                    color: isSel ? theme.textPrimary : theme.textMuted,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _openSettingsSheet(NeuTheme theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final t = NeuTheme(isDark: _isDarkMode);
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: t.bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: t.textSecondary.withOpacity(0.2))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: t.textMuted.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune_rounded, color: t.accent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Controller Settings',
                            style: TextStyle(
                              color: t.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: t.textMuted, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Setting 1: Steer Invert (Roll)
                  _buildSettingRow(
                    theme: t,
                    icon: Icons.swap_horiz_rounded,
                    title: 'Steering Invert (Roll)',
                    subtitle: _invertRoll ? 'Inverted (Alternative)' : 'Natural (Default Reversed)',
                    trailing: Switch(
                      value: _invertRoll,
                      activeColor: t.accent,
                      onChanged: (val) {
                        setState(() => _invertRoll = val);
                        setSheetState(() {});
                        _haptic(duration: 20);
                      },
                    ),
                  ),

                  // Setting 2: Pitch Invert
                  _buildSettingRow(
                    theme: t,
                    icon: Icons.swap_vert_rounded,
                    title: 'Pitch Invert (Forward/Back)',
                    subtitle: _invertPitch ? 'Inverted' : 'Natural',
                    trailing: Switch(
                      value: _invertPitch,
                      activeColor: t.accent,
                      onChanged: (val) {
                        setState(() => _invertPitch = val);
                        setSheetState(() {});
                        _haptic(duration: 20);
                      },
                    ),
                  ),

                  // Setting 3: Sensitivity
                  _buildSettingRow(
                    theme: t,
                    icon: Icons.speed_rounded,
                    title: 'Tilt Sensitivity',
                    subtitle: 'Current: ${_sensitivity}x',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [1.0, 1.4, 2.0].map((s) {
                        final isSel = _sensitivity == s;
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _sensitivity = s);
                              setSheetState(() {});
                              _haptic(duration: 20);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: isSel
                                  ? t.pressed(radius: 8)
                                  : t.raised(radius: 8, distance: 2.0, blur: 4.0),
                              child: Text(
                                '${s}x',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isSel ? t.accent : t.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Setting 4: Theme Toggle & Calibrate
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: NeuButton(
                            theme: t,
                            radius: 12,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            onTap: () {
                              _toggleDarkMode();
                              setSheetState(() {});
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                  size: 16,
                                  color: _isDarkMode ? const Color(0xFFFACC15) : t.textPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isDarkMode ? 'Light Mode' : 'Dark Mode',
                                  style: TextStyle(
                                    color: t.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: NeuButton(
                            theme: t,
                            radius: 12,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            onTap: () {
                              Navigator.of(context).pop();
                              _calibrateNeutral();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.gps_fixed_rounded, size: 16, color: t.accent),
                                const SizedBox(width: 8),
                                Text(
                                  'Calibrate Horizon',
                                  style: TextStyle(
                                    color: t.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingRow({
    required NeuTheme theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.textMuted, size: 18),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildSetupCard(NeuTheme theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: theme.raised(radius: 14, distance: 3.0, blur: 8.0),
      child: Row(
        children: [
          // Neumorphic Input: Laptop IP
          Expanded(
            flex: 3,
            child: Container(
              decoration: theme.recessed(radius: 10, distance: 2.0, blur: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: TextField(
                controller: _serverController,
                decoration: InputDecoration(
                  labelText: 'Laptop IP : Port',
                  labelStyle: TextStyle(color: theme.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                  isDense: true,
                  border: InputBorder.none,
                  hintText: '192.168.1.X:8000',
                  hintStyle: TextStyle(color: theme.textLight, fontSize: 11),
                ),
                style: TextStyle(color: theme.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Neumorphic Input: Room Code
          Expanded(
            flex: 2,
            child: Container(
              decoration: theme.recessed(radius: 10, distance: 2.0, blur: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: 'Room Code',
                  labelStyle: TextStyle(color: theme.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                  isDense: true,
                  counterText: '',
                  border: InputBorder.none,
                  hintText: '4-digits',
                  hintStyle: TextStyle(color: theme.textLight, fontSize: 11),
                ),
                style: TextStyle(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Neumorphic QR Scanner Button
          NeuButton(
            theme: theme,
            radius: 10,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onTap: _openQrScanner,
            child: Icon(
              Icons.qr_code_scanner_rounded,
              color: theme.accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),

          // Neumorphic Connect CTA Button
          NeuButton(
            theme: theme,
            radius: 10,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            onTap: _isConnecting ? null : _connect,
            child: Text(
              _isConnecting ? '...' : 'Connect',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VIEW 1: PURE NEUMORPHIC MOTION & TILT (Minimal & Premium Soft Cockpit)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMotionView(NeuTheme theme) {
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
                // Left: Pure Neumorphic Spirit Level & Telemetry Deck
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: theme.raised(radius: 20, distance: 5.0, blur: 14.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: _buildSpiritLevelCircle(bubbleX, bubbleY, 120, theme),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _telemetryItem('Roll (Steer)', '${calRoll.toStringAsFixed(1)}°', theme),
                              _telemetryItem('Pitch (Tilt)', '${calPitch.toStringAsFixed(1)}°', theme),
                              NeuButton(
                                theme: theme,
                                radius: 9,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                onTap: _calibrateNeutral,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.center_focus_strong, color: theme.textPrimary, size: 13),
                                    const SizedBox(width: 4),
                                    Text('Calibrate', style: TextStyle(color: theme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
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

                // Right: Pure Neumorphic Giant Jump Target
                Expanded(
                  flex: 2,
                  child: _buildJumpButton(isFullHeight: true, theme: theme),
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
                // Main Telemetry Plate
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: theme.raised(radius: 22, distance: 5.5, blur: 15.0),
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: _buildSpiritLevelCircle(bubbleX, bubbleY, 160, theme),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _telemetryItem('Roll (Steer)', '${calRoll.toStringAsFixed(1)}°', theme),
                            _telemetryItem('Pitch (Tilt)', '${calPitch.toStringAsFixed(1)}°', theme),
                            _telemetryItem('Jumps', '$_jumpCount', theme),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Calibrate Neutral Button
                NeuButton(
                  theme: theme,
                  radius: 14,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onTap: _calibrateNeutral,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.center_focus_strong, color: theme.textPrimary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Calibrate Neutral Angle',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Giant Pure Neumorphic JUMP Button
                SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: _buildJumpButton(isFullHeight: false, theme: theme),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  // Recessed Neumorphic Spirit Level Dish with Floating 3D Bubble
  Widget _buildSpiritLevelCircle(double bubbleX, double bubbleY, double size, NeuTheme theme) {
    final ringColor = theme.isDark ? const Color(0xFF282D37) : const Color(0xFFC7D0DC);

    return Container(
      width: size,
      height: size,
      decoration: theme.recessed(shape: BoxShape.circle, distance: 4.0, blur: 9.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Engraved Concentric Rings in Soft Feather Grey
          Container(
            width: size * 0.70,
            height: size * 0.70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ringColor, width: 0.8),
            ),
          ),
          Container(
            width: size * 0.38,
            height: size * 0.38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ringColor.withOpacity(0.8), width: 0.8),
            ),
          ),

          // Engraved Crosshairs in Subtle Grey
          Container(width: size * 0.85, height: 0.8, color: ringColor),
          Container(width: 0.8, height: size * 0.85, color: ringColor),

          // 3D Extruded Pearl Level Bubble with Specular Highlight
          Transform.translate(
            offset: Offset(bubbleX * (size * 0.36), bubbleY * (size * 0.36)),
            child: Container(
              width: size * 0.19,
              height: size * 0.19,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.35),
                  colors: theme.isDark
                      ? const [
                          Color(0xFFFFFFFF),
                          Color(0xFF64748B),
                          Color(0xFF1E293B),
                        ]
                      : const [
                          Color(0xFFFFFFFF),
                          Color(0xFFE8EEF5),
                          Color(0xFFC5CFDA),
                        ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.isDark ? const Color(0x60000000) : const Color(0x202D3E50),
                    offset: const Offset(3.0, 3.0),
                    blurRadius: 6.0,
                  ),
                  BoxShadow(
                    color: theme.isDark ? const Color(0x26FFFFFF) : const Color(0xA6FFFFFF),
                    offset: const Offset(-1.5, -1.5),
                    blurRadius: 3.0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Pure Neumorphic JUMP Button with Tactile Inset
  Widget _buildJumpButton({required bool isFullHeight, required NeuTheme theme}) {
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
            ? theme.pressed(
                radius: 20,
              )
            : theme.raised(
                radius: 20,
                distance: 5.5,
                blur: 15.0,
              ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'JUMP',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: isFullHeight ? 28 : 25,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                shadows: [
                  Shadow(
                    color: theme.isDark ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.95),
                    offset: const Offset(1, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Shake phone or press',
              style: TextStyle(
                color: theme.textMuted,
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

  Widget _telemetryItem(String label, String val, NeuTheme theme) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: theme.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: theme.recessed(radius: 8, distance: 2.0, blur: 5.0),
          child: Text(
            val,
            style: TextStyle(
              color: theme.textPrimary,
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
  // VIEW 2: PURE NEUMORPHIC PRO GAMEPAD (Minimal Monochromatic)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildGamepadView(NeuTheme theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: _isLandscape ? 6.0 : 16.0),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: _buildVirtualJoystick(theme),
            ),
          ),
          Expanded(
            child: Center(
              child: _buildABXYDiamond(theme),
            ),
          ),
        ],
      ),
    );
  }

  // Neumorphic Concave Analog Stick Well with 3D Thumb Cap
  Widget _buildVirtualJoystick(NeuTheme theme) {
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
        decoration: theme.recessed(shape: BoxShape.circle, distance: 4.0, blur: 9.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center Deadzone Ring
            Container(
              width: size * 0.35,
              height: size * 0.35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.isDark ? const Color(0xFF282D37) : const Color(0xFFC7D0DC), width: 0.8),
              ),
            ),
            // Tactile Convex Thumb Knob
            Transform.translate(
              offset: Offset(_stickX * (radius * 0.65), _stickY * (radius * 0.65)),
              child: Container(
                width: size * 0.40,
                height: size * 0.40,
                decoration: theme.raised(
                  shape: BoxShape.circle,
                  distance: 3.5,
                  blur: 8.0,
                ),
                child: Center(
                  child: Container(
                    width: size * 0.16,
                    height: size * 0.16,
                    decoration: theme.recessed(shape: BoxShape.circle, distance: 1.5, blur: 3.5),
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
  Widget _buildABXYDiamond(NeuTheme theme) {
    final size = _isLandscape ? 120.0 : 145.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 0, child: _gamepadBtn('Y', theme)),
          Positioned(bottom: 0, child: _gamepadBtn('A', theme, action: _triggerJump)),
          Positioned(left: 0, child: _gamepadBtn('X', theme)),
          Positioned(right: 0, child: _gamepadBtn('B', theme)),
        ],
      ),
    );
  }

  Widget _gamepadBtn(String label, NeuTheme theme, {VoidCallback? action}) {
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
            ? theme.pressed(
                shape: BoxShape.circle,
              )
            : theme.raised(
                shape: BoxShape.circle,
                distance: 3.5,
                blur: 8.0,
              ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: btnSize * 0.42,
            shadows: [
              Shadow(
                color: theme.isDark ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.9),
                offset: const Offset(1, 1),
                blurRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VIEW 3: PURE NEUMORPHIC RACING WHEEL (Tactile Hub & Tread Pedals)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRacingView(NeuTheme theme) {
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
                    decoration: theme.raised(
                      shape: BoxShape.circle,
                      distance: 5.0,
                      blur: 14.0,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Spokes
                        Container(width: wheelSize * 0.75, height: 8, decoration: theme.recessed(radius: 4, distance: 1.5, blur: 4.0)),
                        Container(width: 8, height: wheelSize * 0.4, margin: EdgeInsets.only(top: wheelSize * 0.35), decoration: theme.recessed(radius: 4, distance: 1.5, blur: 4.0)),
                        // Center Horn Hub
                        Container(
                          width: wheelSize * 0.4,
                          height: wheelSize * 0.4,
                          decoration: theme.raised(
                            shape: BoxShape.circle,
                            distance: 3.5,
                            blur: 8.0,
                          ),
                          child: Icon(Icons.speed, size: 28, color: theme.textPrimary),
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
                          ? theme.pressed(
                              radius: 14,
                            )
                          : theme.raised(
                              radius: 14,
                              distance: 4.0,
                              blur: 10.0,
                            ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up,
                            color: _gasPedal > 0 ? theme.textPrimary : theme.textSecondary,
                            size: 24,
                          ),
                          Text(
                            'GAS',
                            style: TextStyle(
                              color: theme.textPrimary,
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
                          ? theme.pressed(
                              radius: 14,
                            )
                          : theme.raised(
                              radius: 14,
                              distance: 4.0,
                              blur: 10.0,
                            ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pause,
                            color: _brakePedal > 0 ? theme.textPrimary : theme.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'BRAKE',
                            style: TextStyle(
                              color: theme.textPrimary,
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

class _QrScannerSheet extends StatefulWidget {
  final bool isDark;
  final ValueChanged<String> onScanned;

  const _QrScannerSheet({
    required this.isDark,
    required this.onScanned,
  });

  @override
  State<_QrScannerSheet> createState() => _QrScannerSheetState();
}


class _QrScannerSheetState extends State<_QrScannerSheet> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _scanned = false;
  // Automatically locked to landscape orientation (3 = landscapeLeft, 1 = landscapeRight)
  int _rotationQuarterTurns = 3;
  StreamSubscription? _sensorSub;

  @override
  void initState() {
    super.initState();
    try {
      _sensorSub = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen((event) {
        if (!mounted) return;
        int turns = _rotationQuarterTurns;
        if (event.x > 2.5) {
          turns = 3; // landscapeLeft (standard holding position)
        } else if (event.x < -2.5) {
          turns = 1; // landscapeRight (reversed holding position)
        }
        if (turns != _rotationQuarterTurns) {
          setState(() {
            _rotationQuarterTurns = turns;
          });
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.isDark ? NeuTheme.dark() : NeuTheme.light();
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Center(
      child: Container(
        width: isLandscape ? 520 : double.infinity,
        height: isLandscape ? 320 : 450,
        decoration: BoxDecoration(
          color: theme.bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: theme.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, color: theme.accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Scan Room QR Code',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Flashlight Toggle
                      ValueListenableBuilder<MobileScannerState>(
                        valueListenable: _controller,
                        builder: (context, state, child) {
                          final isTorchOn = state.torchState == TorchState.on;
                          return IconButton(
                            icon: Icon(
                              isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                              color: isTorchOn ? const Color(0xFFFACC15) : theme.textMuted,
                              size: 19,
                            ),
                            tooltip: isTorchOn ? 'Flashlight On' : 'Flashlight Off',
                            onPressed: () => _controller.toggleTorch(),
                          );
                        },
                      ),

                      const SizedBox(width: 4),

                      // Close Dialog
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: theme.textMuted, size: 20),
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Camera Viewport
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Camera with automatic landscape orientation
                      Positioned.fill(
                        child: RotatedBox(
                          quarterTurns: _rotationQuarterTurns,
                          child: MobileScanner(
                            controller: _controller,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, child) {
                              return Container(
                                color: Colors.black87,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'Camera error: ${error.errorCode.name}\nPlease verify camera permissions in settings.',
                                  style: TextStyle(color: theme.textMuted, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                            onDetect: (capture) {
                              if (_scanned) return;
                              for (final barcode in capture.barcodes) {
                                final val = barcode.rawValue;
                                if (val != null && val.trim().isNotEmpty) {
                                  _scanned = true;
                                  setState(() {});
                                  widget.onScanned(val.trim());
                                  break;
                                }
                              }
                            },
                          ),
                        ),
                      ),

                      // Cyberpunk / Reticle Viewport Overlay
                      Container(
                        width: isLandscape ? 170 : 210,
                        height: isLandscape ? 170 : 210,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _scanned ? theme.dotConnected : theme.accent,
                            width: 2.2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (_scanned ? theme.dotConnected : theme.accent).withOpacity(0.3),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // 4 Corner Brackets
                            Positioned(top: 4, left: 4, child: Container(width: 14, height: 2, color: theme.accent)),
                            Positioned(top: 4, left: 4, child: Container(width: 2, height: 14, color: theme.accent)),

                            Positioned(top: 4, right: 4, child: Container(width: 14, height: 2, color: theme.accent)),
                            Positioned(top: 4, right: 4, child: Container(width: 2, height: 14, color: theme.accent)),

                            Positioned(bottom: 4, left: 4, child: Container(width: 14, height: 2, color: theme.accent)),
                            Positioned(bottom: 4, left: 4, child: Container(width: 2, height: 14, color: theme.accent)),

                            Positioned(bottom: 4, right: 4, child: Container(width: 14, height: 2, color: theme.accent)),
                            Positioned(bottom: 4, right: 4, child: Container(width: 2, height: 14, color: theme.accent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Instructions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.crop_free_rounded, size: 14, color: theme.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'Align QR code inside box to auto-pair',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
