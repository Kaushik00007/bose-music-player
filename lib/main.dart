import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:miniaudio_player/miniaudio_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  MiniaudioPlayerGlobalConfig.assetLoader = (key) async {
    final data = await rootBundle.load(key);
    return data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
  };

  runApp(const BoseMusicApp());
}

// ---------------------------------------------------------------------------
// Design tokens (visual only)
// ---------------------------------------------------------------------------
const Color _kTeal = Color(0xFF00D6AA);
const Color _kTealButton = Color(0xFF00C8A0);
const Color _kSurface = Color(0xFF16181D);
const Color _kSurfaceRaised = Color(0xFF1E2026);
const Color _kBorder = Color(0x1AFFFFFF);

class BoseMusicApp extends StatelessWidget {
  const BoseMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bose Music Player',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF101114),
        colorScheme: ColorScheme.fromSeed(
          seedColor: _kTealButton,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        sliderTheme: SliderThemeData(
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          activeTrackColor: _kTeal,
          inactiveTrackColor: Colors.grey.shade800,
          thumbColor: _kTeal,
          overlayColor: const Color(0x3300D6AA),
          // Hide the dense tick marks on the EQ sliders for a cleaner look.
          activeTickMarkColor: Colors.transparent,
          inactiveTickMarkColor: Colors.transparent,
          // Clear disabled state (e.g. seek bar before a track has loaded).
          disabledActiveTrackColor: const Color(0x4D00D6AA),
          disabledInactiveTrackColor: Colors.grey.shade900,
          disabledThumbColor: Colors.grey.shade700,
          valueIndicatorColor: _kTeal,
          valueIndicatorTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      home: const PlayerScreen(),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final MiniaudioPlayer player;

  static const List<String> _tracks = [
    'assets/musics/sample.mp3',
    'assets/musics/track2.mp3',
    'assets/musics/track3.mp3',
    'assets/musics/track4.mp3',
  ];

  static const List<String> _trackTitles = [
    'Desi Kalakaar',
    'Blue Eyes',
    'Millionaire',
    'Kuley Kuley',
  ];

  int _currentTrackIndex = 0;
  bool _isSwitchingTrack = false;
  bool _isSeeking = false;
  Duration _dragPosition = Duration.zero;
  StreamSubscription<bool>? _completedSubscription;

  bool loading = true;
  bool playing = false;
  String? errorMessage;

  double low = 0;
  double mid = 0;
  double high = 0;

  @override
  void initState() {
    super.initState();
    player = MiniaudioPlayer();
    _listenToCompletion();
    _loadTrack(_currentTrackIndex);
  }

  void _listenToCompletion() {
    _completedSubscription = player.stream.completed.listen((completed) {
      if (completed && mounted && !_isSwitchingTrack) {
        _playNextTrack();
      }
    });
  }

  Future<void> _loadTrack(int index, {bool autoPlay = false}) async {
    if (_isSwitchingTrack) return;
    if (index < 0 || index >= _tracks.length) return;

    _isSwitchingTrack = true;

    try {
      if (!mounted) return;
      setState(() {
        loading = true;
        errorMessage = null;
      });

      final currentEq = player.state.equalizer;

      await player.action.open(
        AudioSource.asset(_tracks[index]),
      );

      if (!mounted) return;

      if (currentEq != Equalizer.flat) {
        await player.action.setEqualizer(currentEq);
      }

      _currentTrackIndex = index;

      if (autoPlay) {
        await player.action.play();
        if (mounted) {
          setState(() => playing = true);
        }
      } else {
        await player.action.seek(Duration.zero);
      }

      if (!mounted) return;
      setState(() => loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = 'Failed to load track: $e';
      });
    } finally {
      _isSwitchingTrack = false;
    }
  }

  Future<void> _playNextTrack() async {
    final nextIndex = (_currentTrackIndex + 1) % _tracks.length;
    await _loadTrack(nextIndex, autoPlay: true);
  }

  Future<void> _playPreviousTrack() async {
    final prevIndex = (_currentTrackIndex - 1 + _tracks.length) % _tracks.length;
    await _loadTrack(prevIndex, autoPlay: true);
  }

  Future<void> _togglePlayback() async {
    try {
      if (playing) {
        await player.action.pause();
      } else {
        await player.action.play();
      }

      if (mounted) {
        setState(() => playing = !playing);
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _seek(Duration position) async {
    try {
      await player.action.seek(position);
    } catch (e) {
      _showError(e);
    }
  }

  void _onSeekStart(double value) {
    setState(() {
      _isSeeking = true;
      _dragPosition = Duration(milliseconds: value.round());
    });
  }

  void _onSeekChange(double value) {
    setState(() {
      _dragPosition = Duration(milliseconds: value.round());
    });
  }

  void _onSeekEnd(double value) {
    final position = Duration(milliseconds: value.round());
    _seek(position);
    setState(() {
      _isSeeking = false;
      _dragPosition = Duration.zero;
    });
  }

  Future<void> _updateEqualizer(
    String band,
    double value,
  ) async {
    final gains = List<double>.from(
      player.state.equalizer.toList(),
    );

    final indices = switch (band) {
      'Low' => [0, 1, 2],
      'Mid' => [3, 4, 5, 6],
      'High' => [7, 8, 9],
      _ => <int>[],
    };

    for (final index in indices) {
      gains[index] = value;
    }

    try {
      await player.action.setEqualizer(
        Equalizer.fromList(gains),
      );

      if (!mounted) return;

      setState(() {
        if (band == 'Low') low = value;
        if (band == 'Mid') mid = value;
        if (band == 'High') high = value;
      });
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _resetEqualizer() async {
    try {
      await player.action.setEqualizer(Equalizer.flat);

      if (!mounted) return;

      setState(() {
        low = 0;
        mid = 0;
        high = 0;
      });
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _completedSubscription?.cancel();
    unawaited(player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controlsEnabled = !(loading || _isSwitchingTrack);
    final eqIsFlat = low == 0 && mid == 0 && high == 0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsive sizing: artwork scales with window height so the
                // EQ stays visible on 1080p; smaller windows fall back to scroll.
                final h = constraints.maxHeight;
                final w = constraints.maxWidth;
                final compact = h < 780;
                final gap = compact ? 10.0 : 16.0;
                final hPad = w < 420 ? 16.0 : 24.0;
                final artHeight =
                    (h * (compact ? 0.15 : 0.19)).clamp(72.0, 190.0).toDouble();
                final artIconSize = (artHeight * 0.42).clamp(32.0, 72.0).toDouble();

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Header (left padding offsets trailing letter-spacing
                          // so the text is optically centred).
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Text(
                              'BOSE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: Text(
                              'MUSIC PLAYER',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                letterSpacing: 3,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          SizedBox(height: gap),
                          // Artwork
                          Container(
                            height: artHeight,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _kBorder),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF174D48),
                                  Color(0xFF101F28),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.graphic_eq_rounded,
                                size: artIconSize,
                                color: _kTeal.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          SizedBox(height: gap - 2),
                          // Track info
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            child: Text(
                              _trackTitles[_currentTrackIndex],
                              key: ValueKey(_currentTrackIndex),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bose Music Library',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          ),
                          SizedBox(height: gap - 4),
                          // Seek bar
                          StreamBuilder<Duration>(
                            stream: player.stream.position,
                            initialData: player.state.position,
                            builder: (context, snapshot) {
                              final streamPosition = snapshot.data ?? Duration.zero;
                              final duration = player.state.duration;
                              final hasDuration = duration.inMilliseconds > 0;

                              final max = hasDuration
                                  ? duration.inMilliseconds.toDouble()
                                  : 1.0;

                              final displayPosition = _isSeeking ? _dragPosition : streamPosition;
                              final value = displayPosition.inMilliseconds
                                  .toDouble()
                                  .clamp(0.0, max);

                              return Column(
                                children: [
                                  Slider(
                                    value: value,
                                    max: max,
                                    onChangeStart: hasDuration ? _onSeekStart : null,
                                    onChanged: hasDuration ? _onSeekChange : null,
                                    onChangeEnd: hasDuration ? _onSeekEnd : null,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDuration(displayPosition),
                                          style: TextStyle(
                                            color: Colors.grey.shade300,
                                            fontSize: 12,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        Text(
                                          _formatDuration(duration),
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: gap - 4),
                          // Playback controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _ControlButton(
                                icon: Icons.skip_previous_rounded,
                                onPressed: controlsEnabled ? _playPreviousTrack : null,
                                enabled: controlsEnabled,
                                tooltip: 'Previous',
                              ),
                              const SizedBox(width: 24),
                              _PlayPauseButton(
                                playing: playing,
                                loading: loading,
                                onPressed: (loading || errorMessage != null) ? null : _togglePlayback,
                              ),
                              const SizedBox(width: 24),
                              _ControlButton(
                                icon: Icons.skip_next_rounded,
                                onPressed: controlsEnabled ? _playNextTrack : null,
                                enabled: controlsEnabled,
                                tooltip: 'Next',
                              ),
                            ],
                          ),
                          if (errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          SizedBox(height: gap),
                          // Equalizer card
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.fromLTRB(
                              16,
                              compact ? 6 : 10,
                              16,
                              compact ? 8 : 12,
                            ),
                            decoration: BoxDecoration(
                              color: _kSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _kBorder),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'EQUALIZER',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: eqIsFlat ? null : _resetEqualizer,
                                      style: TextButton.styleFrom(
                                        foregroundColor: _kTeal,
                                        disabledForegroundColor: Colors.grey.shade700,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                      ),
                                      child: const Text(
                                        'RESET',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                _equalizerSlider('Low', low),
                                _equalizerSlider('Mid', mid),
                                _equalizerSlider('High', high),
                              ],
                            ),
                          ),
                          SizedBox(height: gap - 4),
                          Center(
                            child: Text(
                              'DESIGNED FOR BETTER SOUND',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 9,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _equalizerSlider(String band, double value) {
    final active = value != 0;
    final sign = value > 0 ? '+' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                band,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  color: active ? _kTeal : Colors.grey.shade400,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                child: Text('$sign${value.toStringAsFixed(1)} dB'),
              ),
            ],
          ),
          Slider(
            min: -12,
            max: 12,
            divisions: 48,
            value: value,
            onChanged: (v) => _updateEqualizer(band, v),
          ),
        ],
      ),
    );
  }
}

/// Secondary round control (previous / next). Fixed size so both match.
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool enabled;
  final String tooltip;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    required this.enabled,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1.0 : 0.35,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 28, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: _kSurfaceRaised,
            disabledBackgroundColor: _kSurfaceRaised,
            fixedSize: const Size(56, 56),
            padding: EdgeInsets.zero,
            shape: const CircleBorder(side: BorderSide(color: _kBorder)),
          ),
        ),
      ),
    );
  }
}

/// Primary round control. Same circular language as the secondary buttons.
class _PlayPauseButton extends StatelessWidget {
  final bool playing;
  final bool loading;
  final VoidCallback? onPressed;

  const _PlayPauseButton({
    required this.playing,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        shape: const CircleBorder(),
        fixedSize: const Size(72, 72),
        padding: EdgeInsets.zero,
        backgroundColor: _kTealButton,
        foregroundColor: Colors.black,
        disabledBackgroundColor: const Color(0x4D00C8A0),
        disabledForegroundColor: Colors.white38,
        elevation: 4,
        shadowColor: const Color(0x3300D6AA),
      ),
      child: loading
          ? const SizedBox(
              height: 26,
              width: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(_kTeal),
              ),
            )
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                key: ValueKey(playing),
                size: 36,
              ),
            ),
    );
  }
}
