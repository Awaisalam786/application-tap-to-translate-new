import '../../../auth/domain/admin_user_model.dart';

class LexiconExample {
  final String id;
  final String entryId;
  final String sentenceDe;
  final String? sentenceEn;
  final String? sentenceUr;
  final String? cefrLevel;
  final String status;
  final String sourceType;
  final String? createdBy;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LexiconExample({
    required this.id,
    required this.entryId,
    required this.sentenceDe,
    this.sentenceEn,
    this.sentenceUr,
    this.cefrLevel,
    this.status = 'draft',
    this.sourceType = 'original_curated',
    this.createdBy,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LexiconExample.fromJson(Map<String, dynamic> json) {
    return LexiconExample(
      id: json['id'] as String,
      entryId: json['entry_id'] as String,
      sentenceDe: json['sentence_de'] as String? ?? '',
      sentenceEn: json['sentence_en'] as String?,
      sentenceUr: json['sentence_ur'] as String?,
      cefrLevel: json['cefr_level'] as String?,
      status: json['status'] as String? ?? 'draft',
      sourceType: json['source_type'] as String? ?? 'original_curated',
      createdBy: json['created_by'] as String?,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entry_id': entryId,
      'sentence_de': sentenceDe,
      'sentence_en': sentenceEn,
      'sentence_ur': sentenceUr,
      'cefr_level': cefrLevel,
      'status': status,
      'source_type': sourceType,
      'created_by': createdBy,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  LexiconExample copyWith({
    String? id,
    String? entryId,
    String? sentenceDe,
    String? sentenceEn,
    String? sentenceUr,
    String? cefrLevel,
    String? status,
    String? sourceType,
    String? createdBy,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LexiconExample(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      sentenceDe: sentenceDe ?? this.sentenceDe,
      sentenceEn: sentenceEn ?? this.sentenceEn,
      sentenceUr: sentenceUr ?? this.sentenceUr,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      status: status ?? this.status,
      sourceType: sourceType ?? this.sourceType,
      createdBy: createdBy ?? this.createdBy,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool canEdit(AdminRole role) {
    if (role == AdminRole.superadmin || role == AdminRole.reviewer) return true;
    if (role == AdminRole.editor) return status != 'verified';
    return false;
  }

  bool canVerify(AdminRole role) {
    return role == AdminRole.superadmin || role == AdminRole.reviewer;
  }

  bool canDelete(AdminRole role) {
    return role == AdminRole.superadmin;
  }
}
