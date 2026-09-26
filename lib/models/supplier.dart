class Supplier {
  final int id;
  final String name;
  final String country;
  final String contactPerson;
  final String phone;
  final String email;
  final double rating;
  final DateTime? deletedAt;

  const Supplier({
    required this.id,
    required this.name,
    required this.country,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.rating,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Supplier copyWith({
    String? name,
    String? country,
    String? contactPerson,
    String? phone,
    String? email,
    double? rating,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Supplier(
      id: id,
      name: name ?? this.name,
      country: country ?? this.country,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      rating: rating ?? this.rating,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
