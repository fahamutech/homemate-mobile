/// The ways one account can use HomeMate. Agency is out of scope.
enum AppRole {
  customer,
  broker,
  landlord;

  bool get isPartner => this != customer;

  static AppRole? fromName(String? name) {
    for (final role in values) {
      if (role.name == name) return role;
    }
    return null;
  }
}
