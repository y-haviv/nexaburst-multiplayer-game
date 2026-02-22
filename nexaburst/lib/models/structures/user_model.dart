// nexaburst/lib/models/structures/user_model.dart

/// Application user representation, including profile details and stats.
class UserModel {
  /// Unique user identifier (e.g., Firebase UID or local ID).
  final String id;

  /// Chosen display name of the user.
  final String username;

  /// User’s email address for authentication or contact.
  final String email;

  /// Preferred language code (e.g., 'en', 'he').
  final String language;

  /// Age of the user in years.
  final int age;

  /// URL or asset identifier for the user’s avatar image.
  final String avatar;

  /// Total number of game wins recorded for this user.
  final int wins;

  /// Constructs a [UserModel] with all required profile and stats fields.
  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.language,
    required this.age,
    required this.avatar,
    required this.wins,
  });

  /// Constructs a [UserModel] with all required profile and stats fields.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'language': language,
      'age': age,
      'avatar': avatar,
      'wins': wins,
    };
  }

  /// Builds a [UserModel] from a map (from Firestore or local preferences),
  /// applying defaults for missing 'id' or 'wins'.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? "", // Ensure ID is always set
      username: map['username'],
      email: map['email'],
      language: map['language'],
      age: map['age'],
      avatar: map['avatar'],
      wins: map['wins'] ?? 0, // Default to 0 if not provided
    );
  }
}
