import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioIntroRecorder extends StatefulWidget {
  const AudioIntroRecorder({
    super.key,
    this.existingUrl,
    this.localPath,
    required this.onRecorded,
  });

  final String? existingUrl;
  final String? localPath;
  final ValueChanged<String> onRecorded;

  @override
  State<AudioIntroRecorder> createState() => _AudioIntroRecorderState();
}

class _AudioIntroRecorderState extends State<AudioIntroRecorder> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _recording = false;
  bool _playing = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  String? _path;

  @override
  void initState() {
    super.initState();
    _path = widget.localPath;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      final path = await _recorder.stop();
      _timer?.cancel();
      setState(() {
        _recording = false;
        _elapsed = Duration.zero;
        _path = path;
      });
      if (path != null) widget.onRecorded(path);
      return;
    }

    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mikrofon icazəsi lazımdır')),
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/intro_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: filePath,
    );

    setState(() {
      _recording = true;
      _elapsed = Duration.zero;
      _path = null;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
      if (_elapsed.inSeconds >= 60) {
        _toggleRecord();
      }
    });
  }

  Future<void> _togglePlay() async {
    final source = _path ?? widget.existingUrl;
    if (source == null) return;

    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
      return;
    }

    try {
      if (_path != null) {
        await _player.setFilePath(_path!);
      } else {
        await _player.setUrl(source);
      }
      setState(() => _playing = true);
      await _player.play();
      await _player.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed,
      );
      if (mounted) setState(() => _playing = false);
    } catch (_) {
      if (mounted) {
        setState(() => _playing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Səs oxunmadı')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAudio = _path != null || widget.existingUrl != null;
    final mm = _elapsed.inMinutes.toString().padLeft(2, '0');
    final ss = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Audio intro', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Qısa səsli tanıtım (maks. 60 san)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: _toggleRecord,
                  icon: Icon(_recording ? Icons.stop : Icons.mic),
                  label: Text(_recording ? 'Dayandır $mm:$ss' : 'Yaz'),
                ),
                const SizedBox(width: 8),
                if (hasAudio)
                  IconButton.filledTonal(
                    onPressed: _togglePlay,
                    icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
                  ),
              ],
            ),
            if (hasAudio) ...[
              const SizedBox(height: 8),
              Text(
                _path != null
                    ? 'Yeni yazı hazırdır (yadda saxlananda yüklənəcək)'
                    : 'Mövcud intro yüklənib',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
