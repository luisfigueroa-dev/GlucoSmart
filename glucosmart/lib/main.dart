import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:provider/provider.dart';
import 'repositories/glucose_repo.dart';
import 'providers/glucose_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'utils/notification_util.dart';
import 'repositories/notification_repo.dart';
import 'providers/notification_provider.dart';

// Instancias globales para acceso directo
final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno desde .env
  await dotenv.load(fileName: ".env");
  final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final String supabaseAnonKey = dotenv.env['SUPABASE_ANON'] ?? '';

  // Inicializar Supabase con las credenciales
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Inicializar NotificationUtil: configura notificaciones locales y WorkManager
  // Lógica compleja: NotificationUtil.initialize() registra el callback de WorkManager
  // y configura los plugins necesarios para notificaciones en segundo plano.
  final notificationUtil = NotificationUtil();
  await notificationUtil.initialize();

  // Inicializar logs para debugging
  await FlutterLogs.initLogs(
    logLevelsEnabled: [LogLevel.INFO, LogLevel.WARNING, LogLevel.ERROR, LogLevel.SEVERE],
    timeStampFormat: TimeStampFormat.TIME_FORMAT_READABLE,
    directoryStructure: DirectoryStructure.FOR_DATE,
    logTypesEnabled: ["device", "network", "errors"],
    logFileExtension: LogFileExtension.LOG,
    logsWriteDirectoryName: "GlucoSmartLogs",
    logsExportDirectoryName: "GlucoSmartLogs/Exported",
    debugFileOperations: true,
    isDebuggable: true,
  );

  runApp(
    // Envolver la app con MultiProvider para estado global
    // Lógica compleja: Se proporcionan repositorios y providers para inyección de dependencias,
    // permitiendo acceso a servicios de notificaciones, glucosa y autenticación en toda la app.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider(create: (_) => GlucoseRepository(supabase)),
        ChangeNotifierProxyProvider<AuthProvider, GlucoseProvider>(
          create: (context) => GlucoseProvider(Provider.of<GlucoseRepository>(context, listen: false)),
          update: (context, auth, previous) => previous ?? GlucoseProvider(Provider.of<GlucoseRepository>(context, listen: false)),
        ),
        Provider(create: (_) => NotificationRepository(supabase)),
        Provider(create: (_) => notificationUtil),
        ChangeNotifierProvider(
          create: (context) => NotificationProvider(
            Provider.of<NotificationRepository>(context, listen: false),
            Provider.of<NotificationUtil>(context, listen: false),
          ),
        ),
      ],
      child: const GlucoApp(),
    ),
  );
}

class GlucoApp extends StatelessWidget {
  const GlucoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlucoSmart',
      // Configuración del tema con Material 3
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      // Configuración de localizaciones para soporte multiidioma
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'), // Español
        Locale('en'), // Inglés
      ],
      // Definir rutas nombradas para navegación
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomeScreen(),
      },
      // Página de error para rutas no encontradas
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Página no encontrada')),
          body: const Center(child: Text('Ruta no válida')),
        ),
      ),
    );
  }
}

// Widget que decide qué mostrar basado en el estado de autenticación
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumir el AuthProvider para reaccionar a cambios de auth
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Si el usuario está autenticado, mostrar HomePage; de lo contrario, LoginPage
        return authProvider.isAuthenticated ? const HomeScreen() : const LoginPage();
      },
    );
  }
}

// Página de inicio de sesión con autenticación por email y contraseña
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Método para iniciar sesión con email y contraseña
  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Navegación automática gracias al AuthProvider
    } catch (e) {
      // Mostrar error al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Método para registrarse con email y contraseña
  Future<void> _signUp() async {
    setState(() => _isLoading = true);
    try {
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro exitoso. Revisa tu email para confirmar.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrarse: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _signIn,
                    child: const Text('Iniciar Sesión'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _signUp,
                    child: const Text('Registrarse'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// Página principal de la app
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GlucoSmart - Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              // Navegación automática gracias al AuthProvider
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bienvenido, ${authProvider.user?.email ?? 'Usuario'}'),
            const SizedBox(height: 20),
            const Text('Funcionalidades de GlucoSmart próximamente...'),
          ],
        ),
      ),
    );
  }
}