class InvGateUser {
  final int id;
  final String? name;
  final String? lastname;
  final String? email;
  final int? type;

  InvGateUser({
    required this.id,
    this.name,
    this.lastname,
    this.email,
    this.type,
  });

  factory InvGateUser.fromJson(Map<String, dynamic> json) {
    return InvGateUser(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String?,
      lastname: json['lastname'] as String?,
      email: json['email'] as String?,
      type: json['type'] as int?,
    );
  }

  String get displayName {
    final nameParts = [name, lastname].where((part) => part != null && part.isNotEmpty).toList();
    if (nameParts.isNotEmpty) {
      return nameParts.join(' ').trim();
    }
    if (email != null && email!.isNotEmpty) {
      return email!;
    }
    return 'User #$id';
  }

  bool get isAgent => type == 1;
  bool get isEndUser => type == 2;
}

