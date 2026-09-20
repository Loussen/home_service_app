import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';

/// Play / stop control for a service-request voice recording.
class RequestAudioPlayer extends StatefulWidget {
  const RequestAudioPlayer({
    super.key,
    required this.audioUrl,
    this.playLabelKey = 'requests.audio_play',
    this.stopLabelKey = 'requests.audio_stop',
    this.hintLabelKey = 'requests.audio_hint',
  });

  final String audioUrl;
  final String playLabelKey;
  final String stopLabelKey;
  final String hintLabelKey;

  @override
  State<RequestAudioPlayer> createState() => _RequestAudioPlayerState();
}

class _RequestAudioPlayerState extends State<RequestAudioPlayer> {
  final _player = AudioPlayer();
  bool _playing = false;
  bool _loading = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final url = widget.audioUrl.trim();
    if (url.isEmpty) return;
    try {
      if (_playing) {
        await _player.stop();
        if (mounted) setState(() => _playing = false);
        return;
      }
      setState(() => _loading = true);
      await _player.setUrl(url);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _playing = true;
      });
      await _player.play();
      await _player.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed,
      );
      if (mounted) setState(() => _playing = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _playing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('audio.play_failed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _loading ? null : _toggle,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.peach,
                  shape: BoxShape.circle,
                ),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _playing
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        color: AppColors.primary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t(_playing
                          ? widget.stopLabelKey
                          : widget.playLabelKey),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t(widget.hintLabelKey),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
