import 'dart:convert';

import 'package:outfit_matcher/core/models/clothing_analysis.dart';
import 'package:outfit_matcher/core/models/wardrobe_item.dart';

/// Represents a user's saved outfit, including the generated mannequins.
class SavedOutfit {
  final String id;
  final String title;
  final List<ClothingAnalysis> items;
  final List<String> wardrobeItemIds; // references to WardrobeItem entries
  final List<String> mannequinImages; // base64 or remote URLs
  final String? notes;
  final String? occasion;
  final String? style;
  final double? matchScore;
  final DateTime createdAt;

  const SavedOutfit({
    required this.id,
    required this.title,
    required this.items,
    required this.mannequinImages,
    this.wardrobeItemIds = const [],
    this.notes,
    this.occasion,
    this.style,
    this.matchScore,
    required this.createdAt,
  });

  SavedOutfit copyWith({
    String? id,
    String? title,
    List<ClothingAnalysis>? items,
    List<String>? wardrobeItemIds,
    List<String>? mannequinImages,
    String? notes,
    String? occasion,
    String? style,
    double? matchScore,
    DateTime? createdAt,
  }) {
    return SavedOutfit(
      id: id ?? this.id,
      title: title ?? this.title,
      items: items ?? this.items,
      wardrobeItemIds: wardrobeItemIds ?? this.wardrobeItemIds,
      mannequinImages: mannequinImages ?? this.mannequinImages,
      notes: notes ?? this.notes,
      occasion: occasion ?? this.occasion,
      style: style ?? this.style,
      matchScore: matchScore ?? this.matchScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory SavedOutfit.fromJson(Map<String, dynamic> json) {
    return SavedOutfit(
      id: json['id'] as String,
      title: json['title'] as String,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => ClothingAnalysis.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      wardrobeItemIds:
          (json['wardrobeItemIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      mannequinImages:
          (json['mannequinImages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      notes: json['notes'] as String?,
      occasion: json['occasion'] as String?,
      style: json['style'] as String?,
      matchScore: (json['matchScore'] as num?)?.toDouble(),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'items': items.map((item) => item.toJson()).toList(),
      'wardrobeItemIds': wardrobeItemIds,
      'mannequinImages': mannequinImages,
      'notes': notes,
      'occasion': occasion,
      'style': style,
      'matchScore': matchScore,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String toJsonString() => jsonEncode(toJson());
}
