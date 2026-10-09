import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/core/update/app_update_gate.dart';
import 'package:home_service_app/core/utils/media_url.dart';

/// ElevenLabs / admin clips for voice-search UX.
///
/// Prefer remote URL from bootstrap `config.voice_prompts.{greeting|accepted}`,
/// then bundled AAC `.m4a` (iOS AVPlayer), then `.mp3`.
class SearchVoicePromptPlayer {
  SearchVoicePromptPlayer();

  AudioPlayer? _player;
  bool _busy = false;

  static String localeCode() {
    final locale = AppRemoteConfig.instance.locale;
    return (locale == 'en' || locale == 'ru') ? locale : 'az';
  }

  static List<String> assetCandidates(String kind) {
    final code = localeCode();
    return [
      'assets/audio/voice_${kind}_$code.m4a',
      'assets/audio/voice_${kind}_$code.mp3',
    ];
  }

  /// Absolute http(s) URL from bootstrap for [kind] (`greeting` | `accepted`).
  static String? remoteUrlFor(String kind) {
    final prompts = AppRemoteConfig.instance.config.voicePrompts;
    final raw = switch (kind) {
      'greeting' => prompts.greetingUrlFor(localeCode()),
      'accepted' => prompts.acceptedUrlFor(localeCode()),
      _ => null,
    };
    final resolved = resolveMediaUrl(raw);
    if (resolved == null) return null;
    if (!resolved.startsWith('http://') && !resolved.startsWith('https://')) {
      return null;
    }
    return resolved;
  }

  Future<void> playGreeting({void Function()? onStart, void Function()? onDone}) =>
      _play('greeting', onStart: onStart, onDone: onDone);

  Future<void> playAccepted({void Function()? onStart, void Function()? onDone}) =>
      _play('accepted', onStart: onStart, onDone: onDone);

  Future<AudioPlayer> _obtainPlayer() async {
    final existing = _player;
    if (existing != null) return existing;
    final created = AudioPlayer();
    _player = created;
    return created;
  }

  Future<void> _resetPlayer() async {
    final old = _player;
    _player = null;
    if (old == null) return;
    try {
      await old.dispose();
    } catch (_) {}
  }

  Future<void> _ensureSession() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());
    await session.setActive(true);
  }

  Future<String> _materialize(String asset) async {
    final data = await rootBundle.load(asset);
    final bytes = data.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final name = asset.split('/').last;
    final file = File('${dir.path}/mysancho_$name');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<String> _firstExistingAsset(List<String> candidates) async {
    Object? lastError;
    for (final asset in candidates) {
      try {
        await rootBundle.load(asset);
        return asset;
      } catch (e) {
        lastError = e;
      }
    }
    throw FlutterError(
      'Voice prompt asset missing: ${candidates.join(', ')} ($lastError)',
    );
  }

  Future<void> _play(
    String kind, {
    void Function()? onStart,
    void Function()? onDone,
  }) async {
    if (AppUpdateGate.isForceBlocked) {
      onDone?.call();
      return;
    }
    if (_busy) return;
    _busy = true;
    final candidates = assetCandidates(kind);
    var announced = false;
    try {
      await _ensureSession();

      final remote = remoteUrlFor(kind);
      if (remote != null) {
        try {
          await _playUrl(remote, onStart: () {
            announced = true;
            onStart?.call();
          });
          return;
        } catch (e, st) {
          debugPrint('[voice_prompt] remote failed ($kind $remote): $e\n$st');
          await _resetPlayer();
          await Future<void>.delayed(const Duration(milliseconds: 200));
          await _ensureSession();
        }
      }

      await _playAssetCandidates(
        candidates,
        onStart: () {
          announced = true;
          onStart?.call();
        },
      );
    } catch (e, st) {
      debugPrint('[voice_prompt] asset failed ($kind): $e\n$st');
      try {
        await _resetPlayer();
        await Future<void>.delayed(const Duration(milliseconds: 250));
        await _ensureSession();
        await _playAssetCandidates(
          candidates,
          onStart: () {
            if (!announced) {
              announced = true;
              onStart?.call();
            }
          },
        );
      } catch (e2, st2) {
        debugPrint('[voice_prompt] retry failed ($kind): $e2\n$st2');
      }
    } finally {
      _busy = false;
      onDone?.call();
    }
  }

  Future<void> _playAssetCandidates(
    List<String> candidates, {
    required void Function() onStart,
  }) async {
    final asset = await _firstExistingAsset(candidates);
    final path = await _materialize(asset);
    await _playFile(path, onStart: onStart);
  }

  Future<void> _playUrl(String url, {required void Function() onStart}) async {
    final player = await _obtainPlayer();
    await player.setVolume(1);
    await player.setUrl(url);
    onStart();
    final done = player.processingStateStream.firstWhere(
      (s) => s == ProcessingState.completed,
    );
    await player.play();
    await done.timeout(const Duration(seconds: 45));
  }

  Future<void> _playFile(String path, {required void Function() onStart}) async {
    final player = await _obtainPlayer();
    await player.setVolume(1);
    await player.setFilePath(path);
    onStart();
    final done = player.processingStateStream.firstWhere(
      (s) => s == ProcessingState.completed,
    );
    await player.play();
    await done.timeout(const Duration(seconds: 30));
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
    _busy = false;
  }

  Future<void> dispose() async {
    await stop();
    await _resetPlayer();
  }
}
