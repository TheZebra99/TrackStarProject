import '../models/user.dart';

/// Singleton that holds the currently logged-in user for the session
/// Set it after login/registration; clear it on logout
class UserSession {
  static final UserSession instance = UserSession._();
  UserSession._();

  User? _currentUser;

  User?   get currentUser => _currentUser;
  bool    get isLoggedIn   => _currentUser != null;
  String  get displayName  => _currentUser?.name  ?? 'Korisnik';
  String  get email        => _currentUser?.email ?? '';
  int     get userId       => _currentUser?.id    ?? 1; // placeholder
  bool    get isAdmin      => _currentUser?.isAdmin ?? false;

  void setUser(User user) => _currentUser = user;
  void clearUser()        => _currentUser = null;
}