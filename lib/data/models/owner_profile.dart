class OwnerProfile {
  final String id;
  final String name;
  final String email;
  final String imageUrl;

  const OwnerProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.imageUrl,
  });

  factory OwnerProfile.fromJson(Map<String, dynamic> json) {
    return OwnerProfile(
      id: (json['id'] ?? json['owner_id'] ?? '').toString(),
      name: (json['name'] ?? json['full_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      imageUrl: (json['image'] ?? json['avatar'] ?? json['profile_image'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'image': imageUrl,
      };
}

