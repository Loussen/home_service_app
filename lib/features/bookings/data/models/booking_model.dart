class BookingModel {
  const BookingModel({
    required this.id,
    required this.conversationId,
    required this.scheduledAt,
    required this.priceAzn,
    required this.status,
    this.offerId,
    this.durationHours,
    this.note,
    this.otherUserName,
    this.profileTitle,
    this.categoryName,
  });

  final int id;
  final int conversationId;
  final DateTime scheduledAt;
  final double priceAzn;
  final String status;
  final int? offerId;
  final double? durationHours;
  final String? note;
  final String? otherUserName;
  final String? profileTitle;
  final String? categoryName;

  bool get isScheduled => status == 'scheduled';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final other = json['other_user'];
    return BookingModel(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      priceAzn: (json['price_azn'] as num).toDouble(),
      status: json['status'] as String? ?? 'scheduled',
      offerId: json['offer_id'] as int?,
      durationHours: (json['duration_hours'] as num?)?.toDouble(),
      note: json['note'] as String?,
      otherUserName: other is Map ? other['name'] as String? : null,
      profileTitle: json['profile_title'] as String?,
      categoryName: json['category_name'] as String?,
    );
  }
}
