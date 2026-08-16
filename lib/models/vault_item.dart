class VaultItem {
  final int? id;
  final String name;
  final String? username;
  final String secret;
  final String? note;
  final String category;
  final String createdAt;

  VaultItem({
    this.id,
    required this.name,
    this.username,
    required this.secret,
    this.note,
    required this.category,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'secret': secret,
      'note': note,
      'category': category,
      'createdAt': createdAt,
    };
  }

  factory VaultItem.fromMap(Map<String, dynamic> map) {
    return VaultItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      username: map['username'] as String?,
      secret: map['secret'] as String,
      note: map['note'] as String?,
      category: map['category'] as String,
      createdAt: map['createdAt'] as String,
    );
  }
}
