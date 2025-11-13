import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single wear event - when a user wore an item or outfit
class WearHistoryEvent {
  final String id;
  final String userId;
  final String? itemId; // Wardrobe item ID if single item
  final String? outfitId; // Saved outfit ID if outfit
  final DateTime wornAt;
  final String? occasion; // Where it was worn
  final String? weather; // Weather condition
  final double? userRating; // User's rating 1-5
  final String? notes; // Optional user notes
  final List<String> tags; // Tags like "comfortable", "got compliments"

  const WearHistoryEvent({
    required this.id,
    required this.userId,
    this.itemId,
    this.outfitId,
    required this.wornAt,
    this.occasion,
    this.weather,
    this.userRating,
    this.notes,
    this.tags = const [],
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'itemId': itemId,
      'outfitId': outfitId,
      'wornAt': Timestamp.fromDate(wornAt),
      'occasion': occasion,
      'weather': weather,
      'userRating': userRating,
      'notes': notes,
      'tags': tags,
    };
  }

  /// Create from Firestore document
  factory WearHistoryEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return WearHistoryEvent(
      id: doc.id,
      userId: data['userId'] as String,
      itemId: data['itemId'] as String?,
      outfitId: data['outfitId'] as String?,
      wornAt: (data['wornAt'] as Timestamp).toDate(),
      occasion: data['occasion'] as String?,
      weather: data['weather'] as String?,
      userRating: (data['userRating'] as num?)?.toDouble(),
      notes: data['notes'] as String?,
      tags: List<String>.from(data['tags'] as List? ?? []),
    );
  }

  WearHistoryEvent copyWith({
    String? id,
    String? userId,
    String? itemId,
    String? outfitId,
    DateTime? wornAt,
    String? occasion,
    String? weather,
    double? userRating,
    String? notes,
    List<String>? tags,
  }) {
    return WearHistoryEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemId: itemId ?? this.itemId,
      outfitId: outfitId ?? this.outfitId,
      wornAt: wornAt ?? this.wornAt,
      occasion: occasion ?? this.occasion,
      weather: weather ?? this.weather,
      userRating: userRating ?? this.userRating,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
    );
  }
}
