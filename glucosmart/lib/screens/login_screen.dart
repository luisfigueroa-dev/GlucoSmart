import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Pantalla de inicio de sesión con formulario para email y contraseña.
/// Integra con AuthProvider para autenticación, maneja errores y navegación.
/// Compatible con WCAG 2.2 AA para accesibilidad. Usa Dart 3.0 con null-safety.
/// Comentarios en español para lógica compleja.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Valida el formato del email usando expresión regular.
  /// Lógica compleja: verifica patrón estándar de email con regex para asegurar
  /// que el usuario ingrese un email válido antes de enviar al servidor.
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es obligatorio';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  /// Valida que la contraseña no esté vacía y tenga longitud mínima.
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  /// Maneja el proceso de inicio de sesión.
  /// Lógica compleja: valida el formulario, llama al método signIn del AuthProvider,
  /// maneja errores específicos de autenticación y navega a home si es exitoso.
  /// Usa try-catch para capturar excepciones y mostrar mensajes de error apropiados.
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // Navegación a home tras login exitoso
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      // Manejo de errores: identifica tipo de error para mensaje específico
      String errorMsg;
      if (e.toString().contains('Invalid login credentials')) {
        errorMsg = 'Credenciales inválidas. Verifica tu email y contraseña.';
      } else if (e.toString().contains('Email not confirmed')) {
        errorMsg = 'Email no confirmado. Revisa tu bandeja de entrada.';
      } else {
        errorMsg = 'Error al iniciar sesión: ${e.toString()}';
      }
      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Campo de email con validación y accesibilidad
              Semantics(
                label: 'Campo de texto para ingresar el email',
                hint: 'Ingresa tu dirección de correo electrónico',
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'ejemplo@dominio.com',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  autofocus: true,
                ),
              ),
              const SizedBox(height: 16),
              // Campo de contraseña con validación y accesibilidad
              Semantics(
                label: 'Campo de texto para ingresar la contraseña',
                hint: 'Ingresa tu contraseña segura',
                child: TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    hintText: 'Mínimo 6 caracteres',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: _validatePassword,
                ),
              ),
              const SizedBox(height: 24),
              // Indicador de carga o botón de login
              if (_isLoading)
                const CircularProgressIndicator(
                  semanticsLabel: 'Iniciando sesión, por favor espera',
                )
              else
                Semantics(
                  button: true,
                  label: 'Botón para iniciar sesión',
                  child: ElevatedButton(
                    onPressed: _signIn,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Iniciar Sesión'),
                  ),
                ),
              // Mostrar mensaje de error si existe
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Semantics(
                    liveRegion: true, // Anuncia cambios dinámicos a lectores de pantalla
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}