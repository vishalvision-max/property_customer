import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';

class AuthRepository {
  final AuthService _service;
  final LocalStorageService _storage;

  AuthRepository(this._service, this._storage);

  Future<User?> getCachedUser() => _storage.getUser();

  Future<User> login({required String email, required String password}) async {
    final user = await _service.login(email: email, password: password);
    await _storage.saveUser(user);
    return user;
  }

  Future<User> signup({required String name, required String email, required String password}) async {
    final user = await _service.signup(name: name, email: email, password: password);
    await _storage.saveUser(user);
    return user;
  }

  Future<String> forgotPassword({required String email}) => _service.forgotPassword(email: email);

  Future<void> logout() => _storage.clearUser();
}
