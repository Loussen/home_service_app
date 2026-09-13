import 'dart:convert';

import 'package:home_service_app/core/remote/bootstrap_model.dart';
import 'package:home_service_app/core/remote/bootstrap_remote_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remote copy + config from `GET /bootstrap`. Offline fallback built-in.
class AppRemoteConfig {
  AppRemoteConfig._();

  static final AppRemoteConfig instance = AppRemoteConfig._();

  static String _cacheKeyFor(String locale) => 'bootstrap_cache_v4_$locale';

  BootstrapPayload _payload = BootstrapPayload(
    strings: Map<String, String>.from(_defaultStrings),
    config: BootstrapConfig(
      onboardingSteps: _defaultOnboardingSteps
          .map((s) => BootstrapStep(id: s.$1, title: s.$2))
          .toList(),
    ),
  );

  BootstrapPayload get payload => _payload;
  BootstrapConfig get config => _payload.config;
  BootstrapFlags get flags => _payload.flags;
  String get locale => _payload.locale;
  List<String> get supportedLocales => _payload.supportedLocales;
  Map<String, String> get localeLabels => _payload.localeLabels;
  List<StaticPageMenuItem> get staticPages => _payload.staticPages;

  /// Load cached bootstrap for [locale], then refresh from API.
  Future<void> load(
    BootstrapRemoteDataSource source, {
    required String locale,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _cacheKeyFor(locale);
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      final map = BootstrapRemoteDataSource.decodeCached(cached);
      if (map != null) {
        _payload = BootstrapPayload.fromJson(map);
      }
    }

    try {
      final remote = await source.fetch(locale: locale);
      _payload = _merge(remote);
      await prefs.setString(cacheKey, jsonEncode(_payload.toJson()));
    } catch (_) {
      // Keep cache / defaults — app works offline.
    }
  }

  Future<void> reload(BootstrapRemoteDataSource source, String locale) =>
      load(source, locale: locale);

  BootstrapPayload _merge(BootstrapPayload remote) {
    final strings = Map<String, String>.from(_defaultStrings);
    strings.addAll(remote.strings);

    final steps = remote.config.onboardingSteps.isNotEmpty
        ? remote.config.onboardingSteps
        : _defaultOnboardingSteps
            .map((s) => BootstrapStep(id: s.$1, title: s.$2))
            .toList();

    return BootstrapPayload(
      version: remote.version,
      locale: remote.locale,
      defaultLocale: remote.defaultLocale,
      supportedLocales: remote.supportedLocales,
      localeLabels: remote.localeLabels,
      strings: strings,
      config: BootstrapConfig(
        maxCategoryTags: remote.config.maxCategoryTags,
        fees: remote.config.fees,
        searchRadiusKm: remote.config.searchRadiusKm,
        urgentRadiusKm: remote.config.urgentRadiusKm,
        urgentDailyLimit: remote.config.urgentDailyLimit,
        urgentHours: remote.config.urgentHours,
        bumpHours: remote.config.bumpHours,
        bumpDailyLimit: remote.config.bumpDailyLimit,
        walletPackages: remote.config.walletPackages,
        requestTtlDefaultHours: remote.config.requestTtlDefaultHours,
        requestTtlOptionsHours: remote.config.requestTtlOptionsHours,
        onboardingSteps: steps,
      ),
      flags: remote.flags,
      staticPages: remote.staticPages,
    );
  }

  String t(String key, {Map<String, String>? params}) {
    var value = _payload.strings[key] ?? _defaultStrings[key] ?? key;
    // PHP single-quoted / DB values often store literal "\n" instead of a newline.
    if (value.contains(r'\n') || value.contains(r'\r')) {
      value = value
          .replaceAll(r'\r\n', '\n')
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\r', '\n');
    }
    if (params != null) {
      for (final e in params.entries) {
        value = value.replaceAll('{${e.key}}', e.value);
      }
    }
    return value;
  }

  static const _defaultOnboardingSteps = [
    ('name', 'Sizi necə çağıraq?'),
    ('categories', 'Nə xidmət göstərirsiniz?'),
    ('location', 'Harada işləyirsiniz?'),
    ('schedule', 'Hansı vaxtlar uyğunsunuz?'),
    ('about', 'Qısa təqdimat'),
  ];

