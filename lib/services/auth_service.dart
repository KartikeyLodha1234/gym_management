class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  Map<String, dynamic>? _currentUser;
  String? _currentRole;

  void setUser(Map<String, dynamic>? user, String? role) {
    _currentUser = user;
    _currentRole = role;
  }

  Map<String, dynamic>? get currentUser => _currentUser;
  String? get currentRole => _currentRole;

  bool get isAdmin => _currentRole == 'Admin';
  bool get isStaff => _currentRole == 'Manager' || _currentRole == 'Trainer' || _currentRole == 'Receptionist';
  bool get isCustomer => _currentRole == 'Member';

  void logout() {
    _currentUser = null;
    _currentRole = null;
  }
}
