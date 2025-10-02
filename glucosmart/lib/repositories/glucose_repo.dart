import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/glucose.dart';

/// Repositorio para manejar operaciones de base de datos relacionadas con mediciones de glucosa.
/// Utiliza únicamente el cliente Supabase para todas las operaciones.
/// Incluye manejo de errores con try-catch y comentarios en español.
///
/// Configuración recomendada en Supabase:
/// - Tabla: glucose
/// - Columnas: id (uuid, primary key), user_id (uuid), value (float8), timestamp (timestamptz), notes (text, nullable)
/// - Índices: CREATE INDEX idx_glucose_user_timestamp ON glucose (user_id, timestamp DESC);
/// - RLS: ALTER TABLE glucose ENABLE ROW LEVEL SECURITY;
///   Política: CREATE POLICY "Users can only access their own glucose data" ON glucose
///     FOR ALL USING (auth.uid() = user_id);
class GlucoseRepository {
  /// Constructor constante que recibe el cliente de Supabase.
  const GlucoseRepository(this._supabaseClient);

  /// Cliente de Supabase para realizar operaciones de base de datos.
  final SupabaseClient _supabaseClient;

  /// Inserta una nueva medición de glucosa en la base de datos.
  /// Maneja errores de conexión y validación.
  ///
  /// [glucose] La medición de glucosa a insertar.
  /// Retorna el ID de la medición insertada o lanza una excepción en caso de error.
  Future<String> insert(Glucose glucose) async {
    try {
      final response = await _supabaseClient
          .from('glucose')
          .insert(glucose.toJson())
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Error al insertar medición de glucosa: $e');
    }
  }

  /// Obtiene las mediciones de glucosa de los últimos 7 días para un usuario específico.
  /// Ordena los resultados por timestamp descendente.
  /// Maneja errores de consulta y parsing de datos.
  ///
  /// [userId] El ID del usuario cuyas mediciones se desean obtener.
  /// Retorna una lista de mediciones o lanza una excepción en caso de error.
  Future<List<Glucose>> getLast7Days(String userId) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final response = await _supabaseClient
          .from('glucose')
          .select()
          .eq('user_id', userId)
          .gte('timestamp', sevenDaysAgo.toIso8601String())
          .order('timestamp', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Glucose.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener mediciones de los últimos 7 días: $e');
    }
  }
}
