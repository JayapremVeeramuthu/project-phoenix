class CustomerDto {
  final String id;
  final String name;
  final String? email;
  final String phoneNumber;
  final String? avatarUrl;
  final String createdAt;

  CustomerDto({
    required this.id,
    required this.name,
    this.email,
    required this.phoneNumber,
    this.avatarUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt,
    };
  }

  factory CustomerDto.fromJson(Map<String, dynamic> json) {
    return CustomerDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
