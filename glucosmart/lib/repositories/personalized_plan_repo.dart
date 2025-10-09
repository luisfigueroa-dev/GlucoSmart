import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/personalized_plan.dart';

/// Repositorio para gestionar planes personalizados en Supabase.
/// Maneja operaciones CRUD y generación de planes con IA.
class PersonalizedPlanRepository {
  /// Instancia del cliente Supabase.
  final SupabaseClient _supabase;

  /// Constructor que recibe el cliente Supabase.
  PersonalizedPlanRepository(this._supabase);

  /// Obtiene todos los planes activos del usuario.
  Future<List<PersonalizedPlan>> getActivePlans(String userId) async {
    try {
      final response = await _supabase
          .from('personalized_plans')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('generated_at', ascending: false);

      return response.map((json) => PersonalizedPlan.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener planes activos: $e');
    }
  }

  /// Obtiene el plan activo más reciente del usuario.
  Future<PersonalizedPlan?> getLatestActivePlan(String userId) async {
    try {
      final response = await _supabase
          .from('personalized_plans')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('generated_at', ascending: false)
          .limit(1);

      if (response.isEmpty) return null;
      return PersonalizedPlan.fromJson(response.first);
    } catch (e) {
      throw Exception('Error al obtener plan más reciente: $e');
    }
  }

  /// Crea un nuevo plan personalizado.
  Future<PersonalizedPlan> createPlan(PersonalizedPlan plan) async {
    try {
      final response = await _supabase
          .from('personalized_plans')
          .insert(plan.toJson())
          .select()
          .single();

      return PersonalizedPlan.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear plan: $e');
    }
  }

  /// Actualiza un plan existente.
  Future<PersonalizedPlan> updatePlan(PersonalizedPlan plan) async {
    try {
      final response = await _supabase
          .from('personalized_plans')
          .update(plan.toJson())
          .eq('id', plan.id)
          .select()
          .single();

      return PersonalizedPlan.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar plan: $e');
    }
  }

  /// Desactiva un plan (lo marca como inactivo).
  Future<void> deactivatePlan(String planId, String userId) async {
    try {
      await _supabase
          .from('personalized_plans')
          .update({'is_active': false})
          .eq('id', planId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Error al desactivar plan: $e');
    }
  }

  /// Elimina un plan permanentemente.
  Future<void> deletePlan(String planId, String userId) async {
    try {
      await _supabase
          .from('personalized_plans')
          .delete()
          .eq('id', planId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Error al eliminar plan: $e');
    }
  }

  /// Obtiene el historial completo de planes del usuario.
  Future<List<PersonalizedPlan>> getPlanHistory(String userId) async {
    try {
      final response = await _supabase
          .from('personalized_plans')
          .select()
          .eq('user_id', userId)
          .order('generated_at', ascending: false);

      return response.map((json) => PersonalizedPlan.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener historial de planes: $e');
    }
  }
}