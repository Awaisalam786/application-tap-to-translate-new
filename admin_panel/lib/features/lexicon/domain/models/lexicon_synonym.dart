import '../../../auth/domain/admin_user_model.dart';

class LexiconSynonym {
  final String id;
  final String entryId;
  final String synonymWord;
  final String? nuanceNote;
  final String status;
  final String sourceType;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LexiconSynonym({
    required this.id,
    required this.entryId,
    required this.synonymWord,
    this.nuanceNote,
    this.status = 'draft',
    this.sourceType = 'manual',
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LexiconSynonym.fromJson(Map<String, dynamic> json) {
    return LexiconSynonym(
      id: json['id'] as String,
      entryId: json['entry_id'] as String,
      synonymWord: json['synonym_word'] as String? ?? '',
      nuanceNote: json['nuance_note'] as String?,
      status: json['status'] as String? ?? 'draft',
      sourceType: json['source_type'] as String? ?? 'manual',
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
      'synonym_word': synonymWord,
      'nuance_note': nuanceNote,
      'status': status,
      'source_type': sourceType,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  LexiconSynonym copyWith({
    String? id,
    String? entryId,
    String? synonymWord,
    String? nuanceNote,
    String? status,
    String? sourceType,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LexiconSynonym(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      synonymWord: synonymWord ?? this.synonymWord,
      nuanceNote: nuanceNote ?? this.nuanceNote,
      status: status ?? this.status,
      sourceType: sourceType ?? this.sourceType,
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
