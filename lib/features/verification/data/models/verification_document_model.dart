class VerificationDocumentModel {
  const VerificationDocumentModel({
    required this.id,
    required this.documentType,
    required this.status,
    this.providerProfileId,
    this.filePublicUrl,
    this.adminNote,
    this.reviewedAt,
    this.createdAt,
  });

  final int id;
  final int? providerProfileId;
  final String documentType;
  final String status;
  final String? filePublicUrl;
  final String? adminNote;
  final DateTime? reviewedAt;
  final DateTime? createdAt;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory VerificationDocumentModel.fromJson(Map<String, dynamic> json) {
    return VerificationDocumentModel(
      id: json['id'] as int,
      providerProfileId: json['provider_profile_id'] as int?,
      documentType: json['document_type'] as String? ?? 'id_card',
      status: json['status'] as String? ?? 'pending',
      filePublicUrl: json['file_public_url'] as String?,
      adminNote: json['admin_note'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
