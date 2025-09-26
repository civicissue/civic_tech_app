import 'package:cloud_firestore/cloud_firestore.dart';

class ReportDoc {
  final String id;
  final String authorId;
  final String category; // e.g., pothole, garbage, streetlight, other
  final String status; // submitted, acknowledged, in_progress, resolved, invalid
  final String description; // required
  final String imageUrl; // required
  final GeoPoint location; // required
  final String address; // required
  final DateTime createdAt;

  const ReportDoc({
    required this.id,
    required this.authorId,
    required this.category,
    required this.status,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.address,
    required this.createdAt,
  });

  factory ReportDoc.fromMap(String id, Map<String, dynamic> m) => ReportDoc(
        id: id,
        authorId: m['authorId'] ?? '',
        category: m['category'] ?? 'other',
        status: m['status'] ?? 'submitted',
        description: (m['description'] ?? '') as String,
        imageUrl: (m['imageUrl'] ?? '') as String,
        location: m['location'] as GeoPoint,
        address: (m['address'] ?? '') as String,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'category': category,
        'status': status,
        'description': description,
        'imageUrl': imageUrl,
        'location': location,
        'address': address,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
