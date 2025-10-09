import 'dart:convert';
import 'package:vestiq/core/models/clothing_analysis.dart';

/// Represents a user's saved outfit, including the generated mannequins.
class SavedOutfit {
  final String id;
  final String title;
  final List<ClothingAnalysis> items;
  final List<String> mannequinImages;
  final String notes;
  final String occasion;
  final String style;
  final double matchScore;
  final DateTime createdAt;
  final bool? isFavorite;

  const SavedOutfit({
    required this.id,
    required this.title,
    required this.items,
    this.mannequinImages = const [],
    this.notes = '',
    this.occasion = '',
    this.style = '',
    this.matchScore = 0.0,
    required this.createdAt,
    this.isFavorite,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'items': items.map((item) => item.toJson()).toList(),
      'mannequinImages': mannequinImages,
      'notes': notes,
      'occasion': occasion,
      'style': style,
      'matchScore': matchScore,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  /// Convert to JSON string for storage
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON
  factory SavedOutfit.fromJson(Map<String, dynamic> json) {
    return SavedOutfit(
      id: json['id'] as String,
      title: json['title'] as String,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => ClothingAnalysis.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      mannequinImages:
          (json['mannequinImages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      notes: json['notes'] as String? ?? '',
      occasion: json['occasion'] as String? ?? '',
      style: json['style'] as String? ?? '',
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isFavorite: json['isFavorite'] as bool?,
    );
  }
}
