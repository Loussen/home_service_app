class BootstrapFees {
  const BootstrapFees({
    this.welcomeBonus = 10,
    this.bump = 1,
    this.urgent = 2,
    this.vip = 15,
    this.verified = 5,
  });

  factory BootstrapFees.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BootstrapFees();
    return BootstrapFees(
      welcomeBonus: _num(json['welcome_bonus'], 10),
      bump: _num(json['bump'], 1),
      urgent: _num(json['urgent'], 2),
      vip: _num(json['vip'], 15),
      verified: _num(json['verified'], 5),
    );
  }

  final double welcomeBonus;
  final double bump;
  final double urgent;
  final double vip;
  final double verified;

  static double _num(dynamic v, double fallback) {
    if (v is num) return v.toDouble();
    return fallback;
  }
}

class BootstrapStep {
  const BootstrapStep({required this.id, required this.title});

  factory BootstrapStep.fromJson(Map<String, dynamic> json) {
    return BootstrapStep(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
    );
  }

  final String id;
  final String title;
}

class BootstrapConfig {
  const BootstrapConfig({
    this.maxCategoryTags = 3,
    this.fees = const BootstrapFees(),
    this.searchRadiusKm = 50,
    this.urgentRadiusKm = 5,
    this.urgentDailyLimit = 3,
    this.urgentHours = 2,
    this.bumpHours = 24,
    this.bumpDailyLimit = 2,
    this.walletPackages = const [10, 30, 50],
    this.onboardingSteps = const [],
  });

  factory BootstrapConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BootstrapConfig();
    final stepsRaw = json['onboarding_steps'];
    final steps = stepsRaw is List
        ? stepsRaw
            .whereType<Map>()
            .map((e) => BootstrapStep.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <BootstrapStep>[];

    return BootstrapConfig(
      maxCategoryTags: (json['max_category_tags'] as num?)?.toInt() ?? 3,
      fees: BootstrapFees.fromJson(
        json['fees'] is Map ? Map<String, dynamic>.from(json['fees'] as Map) : null,
      ),
      searchRadiusKm: (json['search_radius_km'] as num?)?.toDouble() ?? 50,
      urgentRadiusKm: (json['urgent_radius_km'] as num?)?.toDouble() ?? 5,
      urgentDailyLimit: (json['urgent_daily_limit'] as num?)?.toInt() ?? 3,
      urgentHours: (json['urgent_hours'] as num?)?.toInt() ?? 2,
      bumpHours: (json['bump_hours'] as num?)?.toInt() ?? 24,
      bumpDailyLimit: (json['bump_daily_limit'] as num?)?.toInt() ?? 2,
      walletPackages: _numList(json['wallet_packages'], const [10, 30, 50]),
      onboardingSteps: steps,
    );
  }

  final int maxCategoryTags;
  final BootstrapFees fees;
  final double searchRadiusKm;
  final double urgentRadiusKm;
  final int urgentDailyLimit;
  final int urgentHours;
  final int bumpHours;
  final int bumpDailyLimit;
  final List<double> walletPackages;
  final List<BootstrapStep> onboardingSteps;

  static List<double> _numList(dynamic raw, List<double> fallback) {
    if (raw is! List) return fallback;
    final parsed = raw
        .map((e) => e is num ? e.toDouble() : double.tryParse('$e'))
        .whereType<double>()
        .toList();
    return parsed.isEmpty ? fallback : parsed;
  }
}

class BootstrapFlags {
  const BootstrapFlags({
    this.voiceSearch = true,
    this.mapsEnabled = true,
    this.pushConfigured = false,
  });

  factory BootstrapFlags.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BootstrapFlags();
    return BootstrapFlags(
      voiceSearch: json['voice_search'] != false,
      mapsEnabled: json['maps_enabled'] != false,
      pushConfigured: json['push_configured'] == true,
    );
  }

  final bool voiceSearch;
  final bool mapsEnabled;
  final bool pushConfigured;
}

class BootstrapPayload {
  const BootstrapPayload({
    this.version = 1,
    this.locale = 'az',
    this.defaultLocale = 'az',
    this.supportedLocales = const ['az'],
    this.localeLabels = const {},
    this.strings = const {},
    this.config = const BootstrapConfig(),
    this.flags = const BootstrapFlags(),
  });

  factory BootstrapPayload.fromJson(Map<String, dynamic> json) {
    final stringsRaw = json['strings'];
    final strings = <String, String>{};
    if (stringsRaw is Map) {
      for (final e in stringsRaw.entries) {
        strings['${e.key}'] = '${e.value}';
      }
    }

    final labelsRaw = json['locale_labels'];
    final labels = <String, String>{};
    if (labelsRaw is Map) {
      for (final e in labelsRaw.entries) {
        labels['${e.key}'] = '${e.value}';
      }
    }

    final supportedRaw = json['supported_locales'];
    final supported = supportedRaw is List
        ? supportedRaw.map((e) => '$e').toList()
        : <String>[];

    return BootstrapPayload(
      version: (json['version'] as num?)?.toInt() ?? 1,
      locale: (json['locale'] as String?) ?? 'az',
      defaultLocale: (json['default_locale'] as String?) ?? 'az',
      supportedLocales: supported.isNotEmpty ? supported : const ['az'],
      localeLabels: labels,
      strings: strings,
      config: BootstrapConfig.fromJson(
        json['config'] is Map
            ? Map<String, dynamic>.from(json['config'] as Map)
            : null,
      ),
      flags: BootstrapFlags.fromJson(
        json['flags'] is Map
            ? Map<String, dynamic>.from(json['flags'] as Map)
            : null,
      ),
    );
  }

  final int version;
  final String locale;
  final String defaultLocale;
  final List<String> supportedLocales;
  final Map<String, String> localeLabels;
  final Map<String, String> strings;
  final BootstrapConfig config;
  final BootstrapFlags flags;

  Map<String, dynamic> toJson() => {
        'version': version,
        'locale': locale,
        'default_locale': defaultLocale,
        'supported_locales': supportedLocales,
        'locale_labels': localeLabels,
        'strings': strings,
        'config': {
          'max_category_tags': config.maxCategoryTags,
          'fees': {
            'welcome_bonus': config.fees.welcomeBonus,
            'bump': config.fees.bump,
            'urgent': config.fees.urgent,
            'vip': config.fees.vip,
            'verified': config.fees.verified,
          },
          'search_radius_km': config.searchRadiusKm,
          'urgent_radius_km': config.urgentRadiusKm,
          'urgent_daily_limit': config.urgentDailyLimit,
          'urgent_hours': config.urgentHours,
          'bump_hours': config.bumpHours,
          'bump_daily_limit': config.bumpDailyLimit,
          'wallet_packages': config.walletPackages,
          'onboarding_steps': config.onboardingSteps
              .map((s) => {'id': s.id, 'title': s.title})
              .toList(),
        },
        'flags': {
          'voice_search': flags.voiceSearch,
          'maps_enabled': flags.mapsEnabled,
          'push_configured': flags.pushConfigured,
        },
      };
}