  static const _defaultStrings = {
    'auth.tagline': 'Ailə və ev xidmətləri — bir yerdə.',
    'login.subtitle': 'Nömrənizi daxil edin — SMS ilə daxil olursunuz.',
    'login.title': 'Daxil ol / Qeydiyyat',
    'login.hint': 'Eyni nömrə həm giriş, həm qeydiyyatdır.',
    'login.phone_label': 'Telefon nömrəsi',
    'login.phone_helper': 'Demo: +994501111111 · kod 123456',
    'login.phone_invalid': 'Tam nömrə daxil edin (məs. +994501111111)',
    'login.submit': 'Davam et',
    'login.submitting': 'Göndərilir…',
    'otp.subtitle': 'SMS kodunu daxil edin.',
    'otp.title': 'Təsdiq kodu',
    'otp.sent_generic': 'Kod telefonunuza göndərildi.',
    'otp.sent_to': '{phone} nömrəsinə kod göndərildi.',
    'otp.helper': 'Lokal: 123456',
    'otp.submit': 'Təsdiqlə',
    'otp.submitting': 'Yoxlanır…',
    'role.subtitle': 'My Sancho-da necə iştirak etmək istəyirsiniz?',
    'role.title': 'Rol seçin',
    'role.hint':
        'Bu seçim birdəfəlikdir — eyni nömrə yalnız bir rolda ola bilər.',
    'role.client.title': 'Ailə / Müştəri',
    'role.client.subtitle':
        'Dayə, təmizlik, baxıcı axtarın. Sorğu göndərin, chat edin.',
    'role.provider.title': 'Xidmət göstərən',
    'role.provider.subtitle':
        'Profil yaradın, işlər alın, bump və VIP istifadə edin.',
    'tabs.client.search': 'Axtar',
    'tabs.client.requests': 'Sorğularım',
    'tabs.provider.jobs': 'İşlər',
    'tabs.provider.profiles': 'Xidmət',
    'tabs.chat': 'Chat',
    'tabs.profile': 'Profil',
    'tabs.account': 'Hesab',
    'search.headline': 'Nə axtarırsınız?',
    'search.subtitle':
        'Mikrofonu basıb danışın və ya mətni yazın. AI yaxınlıqdakı peşəkarları tapacaq.',
    'search.recording': 'Yazılır… {seconds}s',
    'search.audio_ready': 'Səs hazırdır — göndərin',
    'search.tap_mic': 'Basın və danışın',
    'search.or_text': 'və ya mətn',
    'search.text_hint':
        'məs. Nərimanovda sabah günorta 2 saata dayə axtarıram',
    'search.urgent_title': 'Təcili',
    'search.urgent_subtitle':
        '{km} km daxilində, {hours} saat · {fee} AZN · bu gün {count} qalıb',
    'search.urgent_limit': 'Bu gün təcili limitiniz bitib',
    'search.location_label': 'Axtarış mərkəzi',
    'search.processing': 'AI emal edir və match edir…',
    'search.submit': 'Axtar',
    'search.submitting': 'Göndərilir…',
    'search.voice_uploading': 'Səs yüklənir…',
    'search.voice_uploading_hint': 'Bir az gözləyin — sorğu göndərilir.',
    'search.processing_hint': 'AI sizi dinləyir və uyğun icraçıları axtarır.',
    'search.new_request': 'Yeni sorğu',
    'search.no_matches':
        'Uyğun icraçı tapılmadı.\nRadiusu genişləndirin və ya digər vaxt seçin.',
    'search.transcript_failed':
        'Səs oxunmadı. Eyni mətni yazıb yenidən göndərin.',
    'search.meta.expanded': 'Radius {from} km-dən {to} km-ə genişləndi.',
    'search.meta.dropped_category':
        'Bu kateqoriyada tapılmadı — yaxın digər icraçılar göstərilir.',
    'search.meta.dropped_area':
        'Seçilmiş ərazidə tapılmadı — daha geniş zona.',
    'search.meta.dropped_schedule':
        'Seçilmiş vaxt üçün tapılmadı — digər vaxtlar göstərilir.',
    'search.meta.urgent_radius': 'Təcili: yalnız {km} km daxilində.',
    'search.matches_count': '{count} uyğunluq',
    'search.view_map': 'Xəritə',
    'search.view_list': 'Siyahı',
    'search.map_your_location': 'Sizin məkanınız',
    'search.map_unavailable': 'Xəritə',
    'search.map_providers_count': '{count} icraçı',
    'search.map_key_hint':
        'Xəritə üçün: flutter run --dart-define-from-file=dart_defines.json',
    'search.your_request': 'Sizin sorğunuz',
    'search.filter_category': 'Kateqoriya (istəyə bağlı)',
    'search.category_search_ph': 'Axtar və ya kateqoriya seç…',
    'search.category_empty': 'Uyğun kateqoriya yoxdur',
    'search.filter_when': 'Vaxt (istəyə bağlı)',
    'search.pick_datetime': 'Tarix və saat',
    'search.clear_filters': 'Təmizlə',
    'search.filters_loading': 'Kateqoriyalar yüklənir…',
    'search.category_fallback': 'Xidmət axtarışı',
    'search.filter_more': 'Əlavə filterlər (istəyə bağlı)',
    'search.child_age': 'Uşaq yaşı',
    'search.not_selected': 'Seçilməyib',
    'search.pet_yes': 'Ev heyvanı var',
    'search.pet_no': 'Ev heyvanı yoxdur',
    'search.slot.morning': 'Səhər',
    'search.slot.afternoon': 'Günorta',
    'search.slot.evening': 'Axşam',
    'search.slot.night': 'Gecə',
    'request.status.processing': 'Emal olunur',
    'request.status.matched': 'Uyğunlaşıb',
    'request.status.completed': 'Tamamlanıb',
    'request.status.cancelled': 'Ləğv edilib',
    'category.label': 'Kateqoriyalar',
    'category.max_reached': 'Maksimum {max} kateqoriya',
    'category.selected_count': 'Seçilib {count}/{max}',
    'category.search_hint': 'Axtar: dayə, təmizlik…',
    'category.not_found': 'Kateqoriya tapılmadı',
    'category.leaf_hint':
        'Yalnız konkret xidmət seçin (maks. {max}). Üst kateqoriya seçilmir.',
    'category.search_tap': 'Axtar və toxunun',
    'category.min_one': 'Ən azı bir kateqoriya seçin (maks. {max})',
    'welcome.skip': 'Keç',
    'welcome.next': 'Davam et',
    'welcome.start': 'Başla',
    'welcome.close': 'Bağla',
    'welcome.done': 'Anladım',
    'welcome.step1.title': 'My Sancho-ya xoş gəlmisiniz',
    'welcome.step1.body':
        'Ailə və ev xidmətləri bir yerdə — dayə, təmizlik, baxıcı və daha çoxu yaxınlığınızda.',
    'welcome.step2.title': 'Səsli sorğu',
    'welcome.step2.body':
        'Mikrofonu basıb ehtiyacınızı deyin. AI kateqoriya, vaxt və məkanı anlayır — yazmaq da olar.',
    'welcome.step3.title': 'Uyğun icraçılar',
    'welcome.step3.body':
        'Yaxınlıqdakı peşəkarlar süzülür: məsafə, cədvəl və kateqoriya nəzərə alınır.',
    'welcome.step4.title': 'CONNECT və razılaşın',
    'welcome.step4.body':
        'Seçdiyiniz icraçı ilə chatda yazışın, təklif göndərin və işi təsdiqləyin.',
    'onboarding.step.name': 'Sizi necə çağıraq?',
    'onboarding.step.categories': 'Nə xidmət göstərirsiniz?',
    'onboarding.step.location': 'Harada işləyirsiniz?',
    'onboarding.step.schedule': 'Hansı vaxtlar uyğunsunuz?',
    'onboarding.step.about': 'Qısa təqdimat',
    'onboarding.skip': 'Keç',
    'onboarding.continue': 'Davam et',
    'onboarding.create_profile': 'Profili yarat',
    'onboarding.saving': 'Yadda saxlanır…',
    'onboarding.name_required': 'Adınızı daxil edin',
    'onboarding.name_hint': 'Müştərilər sizi bu adla görəcək.',
    'onboarding.name_label': 'Ad, soyad',
    'onboarding.location_hint':
        'Axtarışda yaxınlıqdakı işlər bu məkana görə gələcək. Xəritədən seçin və ya ünvan yazın.',
    'onboarding.about_label': 'Haqqınızda',
    'onboarding.title_label': 'Başlıq',
    'onboarding.title_hint': 'məs. Təcrübəli dayə',
    'onboarding.banner.title': 'Profilinizi tamamlayın',
    'onboarding.banner.subtitle':
        'Tam profil daha çox iş gətirir · {percent}%',
    'onboarding.banner.cta': 'Davam et',
    'onboarding.banner.cta_create': 'Profil yarat',
    'onboarding.banner.dismiss': 'Bağla',
    'onboarding.missing.profile': 'Profil yoxdur',
    'onboarding.missing.categories': 'Kateqoriya',
    'onboarding.missing.location': 'Məkan',
    'onboarding.missing.schedule': 'Cədvəl',
    'onboarding.missing.about': 'Haqqında',
    'account.user_fallback': 'İstifadəçi',
    'account.role.provider': 'Xidmət göstərən',
    'account.role.client': 'Ailə / müştəri',
    'account.card.audio_intro': 'Audio intro yazın',
    'account.card.profiles': 'Xidmət',
    'account.card.wallet_bump': 'Pul kisəsi / bump',
    'account.card.voice_search': 'Səsli axtarış',
    'account.card.requests': 'Sorğularım',
    'account.card.chats': 'Söhbətlər',
    'account.card.verify': 'Verified sənəd',
    'account.menu.verify': 'Verified sənəd',
    'account.menu.profile_status': 'Profil statusu',
    'account.menu.wallet': 'Pul kisəsi · {balance} AZN',
    'account.menu.reviews': 'Rəylər',
    'account.menu.blocked': 'Bloklanmışlar',
    'account.menu.favorites': 'Seçilmişlər',
    'favorites.title': 'Seçilmişlər',
    'favorites.empty':
        'Hələ seçilmiş xidmətçi yoxdur.\nMatch və ya profil səhifəsindən əlavə edin.',
    'favorites.load_error': 'Seçilmişlər yüklənmədi',
    'favorites.added': 'Seçilmişlərə əlavə olundu',
    'favorites.removed': 'Seçilmişlərdən çıxarıldı',
    'favorites.remove_action': 'Çıxar',
    'favorites.remove_confirm': '{name} seçilmişlərdən çıxarılsın?',
    'favorites.toggle_add': 'Seçilmişə əlavə et',
    'favorites.toggle_remove': 'Seçilmişdən çıxar',
    'notifications.title': 'Bildirişlər',
    'notifications.empty': 'Bildiriş yoxdur.',
    'notifications.load_error': 'Bildirişlər yüklənmədi',
    'notifications.mark_all': 'Hamısını oxu',
    'notifications.marked_all': 'Hamısı oxundu',
    'notifications.filter.all': 'Hamısı',
    'notifications.filter.unread': 'Oxunmamış',
    'notifications.filter.read': 'Oxunmuş',
    'notifications.status.unread': 'Oxunmayıb',
    'notifications.status.read': 'Oxunub',
    'notifications.fallback_title': 'Bildiriş',
    'account.menu.switch_role': 'Rol dəyiş',
    'account.menu.settings': 'Parametrlər',
    'account.menu.info': 'Məlumat',
    'account.menu.language': 'Dil',
    'account.menu.how_it_works': 'Necə işləyir',
    'account.menu.logout': 'Çıxış',
    'account.logout.confirm_title': 'Çıxış',
    'account.logout.confirm_body': 'Hesabdan çıxmaq istəyirsiniz?',
    'common.cancel': 'Ləğv et',
    'static_page.load_error': 'Səhifə yüklənmədi',
    'locale.az': 'Azərbaycan',
    'locale.en': 'English',
    'locale.ru': 'Русский',
    'match.reason.distance': '{km} km',
    'match.reason.schedule_ok': 'Cədvəl uyğun',
    'match.reason.schedule_miss': 'Cədvəl uyğun deyil',
    'match.reason.category': '{name}',
    'match.reason.repeat_client': 'Əvvəl işlədiyiniz provayder',
    'match.reason.bump': 'Önə çıxıb · {hours} saat',
    'match.reason.bump_hint':
        'İcraçı profilini ödənişlə müvəqqəti yüksəldib — axtarışda daha görünəndir. Qalan: {hours} saat.',
    'web.request.voice_too_short':
        'Səs çox qısa və ya qeyri-müəyyəndir. Ən azı {sec} saniyə aydın danışın.',
    'web.request.voice_unclear':
        'Səs oxunmadı və ya qeyri-müəyyəndir. Nümunəyə bənzər aydın səs göndərin (3–20 san).',
    'provider.approval.pending_title': 'Təsdiq gözlənilir',
    'provider.approval.pending':
        'Sorğunuz 1 saat ərzində baxılacaq. Təsdiqləndikdən sonra iş sorğuları gələcək.',
    'provider.approval.approved':
        'Hesabınız təsdiqləndi. İndi iş sorğuları gələ bilər.',
    'web.status.approved': 'Təsdiqli',
    'web.status.rejected': 'Rədd edilib',
    'web.status.blocked': 'Bloklanıb',
    'web.status.pending': 'Gözləyir',
    'provider.approval.rejected_title': 'Qeydiyyat rədd edilib',
    'provider.approval.rejected':
        'Hesabınız rədd edilib. Dəstəklə əlaqə saxlayın və ya profili tamamlayın.',
    'provider.approval.complete_profile': 'Profili tamamla',
    'provider.approval.refresh': 'Statusu yenilə',
    'provider.approval.view_reason': 'Rədd səbəbinə bax',
    'provider.approval.reject_reason_label': 'Admin rədd səbəbi',
    'provider.approval.resubmit_hint':
        'Profil və kateqoriyaları düzəldib yenidən baxışa göndərə bilərsiniz.',
    'provider.approval.resubmit': 'Yenidən baxışa göndər',
    'provider.approval.resubmit_done':
        'Yenidən baxışa göndərildi. Admin təsdiqini gözləyin.',
    'account.upload_photo': 'Şəkil yüklə',
    'account.photo_updated': 'Şəkil yeniləndi',
    'profiles.title': 'Xidmət profili',
    'profiles.empty': 'Hələ xidmət profili yoxdur.\nProfil yaradın.',
    'profiles.fallback_name': 'Profil',
    'profiles.status.published': 'PUBLISHED',
    'profiles.status.new': 'NEW',
    'profiles.bump_success': 'Bump. Balans: {balance} AZN',
    'profiles.bump_remaining': 'Önə çıxıb · {hours} saat',
    'profiles.bump_limit': 'Bu gün bump limitiniz bitib',
    'profiles.delete_title': 'Silinsin?',
    'profiles.delete_no': 'Xeyr',
    'profiles.delete_yes': 'Bəli',
    'profiles.badge.verified': 'Verified',
    'profiles.badge.vip': 'VIP',
    'profile.form.saved': 'Profil yadda saxlanıldı',
    'profile.form.edit_title': 'Profil redaktə',
    'profile.form.new_title': 'Yeni profil',
    'profile.form.title_label': 'Başlıq',
    'profile.form.bio_label': 'Haqqında',
    'profile.form.saving': 'SAXLANILIR...',
    'profile.form.save': 'SAXLA VƏ DAVAM ET',
    'profile.availability.title': 'Əlçatanlıq',
    'profile.availability.full_week': 'Bu həftə doluyam',
    'profile.availability.full_week_hint':
        'Axtarışda görünməyəcəksiniz, bazar gününə qədər.',
    'profile.availability.quiet': 'Səssiz saatlar',
    'profile.availability.quiet_hint':
        'Bu saatlarda bildiriş gəlməz. Təcili sorğular istisnadır.',
    'profile.availability.quiet_none': 'Yoxdur',
    'profile.availability.quiet_custom': 'Öz saatım',
    'profile.badge.full': 'Bu həftə dolu',
    'profile.badge.quiet': 'Səssiz {from}–{to}',
    'schedule.title': 'Cədvəl',
    'schedule.hint': 'Uyğun gün və saatları seçin',
    'web.schedule.morning': 'Səhər',
    'web.schedule.afternoon': 'Günorta',
    'web.schedule.evening': 'Axşam',
    'web.schedule.night': 'Gecə',
    'web.schedule.morning_short': 'Səhər',
    'web.schedule.afternoon_short': 'Gün.',
    'web.schedule.evening_short': 'Axş.',
    'web.schedule.night_short': 'Gecə',
    'web.schedule.day_1': 'B.e',
    'web.schedule.day_2': 'Ç.a',
    'web.schedule.day_3': 'Ç',
    'web.schedule.day_4': 'C.a',
    'web.schedule.day_5': 'C',
    'web.schedule.day_6': 'Ş',
    'web.schedule.day_7': 'B',
    'location.city_hint': 'Şəhər seçin',
    'location.district_label': 'Rayon / qəsəbə',
    'location.district_pick_city': 'Əvvəl şəhər seçin',
    'location.district_hint': 'Rayon seçin',
    'location.search_address': 'Ünvan axtar',
    'location.maps_key_missing':
        'Xəritə üçün Google Maps açarı lazımdır. GPS və ünvan axtarışı da eyni açarı istifadə edir.',
    'location.my_gps': 'Mənim yerim',
    'category.add': 'Əlavə et',
    'category.done': 'Hazır',
    'jobs.title': 'İşlər',
    'jobs.subtitle': 'Sizə uyğun müştəri sorğuları',
    'jobs.empty':
        'Hələ uyğun iş yoxdur.\nProfilinizi aktiv saxlayın — müştəri axtaranda burada görünəcək.',
    'jobs.client_fallback': 'Müştəri',
    'jobs.reply_opening': 'AÇILIR…',
    'jobs.reply': 'CAVAB VER',
    'jobs.when': 'Vaxt: {when}',
    'jobs.detail_title': 'İş haqqında',
    'jobs.detail_request': 'Sorğu',
    'jobs.detail_match': 'Niyə uyğundur',
    'jobs.open_detail': 'Ətraflı bax →',
    'jobs.audio_play': 'Səsli sorğunu dinlə',
    'jobs.audio_stop': 'Dayandır',
    'jobs.audio_hint': 'Müştərinin yazdığı orijinal səs',
    'jobs.created_at': 'Yaradılıb: {when}',
    'jobs.expires_at': 'Bitir: {when}',
    'requests.empty':
        'Hələ sorğu yoxdur.\nAxtar tabında səs və ya mətn göndərin.',
    'requests.item_fallback': 'Sorğu #{id}',
    'requests.matches_count': '{count} uyğunluq',
    'requests.when': 'Vaxt: {when}',
    'requests.duration_hours': '{hours} saat',
    'web.requests.filter_all': 'Hamısı',
    'web.requests.filter_matched': 'Uyğunlaşan',
    'web.requests.filter_unmatched': 'Uyğunlaşmayan',
    'web.requests.filter_empty': 'Bu filterə uyğun sorğu yoxdur.',
    'web.requests.page_info': 'Səhifə {page} / {last} · {total} sorğu',
    'web.requests.prev': 'Əvvəl',
    'web.requests.next': 'Sonra',
    'chat.title': 'Chat',
    'chat.tab.current': 'Cari',
    'chat.tab.archive': 'Arxiv',
    'chat.empty_title': 'Hələ söhbət yoxdur',
    'chat.empty': 'Match-də Connect basın — yazışma burada açılacaq.',
    'chat.archive_empty': 'Arxiv boşdur',
    'chat.archive_empty_body': 'Arxivlənmiş söhbətlər burada görünəcək.',
    'chat.search_hint': 'Ad və ya mesaj axtar…',
    'chat.search_empty': 'Nəticə yoxdur',
    'chat.search_empty_body': 'Başqa sözlə yenidən axtarın.',
    'chat.new_preview': 'Yeni söhbət',
    'chat.yesterday': 'Dünən',
    'chat.fallback_name': 'Söhbət',
    'chat.message_hint': 'Mesaj yazın…',
    'chat.blocked_badge': 'Bloklanıb',
    'chat.blocked_hint':
        'Bu söhbət bloklanıb. Tarixçəyə baxa bilərsiniz, mesaj göndərmək olmur.',
    'chat.blocked_by_me_hint':
        'Bu istifadəçini bloklamısınız. Tarixçə açıqdır; mesaj üçün bloku götürün.',
    'chat.blocked_composer': 'Bloklanmış söhbətdə mesaj göndərmək olmur',
    'offer.title': 'Təklif',
    'offer.compose_title': 'Təklif göndər',
    'offer.pick_time': 'Tarix və saat seçin',
    'offer.price_label': 'Qiymət (AZN)',
    'offer.hours_label': 'Müddət (saat, istəyə bağlı)',
    'offer.note_label': 'Qeyd (istəyə bağlı)',
    'offer.send': 'GÖNDƏR',
    'offer.sending': 'GÖNDƏRİLİR…',
    'offer.accept': 'Qəbul et',
    'offer.decline': 'Rədd et',
    'offer.complete': 'İş tamamlandı',
    'offer.cancel': 'Ləğv et',
    'offer.duration': '{hours} saat',
    'offer.price_required': 'Qiymət daxil edin',
    'offer.time_future': 'Vaxt gələcəkdə olmalıdır',
    'offer.status.pending': 'Gözləyir',
    'offer.status.accepted': 'Təsdiq',
    'offer.status.completed': 'Bitdi',
    'offer.status.declined': 'Rədd',
    'offer.status.cancelled': 'Ləğv',
    'review.write': 'Rəy yaz',
    'review.compose_title': 'İş haqqında rəy',
    'review.comment_label': 'Şərh (istəyə bağlı)',
    'review.send': 'GÖNDƏR',
    'review.sending': 'GÖNDƏRİLİR…',
    'review.stars_required': 'Ulduz seçin',
    'review.yours': 'Sizin rəyiniz',
    'review.theirs': 'Onların rəyi',
    'review.list_title': 'Rəylər',
    'review.empty': 'Hələ rəy yoxdur',
    'verify.title': 'Verified sənəd',
    'verify.subtitle': 'Şəxsiyyət vəsiqəsi və ya pasport yükləyin. Admin yoxladıqdan sonra profilinizdə Verified badge görünəcək.',
    'verify.empty': 'Hələ sənəd yükləməmisiniz.',
    'verify.upload': 'SƏNƏD YÜKLƏ',
    'verify.uploading': 'YÜKLƏNİR…',
    'verify.pending_hint': 'Sənəd yoxlanılır — admin cavabını gözləyin.',
    'verify.latest': 'Son sənəd',
    'verify.history': 'Keçmiş',
    'verify.status.pending': 'Gözləyir',
    'verify.status.approved': 'Təsdiqlənib',
    'verify.status.rejected': 'Rədd edilib',
    'report.menu': 'Şikayət et',
    'report.title': 'Şikayət',
    'report.details_label': 'Əlavə qeyd (istəyə bağlı)',
    'report.send': 'GÖNDƏR',
    'report.sending': 'GÖNDƏRİLİR…',
    'report.reason_required': 'Səbəb seçin',
    'report.reason.spam': 'Spam',
    'report.reason.harassment': 'Təzyiq',
    'report.reason.fraud': 'Fırıldaq',
    'report.reason.inappropriate': 'Uyğun deyil',
    'report.reason.other': 'Digər',
    'block.menu': 'Blokla',
    'block.title': 'Blokla',
    'block.confirm':
        'Bu istifadəçini bloklamaq istəyirsiniz? Söhbət tarixçəsi qalacaq, amma heç bir tərəf mesaj göndərə bilməyəcək.',
    'block.confirm.client':
        'Bu xidmətçini bloklamaq istəyirsiniz? Bundan sonra sorğularınızın nəticəsində görünməyəcək və mesaj yazmaq olmaz. Söhbət tarixçəsi qalacaq.',
    'block.confirm.provider':
        'Bu müştərini bloklamaq istəyirsiniz? Bundan sonra onun işləri sizə gəlməyəcək və mesaj yazmaq olmaz. Söhbət tarixçəsi qalacaq.',
    'block.cancel': 'Ləğv',
    'block.confirm_action': 'Blokla',
    'block.done': 'İstifadəçi bloklandı',
    'block.list_title': 'Bloklanmışlar',
    'block.empty': 'Bloklanmış istifadəçi yoxdur.',
    'block.load_error': 'Siyahı yüklənmədi',
    'block.unblock_title': 'Bloku götür',
    'block.unblock_confirm': '{name} üçün bloku götürmək istəyirsiniz?',
    'block.unblock_action': 'Bloku götür',
    'block.unblocked': 'Blok götürüldü',
    'bookings.title': 'İşlərim',
    'bookings.upcoming': 'Gələcək',
    'bookings.past': 'Keçmiş',
    'bookings.empty': 'Hələ təsdiqlənmiş iş yoxdur.\nChat-də təklif qəbul edəndə burada görünəcək.',
    'bookings.open_chat': 'Chat',
    'bookings.cancel_title': 'İşi ləğv et',
    'bookings.cancel_confirm': 'Planlaşdırılmış iş ləğv olunsun?',
    'bookings.cancel_action': 'Ləğv et',
    'bookings.cancelling': 'Ləğv…',
    'bookings.status.scheduled': 'Planlaşdırılıb',
    'bookings.status.completed': 'Bitib',
    'bookings.status.cancelled': 'Ləğv',
    'account.menu.bookings': 'İşlərim (booking)',
    'match.provider_fallback': 'İcraçı',
    'match.score': '{score}% uyğunluq',
    'match.connecting': 'QOŞULUR…',
    'match.connect': 'CONNECT',
    'match.connect_remaining': 'Bu gün {count} CONNECT qalıb',
    'match.connect_free': 'Pulsuz CONNECT: {left}/{quota} qalıb · bu gün {count}',
    'match.connect_free_open': 'CONNECT pulsuzdur · bu gün {count} qalıb',
    'match.connect_paid': 'CONNECT · {fee} AZN · bu gün {count} qalıb',
    'match.view_profile': 'Profilə bax',
    'provider.profile_title': 'Xidmətçi',
    'provider.about': 'Haqqında',
    'provider.play_intro': 'Audio intro',
    'provider.stop_intro': 'Dayandır',
    'wallet.title': 'Pul kisəsi',
    'wallet.transactions': 'Tranzaksiyalar',
    'wallet.empty': 'Hələ tranzaksiya yoxdur',
    'audio.title': 'Audio intro',
    'audio.hint': 'Qısa səsli tanıtım (maks. 20 san)',
    'audio.record_stop': 'Dayandır {time}',
    'audio.record': 'Yaz',
    'audio.ready_upload':
        'Yeni yazı hazırdır (yadda saxlananda yüklənəcək)',
    'audio.existing': 'Mövcud intro yüklənib',
    'audio.play_failed': 'Səs oxunmadı',
    'search.mic_required': 'Mikrofon icazəsi lazımdır',
    'search.input_required': 'Səs yazın və ya mətni daxil edin',
    'search.still_processing': 'Emal hələ davam edir — sonra yeniləyin',
    'search.ttl.title': 'Sorğu nə qədər açıq qalsın?',
    'search.ttl.body':
        'Bu müddətdən sonra yeni əlaqə və cavab bağlanır. İstədiyinizi seçib təsdiqləyin.',
    'search.ttl.hours': '{hours} saat',
    'search.ttl.default_badge': 'Standart',
    'search.ttl.confirm': 'Təsdiqlə',
    'search.urgent_sent': 'Təcili bildiriş göndərildi. Qalan: {balance} AZN',
    'common.balance_remaining': 'Qalan:',
    'common.retry': 'Yenidən cəhd et',
    'error.cache': 'Yerli məlumat oxunmadı',
    'location.city_label': 'Şəhər',
    'location.rayon_suffix': '{name} rayonu',
    'location.address_hint': 'məs. Nərimanov, Gənclik…',
    'search.fee_total': 'Balansdan çıxılacaq: {amount} AZN',
    'search.fee_breakdown': 'Axtarış: {base} AZN',
    'search.fee_breakdown_urgent':
        'Axtarış: {base} AZN + Təcili: {urgent} AZN',
    'search.budget_max': '<= {amount} AZN',
    'wallet.load_failed': 'Pul kisəsi yüklənmədi',
    'error.network':
        'API-yə qoşulmaq mümkün olmadı. Mac və telefon eyni Wi‑Fi-də olmalıdır.',
    'error.generic': 'Xəta baş verdi',
    'push.new_job.title': 'Sizə uyğun sorğu',
    'push.new_job.body': 'İşlər tabında yeni sorğuya baxın',
    'push.urgent.title': 'Təcili sorğu',
  };
}

String t(String key, {Map<String, String>? params}) =>
    AppRemoteConfig.instance.t(key, params: params);
