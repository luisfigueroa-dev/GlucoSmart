import 'package:flutter/material.dart';
import 'advisor_screen.dart';

/// Pantalla de educación diabetológica con base de conocimiento.
/// Incluye artículos, guías y consejos sobre diabetes.
/// Compatible con WCAG 2.2 AA para accesibilidad.
/// Usa Dart 3.0 con null-safety.
class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Educación Diabética'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildEducationCard(
            context,
            '¿Qué es la Diabetes Mellitus?',
            'La diabetes es una enfermedad crónica que afecta cómo el cuerpo procesa la glucosa en sangre. Existen tipos 1, 2 y gestacional.',
            Icons.info,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildEducationCard(
            context,
            'Prevención de la Diabetes Tipo 2',
            'Mantén un peso saludable, ejercítate regularmente, come alimentos balanceados y controla el estrés.',
            Icons.health_and_safety,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildEducationCard(
            context,
            'Complicaciones de la Diabetes',
            'La diabetes no controlada puede causar problemas en ojos, riñones, corazón y nervios. El control temprano previene complicaciones.',
            Icons.warning,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildEducationCard(
            context,
            'Autocuidado Diario',
            'Monitorea tus niveles de glucosa, toma medicamentos según prescripción, come saludable y ejercítate.',
            Icons.self_improvement,
            Colors.purple,
          ),
          const SizedBox(height: 16),
          _buildEducationCard(
            context,
            'Hipoglucemia: Síntomas y Tratamiento',
            'Baja azúcar en sangre (<70 mg/dL). Síntomas: temblor, sudoración, confusión. Trata con glucosa rápida.',
            Icons.bloodtype,
            Colors.red,
          ),
          const SizedBox(height: 16),
          _buildEducationCard(
            context,
            'Hiperglucemia: Manejo',
            'Alta azúcar en sangre (>140 mg/dL). Verifica cetonas, hidrátate, ajusta insulina si es necesario.',
            Icons.trending_up,
            Colors.redAccent,
          ),
          const SizedBox(height: 24),
          // Asesor inteligente
          Card(
            elevation: 4,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AdvisorScreen()),
              ),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy, size: 40, color: Colors.blue),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Asistente Virtual',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pregunta sobre diabetes y recibe consejos personalizados',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Videos educativos
          const Text(
            'Videos Educativos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildVideoCard(
            context,
            '¿Qué es la Diabetes?',
            'Video explicativo sobre tipos de diabetes y sus causas',
            'https://www.youtube.com/watch?v=example1',
            Icons.play_circle_fill,
            Colors.red,
          ),
          _buildVideoCard(
            context,
            'Control de Glucosa',
            'Cómo monitorear y mantener niveles saludables',
            'https://www.youtube.com/watch?v=example2',
            Icons.monitor_heart,
            Colors.blue,
          ),
          _buildVideoCard(
            context,
            'Alimentación Saludable',
            'Guía de nutrición para personas con diabetes',
            'https://www.youtube.com/watch?v=example3',
            Icons.restaurant,
            Colors.green,
          ),
          _buildVideoCard(
            context,
            'Ejercicio y Diabetes',
            'Beneficios del ejercicio y recomendaciones seguras',
            'https://www.youtube.com/watch?v=example4',
            Icons.directions_run,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(
    BuildContext context,
    String title,
    String description,
    String videoUrl,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () {
          // En una implementación real, abriría el video
          // Por ahora, mostrar un diálogo informativo
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: color),
                  const SizedBox(height: 16),
                  Text(description),
                  const SizedBox(height: 16),
                  const Text(
                    'En una versión completa, este enlace abriría un video educativo.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_arrow, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEducationCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: InkWell(
        onTap: () => _showEducationDialog(context, title, description),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showEducationDialog(BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(description),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}