import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medication.dart';

/// Repositorio para manejar operaciones de base de datos relacionadas con dosis de medicamentos.
/// Utiliza únicamente el cliente Supabase para todas las operaciones.
/// Incluye manejo de errores con try-catch y comentarios en español.
///
/// Configuración recomendada en Supabase:
/// - Tabla: medications
/// - Columnas: id (uuid, primary key), user_id (uuid), name (text), dose (float8), unit (text), timestamp (timestamptz), type (text)
/// - Índices: CREATE INDEX idx_medications_user_timestamp ON medications (user_id, timestamp DESC);
/// - RLS: ALTER TABLE medications ENABLE ROW LEVEL SECURITY;
///   Política: CREATE POLICY "Users can only access their own medications data" ON medications
///     FOR ALL USING (auth.uid() = user_id);
class MedicationRepository {
  /// Constructor constante que recibe el cliente de Supabase.
  const MedicationRepository(this._supabaseClient);

  /// Cliente de Supabase para realizar operaciones de base de datos.
  final SupabaseClient _supabaseClient;

  /// Inserta una nueva dosis de medicamento en la base de datos.
  /// Maneja errores de conexión y validación.
  ///
  /// [medication] La dosis de medicamento a insertar.
  /// Retorna el ID de la dosis insertada o lanza una excepción en caso de error.
  Future<String> insert(Medication medication) async {
    try {
      final response = await _supabaseClient
          .from('medications')
          .insert(medication.toJson())
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Error al insertar dosis de medicamento: $e');
    }
  }

  /// Obtiene las dosis de medicamentos de los últimos 7 días para un usuario específico.
  /// Ordena los resultados por timestamp descendente.
  /// Maneja errores de consulta y parsing de datos.
  ///
  /// [userId] El ID del usuario cuyas dosis se desean obtener.
  /// Retorna una lista de dosis o lanza una excepción en caso de error.
  Future<List<Medication>> getLast7Days(String userId) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final response = await _supabaseClient
          .from('medications')
          .select()
          .eq('user_id', userId)
          .gte('timestamp', sevenDaysAgo.toIso8601String())
          .order('timestamp', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Medication.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener dosis de los últimos 7 días: $e');
    }
  }
}
