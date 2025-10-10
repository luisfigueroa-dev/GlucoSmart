import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/carbs.dart';

/// Repositorio para manejar operaciones de base de datos relacionadas con entradas de carbohidratos.
/// Utiliza únicamente el cliente Supabase para todas las operaciones.
/// Incluye manejo de errores con try-catch y comentarios en español.
///
/// Configuración recomendada en Supabase:
/// - Tabla: carbs
/// - Columnas: id (uuid, primary key), user_id (uuid), grams (int4), timestamp (timestamptz), food (text, nullable)
/// - Índices: CREATE INDEX idx_carbs_user_timestamp ON carbs (user_id, timestamp DESC);
/// - RLS: ALTER TABLE carbs ENABLE ROW LEVEL SECURITY;
///   Política: CREATE POLICY "Users can only access their own carbs data" ON carbs
///     FOR ALL USING (auth.uid() = user_id);
class CarbsRepository {
  /// Constructor constante que recibe el cliente de Supabase.
  const CarbsRepository(this._supabaseClient);

  /// Cliente de Supabase para realizar operaciones de base de datos.
  final SupabaseClient _supabaseClient;

  /// Inserta una nueva entrada de carbohidratos en la base de datos.
  /// Maneja errores de conexión y validación.
  ///
  /// [carbs] La entrada de carbohidratos a insertar.
  /// Retorna el ID de la entrada insertada o lanza una excepción en caso de error.
  Future<String> insert(Carbs carbs) async {
    try {
      final response = await _supabaseClient
          .from('carbs')
          .insert(carbs.toJsonForInsert())
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Error al insertar entrada de carbohidratos: $e');
    }
  }

  /// Obtiene las entradas de carbohidratos de los últimos 7 días para un usuario específico.
  /// Ordena los resultados por timestamp descendente.
  /// Maneja errores de consulta y parsing de datos.
  ///
  /// [userId] El ID del usuario cuyas entradas se desean obtener.
  /// Retorna una lista de entradas o lanza una excepción en caso de error.
  Future<List<Carbs>> getLast7Days(String userId) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final response = await _supabaseClient
          .from('carbs')
          .select()
          .eq('user_id', userId)
          .gte('timestamp', sevenDaysAgo.toIso8601String())
          .order('timestamp', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Carbs.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener entradas de los últimos 7 días: $e');
    }
  }
}
