/// User payload returned by Helios Core after Google exchange.
class HeliosUser {
  const HeliosUser({
    required this.id,
    required this.email,
    this.name,
    this.avatar,
    this.phone,
  });

  final String id;
  final String email;
  final String? name;
  final String? avatar;
  final String? phone;

  String get displayLabel => (name != null && name!.trim().isNotEmpty)
      ? name!.trim()
      : email;

  factory HeliosUser.fromJson(Map<String, dynamic> json) {
    return HeliosUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'avatar': avatar,
        'phone': phone,
      };
}
