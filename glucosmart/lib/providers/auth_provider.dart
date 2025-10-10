import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider para manejar el estado de autenticación global.
/// Utiliza ChangeNotifier para notificar cambios a los widgets escuchando.
/// Compatible con Dart 3.0 y null-safety.
class AuthProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;

  AuthProvider() {
    // Escuchar cambios en el estado de autenticación de Supabase
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      _user = event.session?.user;
      // Debug: imprimir información del usuario
      print('AuthProvider: User changed - ID: ${_user?.id}, Email: ${_user?.email}');
      notifyListeners();
    });

    // Debug: verificar estado inicial
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    print('AuthProvider: Current user on init - ID: ${currentUser?.id}, Email: ${currentUser?.email}');
    if (currentUser != null && _user == null) {
      _user = currentUser;
      notifyListeners();
    }
  }

  // Método para verificar si el usuario está autenticado
  bool get isAuthenticated => _user != null;

  // Método para cerrar sesión
  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  // Método para iniciar sesión con email y contraseña
  Future<void> signIn(String email, String password) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Método para registrarse con email y contraseña
  Future<void> signUp(String email, String password) async {
    await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
  }
}