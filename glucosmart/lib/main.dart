import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_logs/flutter_logs.dart';

final supabase = Supabase.instance.client;
final _local = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  final url = dotenv.env['SUPABASE_URL']!;
  final key = dotenv.env['SUPABASE_ANON']!;
  await Supabase.initialize(url: url, anonKey: key);  

  final initSett =
      InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'));
  await _local.initialize(initSett);

  runApp(const GlucoApp());
}

class GlucoApp extends StatelessWidget {
  const GlucoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlucoSmart-T2',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: supabase.auth.currentUser == null ? const LoginPage() : const HomePage(),
    );
  }
}

/* ---------- Ejemplo de página home (vacía para que compile) ---------- */
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await supabase.auth.signOut();
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginPage()));
          },
          child: const Text('Cerrar sesión'),
        ),
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Future<void> _signInGoogle() async {
  try {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.glucosmart://callback',
    );
  } catch (e) {
    print(e.toString());
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Entrar con Google'),
          onPressed: _signInGoogle,
        ),
      ),
    );
  }
}