
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
          seedColor: const Color(0xFF00C8A0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
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
    _loadTrack();
  }

  Future<void> _loadTrack() async {
    try {
      await player.action.open(
        AudioSource.asset('assets/musics/sample.mp3'),
      );

      if (!mounted) return;
      setState(() => loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = e.toString();
      });
    }
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
    unawaited(player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: ListView(
              padding: const EdgeInsets.all(28),
              children: [
                const Text(
                  'BOSE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'MUSIC PLAYER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    letterSpacing: 4,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF174D48),
                        Color(0xFF101F28),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.graphic_eq_rounded,
                      size: 110,
                      color: Color(0xFF00D6AA),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Sample Track',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bose Music Library',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 24),
                StreamBuilder<Duration>(
                  stream: player.stream.position,
                  initialData: player.state.position,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = player.state.duration;

                    final max = duration.inMilliseconds > 0
                        ? duration.inMilliseconds.toDouble()
                        : 1.0;

                    final value = position.inMilliseconds
                        .toDouble()
                        .clamp(0.0, max);

                    return Column(
                      children: [
                        Slider(
                          value: value,
                          max: max,
                          onChanged: duration.inMilliseconds > 0
                              ? (v) => _seek(
                                    Duration(
                                      milliseconds: v.round(),
                                    ),
                                  )
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(position)),
                              Text(_formatDuration(duration)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: null,
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: 38,
                    ),
                    const SizedBox(width: 18),
                    FilledButton(
                      onPressed: loading || errorMessage != null
                          ? null
                          : _togglePlayback,
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(22),
                      ),
                      child: loading
                          ? const SizedBox(
                              height: 28,
                              width: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 36,
                            ),
                    ),
                    const SizedBox(width: 18),
                    IconButton(
                      onPressed: null,
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: 38,
                    ),
                  ],
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 42),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'EQUALIZER',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    TextButton(
                      onPressed: _resetEqualizer,
                      child: const Text('RESET'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _equalizerSlider('Low', low),
                _equalizerSlider('Mid', mid),
                _equalizerSlider('High', high),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'DESIGNED FOR BETTER SOUND',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _equalizerSlider(String band, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                band,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('${value.toStringAsFixed(1)} dB'),
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
