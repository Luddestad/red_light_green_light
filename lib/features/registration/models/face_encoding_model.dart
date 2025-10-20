import 'dart:math';

/// Represents face encoding data for player identification
class FaceEncodingData {
  final List<double> encoding;
  final String playerId;
  final DateTime createdAt;
  final double confidence;

  const FaceEncodingData({
    required this.encoding,
    required this.playerId,
    required this.createdAt,
    required this.confidence,
  });

  /// Calculate similarity with another face encoding using cosine similarity
  double similarityTo(FaceEncodingData other) {
    if (encoding.length != other.encoding.length) {
      return 0.0;
    }

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < encoding.length; i++) {
      dotProduct += encoding[i] * other.encoding[i];
      normA += encoding[i] * encoding[i];
      normB += other.encoding[i] * other.encoding[i];
    }

    if (normA == 0.0 || normB == 0.0) {
      return 0.0;
    }

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// Check if this face encoding matches another with given threshold
  bool matches(FaceEncodingData other, {double threshold = 0.8}) {
    return similarityTo(other) >= threshold;
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'encoding': encoding,
      'playerId': playerId,
      'createdAt': createdAt.toIso8601String(),
      'confidence': confidence,
    };
  }

  /// Create from JSON
  factory FaceEncodingData.fromJson(Map<String, dynamic> json) {
    return FaceEncodingData(
      encoding: List<double>.from(json['encoding']),
      playerId: json['playerId'],
      createdAt: DateTime.parse(json['createdAt']),
      confidence: json['confidence'].toDouble(),
    );
  }

  @override
  String toString() {
    return 'FaceEncodingData(playerId: $playerId, confidence: $confidence, encodingLength: ${encoding.length})';
  }
}
