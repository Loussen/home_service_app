import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/core/network/api_client.dart';
import 'package:home_service_app/core/network/api_response.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';

class StaticPageScreen extends StatefulWidget {
  const StaticPageScreen({
    super.key,
    required this.slug,
    this.initialTitle,
  });

  final String slug;
  final String? initialTitle;

  @override
  State<StaticPageScreen> createState() => _StaticPageScreenState();
}

class _StaticPageScreenState extends State<StaticPageScreen> {
  bool _loading = true;
  String? _error;
  String _title = '';
  String _bodyHtml = '';

  @override
  void initState() {
    super.initState();
    _title = widget.initialTitle ?? '';
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final locale = AppRemoteConfig.instance.locale;
      final res = await getIt<ApiClient>().dio.get<Map<String, dynamic>>(
        '/pages/${widget.slug}',
        queryParameters: {'locale': locale},
      );
      final parsed = ApiResponse.fromJson(
        res.data ?? {},
        (raw) => Map<String, dynamic>.from(raw as Map),
      );
      if (!parsed.success || parsed.data == null) {
        throw Exception(parsed.message);
      }
      final data = parsed.data!;
      if (!mounted) return;
      setState(() {
        _title = (data['title'] as String?)?.trim().isNotEmpty == true
            ? data['title'] as String
            : (widget.initialTitle ?? widget.slug);
        _bodyHtml = (data['body_html'] as String?) ?? '';
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message ?? t('static_page.load_error');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = t('static_page.load_error');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Text(
          _title.isEmpty ? '…' : _title,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: Text(t('common.retry')),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    Html(
                      data: _bodyHtml.isEmpty ? '<p></p>' : _bodyHtml,
                      style: {
                        'body': Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          color: AppColors.ink,
                          fontSize: FontSize(16),
                          lineHeight: const LineHeight(1.5),
                        ),
                        'a': Style(color: AppColors.primary),
                        'h1': Style(color: AppColors.primary),
                        'h2': Style(color: AppColors.primary),
                        'h3': Style(color: AppColors.primary),
                      },
                    ),
                  ],
                ),
    );
  }
}
