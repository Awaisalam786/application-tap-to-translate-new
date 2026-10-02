import '../../../auth/domain/admin_user_model.dart';

class LexiconTranslation {
  final String id;
  final String entryId;
  final String targetLang;
  final String translation;
  final String? contextNotes;
  final String status;
  final String sourceType;
  final String? provider;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LexiconTranslation({
    required this.id,
    required this.entryId,
    required this.targetLang,
    required this.translation,
    this.contextNotes,
    this.status = 'draft',
    this.sourceType = 'manual',
    this.provider = 'human',
    this.verifiedBy,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  static String languageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ur':
        return 'Urdu';
      case 'fa':
        return 'Persian (Farsi)';
      case 'ar':
        return 'Arabic';
      default:
        return code.toUpperCase();
    }
  }

  factory LexiconTranslation.fromJson(Map<String, dynamic> json) {
    return LexiconTranslation(
      id: json['id'] as String,
      entryId: json['entry_id'] as String,
      targetLang: json['target_lang'] as String? ?? 'en',
      translation: json['translation'] as String? ?? '',
      contextNotes: json['context_notes'] as String?,
      status: json['status'] as String? ?? 'draft',
      sourceType: json['source_type'] as String? ?? 'manual',
      provider: json['provider'] as String? ?? 'human',
      verifiedBy: json['verified_by'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'] as String)
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
      'target_lang': targetLang,
      'translation': translation,
      'context_notes': contextNotes,
      'status': status,
      'source_type': sourceType,
      'provider': provider,
      'verified_by': verifiedBy,
      'verified_at': verifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  LexiconTranslation copyWith({
    String? id,
    String? entryId,
    String? targetLang,
    String? translation,
    String? contextNotes,
    String? status,
    String? sourceType,
    String? provider,
    String? verifiedBy,
    DateTime? verifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LexiconTranslation(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      targetLang: targetLang ?? this.targetLang,
      translation: translation ?? this.translation,
      contextNotes: contextNotes ?? this.contextNotes,
      status: status ?? this.status,
      sourceType: sourceType ?? this.sourceType,
      provider: provider ?? this.provider,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
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
