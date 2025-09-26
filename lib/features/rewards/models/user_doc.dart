class UserDoc {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final int impactScore;
  const UserDoc({required this.uid, this.displayName, this.email, this.photoURL, this.impactScore = 0});
  factory UserDoc.fromMap(String id, Map<String, dynamic> m) => UserDoc(
        uid: id,
        displayName: m['displayName'],
        email: m['email'],
        photoURL: m['photoURL'],
        impactScore: (m['impactScore'] ?? 0) as int,
      );
}