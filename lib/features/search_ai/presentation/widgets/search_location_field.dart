import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/profile/data/places_client.dart';

class SearchLocationField extends StatefulWidget {
  const SearchLocationField({
    super.key,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.onChanged,
    this.enabled = true,
  });

  final double latitude;
  final double longitude;
  final String? address;
  final void Function(double lat, double lng, String? address) onChanged;
  final bool enabled;

  @override
  State<SearchLocationField> createState() => _SearchLocationFieldState();
}

class _SearchLocationFieldState extends State<SearchLocationField> {
  final _places = getIt<PlacesClient>();

  Future<void> _pick() async {
    if (!widget.enabled) return;

    final query = TextEditingController(text: widget.address ?? '');
    final focus = FocusNode();
    var suggestions = <PlaceSuggestion>[];
    var searching = false;
    Timer? debounce;

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            void search(String q) {
              debounce?.cancel();
              debounce = Timer(const Duration(milliseconds: 320), () async {
                if (q.trim().length < 2) {
                  setSheet(() => suggestions = []);
                  return;
                }
                setSheet(() => searching = true);
                try {
                  final list = await _places.autocomplete(q.trim());
                  if (context.mounted) {
                    setSheet(() {
                      suggestions = list;
                      searching = false;
                    });
                  }
                } catch (_) {
                  if (context.mounted) {
                    setSheet(() => searching = false);
                  }
                }
              });
            }

            Future<void> useGps() async {
              var perm = await Geolocator.checkPermission();
              if (perm == LocationPermission.denied) {
                perm = await Geolocator.requestPermission();
              }
              if (perm == LocationPermission.denied ||
                  perm == LocationPermission.deniedForever) {
                return;
              }
              final pos = await Geolocator.getCurrentPosition();
              widget.onChanged(pos.latitude, pos.longitude, null);
              if (context.mounted) Navigator.pop(context);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t('search.location_label'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: query,
                    focusNode: focus,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: t('location.search_address'),
                      suffixIcon: searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    onChanged: search,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: useGps,
                    icon: const Icon(Icons.my_location),
                    label: Text(t('location.my_gps')),
                  ),
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: suggestions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final s = suggestions[i];
                          return ListTile(
                            dense: true,
                            title: Text(s.description),
                            onTap: () async {
                              final place = await _places.details(s.placeId);
                              if (place == null) return;
                              widget.onChanged(
                                place.latitude,
                                place.longitude,
                                place.formattedAddress,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
    query.dispose();
    focus.dispose();
    debounce?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.address?.trim().isNotEmpty == true
        ? widget.address!
        : '${widget.latitude.toStringAsFixed(4)}, '
            '${widget.longitude.toStringAsFixed(4)}';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: widget.enabled,
      leading: const Icon(Icons.place_outlined),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(t('search.location_label')),
      trailing: const Icon(Icons.chevron_right),
      onTap: _pick,
    );
  }
}
